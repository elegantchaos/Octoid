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
  /// Normalized workflow name used by ActionStatus workflow matching.
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
        let workflowCoordinator = WorkflowRunPollingCoordinator(
          session: self,
          repository: repository,
          interval: configuration.interval,
          continuation: continuation
        )

        var endpointTasks: [Task<Void, Never>] = []
        defer {
          for task in endpointTasks {
            task.cancel()
          }

          Task {
            await workflowCoordinator.cancelAll()
          }
          continuation.finish()
        }

        if configuration.pollEvents {
          endpointTasks.append(
            Task {
              for await event in self.pollData(
                for: EventsResource(name: repository.name, owner: repository.owner),
                every: configuration.interval,
                initialDelay: configuration.initialDelay
              ) {
                switch Self.decode(event, as: Events.self) {
                case .payload(let payload):
                  continuation.yield(.events(payload))
                case .message(let message):
                  continuation.yield(.message(source: .events, message: message))
                case .transportError(let error):
                  continuation.yield(.transportError(source: .events, description: error))
                case .ignored:
                  break
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
                switch Self.decode(event, as: Workflows.self) {
                case .payload(let workflows):
                  continuation.yield(.workflows(workflows))
                  await workflowCoordinator.updateTargets(from: workflows)
                case .message(let message):
                  continuation.yield(.message(source: .workflows, message: message))
                case .transportError(let error):
                  continuation.yield(.transportError(source: .workflows, description: error))
                case .ignored:
                  break
                }
              }
            }
          )
        }

        while !Task.isCancelled {
          do {
            try await Task.sleep(for: .seconds(60))
          } catch {
            break
          }
        }
      }

      continuation.onTermination = { _ in
        lifecycleTask.cancel()
      }
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
      switch response.statusCode {
      case 304:
        return .ignored
      case 200:
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
          return .payload(try decoder.decode(payloadType, from: data))
        } catch {
          return .transportError("Failed to decode \(payloadType): \(error)")
        }
      case 400, 401, 403, 404:
        do {
          let decoder = JSONDecoder()
          return .message(try decoder.decode(Message.self, from: data))
        } catch {
          return .transportError("Failed to decode message payload: \(error)")
        }
      default:
        return .transportError("Unexpected HTTP status: \(response.statusCode)")
      }
    }
  }
}

/// Decoding result used when mapping polling events to repository updates.
private enum DecodedPollEvent<Payload> {
  /// Successfully decoded endpoint payload.
  case payload(Payload)
  /// Successfully decoded GitHub API message.
  case message(Message)
  /// Transport or decoding failure description.
  case transportError(String)
  /// Non-actionable poll response (such as HTTP 304).
  case ignored
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
  private static func normalizeWorkflowName(_ name: String) -> String {
    let lowercased = name.lowercased()
    if lowercased.hasSuffix(".yaml") {
      return String(lowercased.dropLast(5))
    } else if lowercased.hasSuffix(".yml") {
      return String(lowercased.dropLast(4))
    } else {
      return lowercased
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
        switch Session.decode(event, as: WorkflowRuns.self) {
        case .payload(let runs):
          continuation.yield(.workflowRuns(target: target, runs: runs))
        case .message(let message):
          continuation.yield(.message(source: source, message: message))
        case .transportError(let error):
          continuation.yield(.transportError(source: source, description: error))
        case .ignored:
          break
        }
      }
    }
  }
}
