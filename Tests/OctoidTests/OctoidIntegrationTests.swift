import Foundation
import Testing
import JSONSession

@testable import Octoid

@Test
func liveEventsEndpointDecodesEvents() async throws {
    guard let configuration = await liveConfiguration(for: #function) else {
        return
    }

    guard configuration.apiBaseURL.host == "api.github.com" else {
        return
    }

    let repos = [
        RepoFixture(owner: "elegantchaos", name: "Logger"),
        RepoFixture(owner: "elegantchaos", name: "ReleaseTools"),
        RepoFixture(owner: "elegantchaos", name: "Stack"),
    ]

    for repo in repos {
        let session = IntegrationOctoidSession(token: configuration.token)
        let resource = EventsResource(name: repo.name, owner: repo.owner)
        session.poll(
            target: resource,
            processors: [EventsCaptureProcessor(), MessageProcessor<IntegrationOctoidSession>()],
            for: DispatchTime.now()
        )

        let events = try await session.awaitEvents()
        #expect(events.count >= 0)
    }
}

@Test
func liveWorkflowRunsEndpointDecodesRuns() async throws {
    guard let configuration = await liveConfiguration(for: #function) else {
        return
    }

    guard configuration.apiBaseURL.host == "api.github.com" else {
        return
    }

    let repos = [
        RepoFixture(owner: "elegantchaos", name: "Logger", workflow: configuration.workflow),
        RepoFixture(owner: "elegantchaos", name: "ReleaseTools", workflow: configuration.workflow),
        RepoFixture(owner: "elegantchaos", name: "Stack", workflow: configuration.workflow),
    ]

    for repo in repos {
        let session = IntegrationOctoidSession(token: configuration.token)
        let resource = WorkflowResource(name: repo.name, owner: repo.owner, workflow: repo.workflow)
        session.poll(
            target: resource,
            processors: [WorkflowRunsCaptureProcessor(), MessageProcessor<IntegrationOctoidSession>()],
            for: DispatchTime.now()
        )

        let runs = try await session.awaitRuns()
        #expect(runs.total_count >= 0)
    }
}

@Test
func liveMissingWorkflowReturnsNotFoundMessage() async throws {
    guard let configuration = await liveConfiguration(for: #function) else {
        return
    }

    guard configuration.apiBaseURL.host == "api.github.com" else {
        return
    }

    let session = IntegrationOctoidSession(token: configuration.token)
    let missingWorkflow = "definitely-not-a-real-workflow-\(UUID().uuidString)"
    let resource = WorkflowResource(name: "Logger", owner: "elegantchaos", workflow: missingWorkflow)
    session.poll(
        target: resource,
        processors: [WorkflowRunsCaptureProcessor(), MessageProcessor<IntegrationOctoidSession>()],
        for: DispatchTime.now()
    )

    let message = try await session.awaitMessage()
    #expect(message.message == "Not Found")
}

private func liveConfiguration(for testName: String) async -> IntegrationConfiguration? {
    switch await IntegrationTestSupport.configurationResult() {
    case .ready(let configuration):
        return configuration
    case .skipped(let reason):
        print("[OctoidIntegration] \(testName) skipped: \(reason)")
        return nil
    }
}

private struct RepoFixture {
    let owner: String
    let name: String
    let workflow: String

    init(owner: String, name: String, workflow: String = "Tests") {
        self.owner = owner
        self.name = name
        self.workflow = workflow
    }
}

private struct EventsCaptureProcessor: JSONSession.Processor {
    typealias SessionType = IntegrationOctoidSession
    typealias Payload = Events

    let name = "events capture"
    let codes = [200]

    func process(_ payload: Events, response _: HTTPURLResponse, for _: JSONSession.Request, in session: IntegrationOctoidSession) -> RepeatStatus {
        session.capture(events: payload)
        return .cancel
    }
}

private struct WorkflowRunsCaptureProcessor: JSONSession.Processor {
    typealias SessionType = IntegrationOctoidSession
    typealias Payload = WorkflowRuns

    let name = "workflow capture"
    let codes = [200]

    func process(_ payload: WorkflowRuns, response _: HTTPURLResponse, for _: JSONSession.Request, in session: IntegrationOctoidSession) -> RepeatStatus {
        session.capture(runs: payload)
        return .cancel
    }
}

private actor IntegrationState {
    var events: Events?
    var runs: WorkflowRuns?
    var message: Message?

    func set(events: Events) {
        self.events = events
    }

    func set(runs: WorkflowRuns) {
        self.runs = runs
    }

    func set(message: Message) {
        self.message = message
    }
}

private final class IntegrationOctoidSession: Octoid.Session, MessageReceiver {
    private let state = IntegrationState()

    func capture(events: Events) {
        Task {
            await state.set(events: events)
        }
    }

    func capture(runs: WorkflowRuns) {
        Task {
            await state.set(runs: runs)
        }
    }

    func received(_ message: Message, response _: HTTPURLResponse, for _: JSONSession.Request) -> RepeatStatus {
        Task {
            await state.set(message: message)
        }
        return .cancel
    }

    func awaitEvents(timeout: TimeInterval = 30) async throws -> Events {
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message = await state.message {
                throw IntegrationTestError.api(message.description)
            }
            if let events = await state.events {
                return events
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout
    }

    func awaitRuns(timeout: TimeInterval = 30) async throws -> WorkflowRuns {
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message = await state.message {
                throw IntegrationTestError.api(message.description)
            }
            if let runs = await state.runs {
                return runs
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout
    }

    func awaitMessage(timeout: TimeInterval = 30) async throws -> Message {
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message = await state.message {
                return message
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout
    }
}

private enum IntegrationTestError: Error {
    case api(String)
    case timeout
}
