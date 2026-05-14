// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/02/2026.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

/// Identifies a GitHub repository by owner/name.
public struct RepositoryReference: Sendable, Hashable {
  /// Repository owner login.
  public let owner: String
  /// Repository name.
  public let name: String

  /// Creates a repository reference.
  public init(owner: String, name: String) {
    self.owner = owner
    self.name = name
  }
}

/// Workflow target metadata attached to workflow run updates.
public struct RepositoryWorkflowTarget: Sendable, Hashable {
  /// Workflow identifier from the GitHub workflows endpoint.
  public let workflowID: Int
  /// Workflow display name.
  public let name: String
  /// Workflow name with any `.yml`/`.yaml` suffix stripped for matching.
  public let normalizedName: String

  /// Creates a workflow target descriptor.
  public init(workflowID: Int, name: String, normalizedName: String) {
    self.workflowID = workflowID
    self.name = name
    self.normalizedName = normalizedName
  }
}

/// Endpoint source for repository update stream events.
public enum RepositoryUpdateSource: Sendable, Hashable {
  /// Repository events endpoint.
  case events
  /// Repository workflows endpoint.
  case workflows
  /// Workflow runs endpoint for a specific workflow target.
  case workflowRuns(RepositoryWorkflowTarget)
}

/// Stream update emitted by Octoid repository polling.
public enum RepositoryUpdate: Sendable {
  /// Decoded repository events payload.
  case events(Events)
  /// Decoded repository workflows payload.
  case workflows(Workflows)
  /// Decoded workflow runs payload for a workflow target.
  case workflowRuns(target: RepositoryWorkflowTarget, runs: WorkflowRuns)
  /// HTTP metadata observed for an endpoint response.
  case responseMetadata(source: RepositoryUpdateSource, metadata: HTTPResponseMetadata)
  /// GitHub reported that repository polling is rate limited.
  case rateLimited(source: RepositoryUpdateSource, message: Message?, metadata: HTTPResponseMetadata)
  /// Decoded GitHub message payload for an endpoint.
  case message(source: RepositoryUpdateSource, message: Message)
  /// Transport-level polling error for an endpoint.
  case transportError(source: RepositoryUpdateSource, description: String)
}

/// Polling configuration for repository update streams.
public struct RepositoryPollConfiguration: Sendable {
  /// Polling interval shared by all repository endpoints.
  public let interval: Duration
  /// Optional initial delay before starting events/workflows polling.
  public let initialDelay: Duration
  /// Indicates whether repository events should be polled.
  public let pollEvents: Bool
  /// Indicates whether repository workflows should be polled.
  public let pollWorkflows: Bool

  /// Creates a repository polling configuration.
  public init(
    interval: Duration,
    initialDelay: Duration = .zero,
    pollEvents: Bool = true,
    pollWorkflows: Bool = true
  ) {
    self.interval = interval
    self.initialDelay = initialDelay
    self.pollEvents = pollEvents
    self.pollWorkflows = pollWorkflows
  }
}

/// Octoid stream APIs layered on top of JSONSession polling streams.
public extension Session {
  /// Creates a continuous stream of repository updates.
  ///
  /// The stream polls workflows and events, and automatically polls workflow-runs
  /// for active workflows (or all workflows when none are active).
  nonisolated func repositoryUpdates(
    for repository: RepositoryReference,
    configuration: RepositoryPollConfiguration
  ) -> AsyncStream<RepositoryUpdate> {
    AsyncStream(RepositoryUpdate.self, bufferingPolicy: .bufferingNewest(100)) { continuation in
      let lifecycleTask = Task {
        let keepAliveInterval = configuration.interval > .zero ? configuration.interval : .seconds(1)
        let workflowCoordinator = WorkflowRunPollingCoordinator(
          session: self,
          repository: repository,
          interval: configuration.interval,
          continuation: continuation
        )

        var endpointTasks: [Task<Void, Never>] = []

        if configuration.pollEvents {
          endpointTasks.append(
            Task {
              for await event in self.pollData(
                for: EventsResource(name: repository.name, owner: repository.owner),
                every: configuration.interval,
                initialDelay: configuration.initialDelay
              ) {
                await Self.yieldDecoded(event, source: .events, as: Events.self, to: continuation) { payload in
                  .events(payload)
                }
              }
            }
          )
        }

        if configuration.pollWorkflows {
          endpointTasks.append(
            Task {
              for await event in self.pollData(
                for: WorkflowsResource(name: repository.name, owner: repository.owner),
                every: configuration.interval,
                initialDelay: configuration.initialDelay
              ) {
                await Self.yieldDecoded(event, source: .workflows, as: Workflows.self, to: continuation) { workflows in
                  await workflowCoordinator.updateTargets(from: workflows)
                  return .workflows(workflows)
                }
              }
            }
          )
        }

        while !Task.isCancelled {
          do {
            try await Task.sleep(for: keepAliveInterval)
          } catch {
            break
          }
        }

        for task in endpointTasks {
          task.cancel()
        }
        await workflowCoordinator.cancelAll()
        continuation.finish()
      }

      continuation.onTermination = { _ in
        lifecycleTask.cancel()
      }
    }
  }

  /// Yields response metadata and decoded update values for a polling event.
  fileprivate nonisolated static func yieldDecoded<Payload: Decodable & Sendable>(
    _ event: PollDataEvent,
    source: RepositoryUpdateSource,
    as payloadType: Payload.Type,
    to continuation: AsyncStream<RepositoryUpdate>.Continuation,
    payloadUpdate: (Payload) async -> RepositoryUpdate
  ) async {
    switch Self.decode(event, as: payloadType) {
      case .payload(let payload):
        if let metadata = event.metadata {
          continuation.yield(.responseMetadata(source: source, metadata: metadata))
        }
        continuation.yield(await payloadUpdate(payload))
      case .rateLimited(let message, let metadata):
        continuation.yield(.responseMetadata(source: source, metadata: metadata))
        continuation.yield(.rateLimited(source: source, message: message, metadata: metadata))
      case .message(let message):
        if let metadata = event.metadata {
          continuation.yield(.responseMetadata(source: source, metadata: metadata))
        }
        continuation.yield(.message(source: source, message: message))
      case .transportError(let error):
        if let metadata = event.metadata {
          continuation.yield(.responseMetadata(source: source, metadata: metadata))
        }
        continuation.yield(.transportError(source: source, description: error))
      case .ignored(let metadata):
        continuation.yield(.responseMetadata(source: source, metadata: metadata))
    }
  }

  /// Decodes a polling event into payload/message/error events.
  fileprivate nonisolated static func decode<Payload: Decodable & Sendable>(
    _ event: PollDataEvent,
    as payloadType: Payload.Type
  ) -> DecodedPollEvent<Payload> {
    switch event {
    case .transportError(let error):
      return .transportError(error)

    case .response(let data, let response):
      let metadata = response.metadata
      switch response.statusCode {
      case 304:
        return .ignored(metadata)
      case 200:
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
          return .payload(try decoder.decode(payloadType, from: data))
        } catch {
          return .transportError("Failed to decode \(payloadType): \(error)")
        }
      case 400, 401, 403, 404, 429:
        return decodeMessage(data: data, metadata: metadata)
      default:
        return .transportError("Unexpected HTTP status: \(response.statusCode)")
      }
    }
  }

  /// Decodes an API message and upgrades rate-limit responses to a semantic event.
  private nonisolated static func decodeMessage<Payload: Decodable & Sendable>(
    data: Data,
    metadata: HTTPResponseMetadata
  ) -> DecodedPollEvent<Payload> {
    let message = try? JSONDecoder().decode(Message.self, from: data)
    if isRateLimited(message: message, metadata: metadata) {
      return .rateLimited(message, metadata)
    }

    if let message {
      return .message(message)
    }

    return .transportError("Failed to decode message payload")
  }

  /// Returns whether a GitHub API response represents primary or secondary rate limiting.
  private nonisolated static func isRateLimited(message: Message?, metadata: HTTPResponseMetadata) -> Bool {
    if metadata.statusCode == 429 {
      return true
    }

    if metadata.rateLimit?.retryAfter != nil {
      return true
    }

    if metadata.statusCode == 403, metadata.rateLimit?.isDepleted == true {
      return true
    }

    guard let text = message?.message.lowercased() else { return false }
    return text.contains("rate limit")
  }
}

/// Decoding result used when mapping polling events to repository updates.
private enum DecodedPollEvent<Payload> {
  /// Successfully decoded endpoint payload.
  case payload(Payload)
  /// GitHub reported a rate-limit response.
  case rateLimited(Message?, HTTPResponseMetadata)
  /// Successfully decoded GitHub API message.
  case message(Message)
  /// Transport or decoding failure description.
  case transportError(String)
  /// Non-actionable poll response (such as HTTP 304).
  case ignored(HTTPResponseMetadata)
}

/// Maintains workflow-run polling streams for active workflows in a repository.
private actor WorkflowRunPollingCoordinator {
  /// Shared JSON session used for polling.
  private let session: Session
  /// Repository being polled.
  private let repository: RepositoryReference
  /// Polling interval for workflow-run streams.
  private let interval: Duration
  /// Target continuation receiving stream updates.
  private let continuation: AsyncStream<RepositoryUpdate>.Continuation
  /// Active workflow polling tasks keyed by workflow target.
  private var tasks: [RepositoryWorkflowTarget: Task<Void, Never>] = [:]

  /// Creates a workflow-run stream coordinator.
  init(
    session: Session,
    repository: RepositoryReference,
    interval: Duration,
    continuation: AsyncStream<RepositoryUpdate>.Continuation
  ) {
    self.session = session
    self.repository = repository
    self.interval = interval
    self.continuation = continuation
  }

  /// Synchronizes run polling tasks to match the latest workflow payload.
  func updateTargets(from workflows: Workflows) {
    let active = workflows.workflows.filter { $0.state == "active" }
    let source = active.isEmpty ? workflows.workflows : active
    let targets = Set(source.map(Self.target(from:)))

    for (target, task) in tasks where !targets.contains(target) {
      task.cancel()
      tasks.removeValue(forKey: target)
    }

    for target in targets where tasks[target] == nil {
      tasks[target] = makeTask(for: target)
    }
  }

  /// Cancels all active workflow-run polling tasks.
  func cancelAll() {
    for task in tasks.values {
      task.cancel()
    }
    tasks.removeAll()
  }

  /// Creates a stable workflow target descriptor from workflow metadata.
  private static func target(from workflow: Workflow) -> RepositoryWorkflowTarget {
    RepositoryWorkflowTarget(
      workflowID: workflow.id,
      name: workflow.name,
      normalizedName: normalizeWorkflowName(workflow.name)
    )
  }

  /// Normalizes workflow names for string-based matching fallback.
  ///
  /// This strips a trailing workflow extension in a case-insensitive way
  /// while preserving the original workflow name casing.
  private static func normalizeWorkflowName(_ name: String) -> String {
    let lowercased = name.lowercased()
    if lowercased.hasSuffix(".yaml") {
      return String(name.dropLast(5))
    } else if lowercased.hasSuffix(".yml") {
      return String(name.dropLast(4))
    } else {
      return name
    }
  }

  /// Creates and starts a workflow-runs polling task for a workflow target.
  private func makeTask(for target: RepositoryWorkflowTarget) -> Task<Void, Never> {
    let resource = WorkflowResource(
      name: repository.name,
      owner: repository.owner,
      workflowID: target.workflowID
    )
    let source = RepositoryUpdateSource.workflowRuns(target)

    return Task {
      for await event in session.pollData(for: resource, every: interval) {
        await Session.yieldDecoded(event, source: source, as: WorkflowRuns.self, to: continuation) { runs in
          .workflowRuns(target: target, runs: runs)
        }
      }
    }
  }
}
