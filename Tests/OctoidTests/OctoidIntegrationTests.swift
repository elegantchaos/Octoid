import Foundation
import JSONSession
import Testing

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
        RepoFixture(owner: "elegantchaos", name: "Logger"),
        RepoFixture(owner: "elegantchaos", name: "ReleaseTools"),
        RepoFixture(owner: "elegantchaos", name: "Stack"),
    ]

    for repo in repos {
        let session = IntegrationOctoidSession(token: configuration.token)

        // Discover workflows first, then fetch runs using workflow ID to avoid filename/case guesses.
        let workflowsResource = WorkflowsResource(name: repo.name, owner: repo.owner)
        session.poll(
            target: workflowsResource,
            processors: [WorkflowsCaptureProcessor(), MessageProcessor<IntegrationOctoidSession>()],
            for: DispatchTime.now()
        )

        let workflows = try await session.awaitWorkflows()
        guard let discoveredWorkflow = workflows.preferredWorkflow else {
            throw IntegrationTestError.noWorkflows(context: await session.requestContext())
        }

        let resource = WorkflowResource(
            name: repo.name,
            owner: repo.owner,
            workflowID: discoveredWorkflow.id
        )
        session.poll(
            target: resource,
            processors: [
                WorkflowRunsCaptureProcessor(), MessageProcessor<IntegrationOctoidSession>(),
            ],
            for: DispatchTime.now()
        )

        let runs = try await session.awaitRuns()
        #expect(runs.total_count >= 0)
    }
}

@Test
func liveWorkflowsEndpointDecodesWorkflows() async throws {
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
        let resource = WorkflowsResource(name: repo.name, owner: repo.owner)
        session.poll(
            target: resource,
            processors: [WorkflowsCaptureProcessor(), MessageProcessor<IntegrationOctoidSession>()],
            for: DispatchTime.now()
        )

        let workflows = try await session.awaitWorkflows()
        #expect(workflows.total_count >= workflows.workflows.count)
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
    let resource = WorkflowResource(
        name: "Logger", owner: "elegantchaos", workflow: missingWorkflow)
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

    init(owner: String, name: String) {
        self.owner = owner
        self.name = name
    }
}

private struct EventsCaptureProcessor: JSONSession.Processor {
    typealias SessionType = IntegrationOctoidSession
    typealias Payload = Events

    let name = "events capture"
    let codes = [200]

    func process(
        _ payload: Events, response: HTTPURLResponse, for request: JSONSession.Request,
        in session: IntegrationOctoidSession
    ) -> RepeatStatus {
        session.capture(events: payload, response: response, request: request)
        return .cancel
    }
}

private struct WorkflowRunsCaptureProcessor: JSONSession.Processor {
    typealias SessionType = IntegrationOctoidSession
    typealias Payload = WorkflowRuns

    let name = "workflow capture"
    let codes = [200]

    func process(
        _ payload: WorkflowRuns, response: HTTPURLResponse, for request: JSONSession.Request,
        in session: IntegrationOctoidSession
    ) -> RepeatStatus {
        session.capture(runs: payload, response: response, request: request)
        return .cancel
    }
}

private struct WorkflowsCaptureProcessor: JSONSession.Processor {
    typealias SessionType = IntegrationOctoidSession
    typealias Payload = Workflows

    let name = "workflows capture"
    let codes = [200]

    func process(
        _ payload: Workflows, response: HTTPURLResponse, for request: JSONSession.Request,
        in session: IntegrationOctoidSession
    ) -> RepeatStatus {
        session.capture(workflows: payload, response: response, request: request)
        return .cancel
    }
}

private struct IntegrationRequestContext {
    let url: URL?
    let statusCode: Int?
}

private actor IntegrationState {
    var events: Events?
    var runs: WorkflowRuns?
    var workflows: Workflows?
    var message: Message?
    var lastRequestURL: URL?
    var lastStatusCode: Int?

    func set(events: Events) {
        self.events = events
    }

    func set(runs: WorkflowRuns) {
        self.runs = runs
    }

    func set(workflows: Workflows) {
        self.workflows = workflows
    }

    func set(message: Message) {
        self.message = message
    }

    func set(requestURL: URL?, statusCode: Int) {
        lastRequestURL = requestURL
        lastStatusCode = statusCode
    }

    func requestContext() -> IntegrationRequestContext {
        IntegrationRequestContext(url: lastRequestURL, statusCode: lastStatusCode)
    }
}

private final class IntegrationOctoidSession: Octoid.Session, MessageReceiver {
    private let state = IntegrationState()
    private let defaultTimeout: TimeInterval = 90

    private func captureRequestContext(request: JSONSession.Request, response: HTTPURLResponse) {
        let path = request.resource.path(in: self)
        let url = base.appendingPathComponent(path)
        Task {
            await state.set(requestURL: url, statusCode: response.statusCode)
        }
    }

    func capture(events: Events, response: HTTPURLResponse, request: JSONSession.Request) {
        captureRequestContext(request: request, response: response)
        Task {
            await state.set(events: events)
        }
    }

    func capture(runs: WorkflowRuns, response: HTTPURLResponse, request: JSONSession.Request) {
        captureRequestContext(request: request, response: response)
        Task {
            await state.set(runs: runs)
        }
    }

    func capture(workflows: Workflows, response: HTTPURLResponse, request: JSONSession.Request) {
        captureRequestContext(request: request, response: response)
        Task {
            await state.set(workflows: workflows)
        }
    }

    func received(_ message: Message, response: HTTPURLResponse, for request: JSONSession.Request)
        -> RepeatStatus
    {
        captureRequestContext(request: request, response: response)
        Task {
            await state.set(message: message)
        }
        return .cancel
    }

    func awaitEvents(timeout: TimeInterval? = nil) async throws -> Events {
        let timeout = timeout ?? defaultTimeout
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message = await state.message {
                throw IntegrationTestError.api(
                    message.description, context: await state.requestContext())
            }
            if let events = await state.events {
                return events
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout(context: await state.requestContext())
    }

    func awaitRuns(timeout: TimeInterval? = nil) async throws -> WorkflowRuns {
        let timeout = timeout ?? defaultTimeout
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message = await state.message {
                throw IntegrationTestError.api(
                    message.description, context: await state.requestContext())
            }
            if let runs = await state.runs {
                return runs
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout(context: await state.requestContext())
    }

    func awaitWorkflows(timeout: TimeInterval? = nil) async throws -> Workflows {
        let timeout = timeout ?? defaultTimeout
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message = await state.message {
                throw IntegrationTestError.api(
                    message.description, context: await state.requestContext())
            }
            if let workflows = await state.workflows {
                return workflows
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout(context: await state.requestContext())
    }

    func awaitMessage(timeout: TimeInterval? = nil) async throws -> Message {
        let timeout = timeout ?? defaultTimeout
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message = await state.message {
                return message
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout(context: await state.requestContext())
    }

    func requestContext() async -> IntegrationRequestContext {
        await state.requestContext()
    }
}

private enum IntegrationTestError: Error, LocalizedError {
    case api(String, context: IntegrationRequestContext)
    case timeout(context: IntegrationRequestContext)
    case noWorkflows(context: IntegrationRequestContext)

    var errorDescription: String? {
        switch self {
        case .api(let description, let context):
            return "GitHub API error: \(description)\(context.suffix)"
        case .timeout(let context):
            return "Timed out waiting for integration response\(context.suffix)"
        case .noWorkflows(let context):
            return "No workflows found for repository\(context.suffix)"
        }
    }
}

private extension IntegrationRequestContext {
    var suffix: String {
        var fields: [String] = []
        if let url {
            fields.append("url=\(url.absoluteString)")
        }
        if let statusCode {
            fields.append("status=\(statusCode)")
        }

        guard !fields.isEmpty else {
            return "."
        }

        return " (\(fields.joined(separator: ", ")))."
    }
}
