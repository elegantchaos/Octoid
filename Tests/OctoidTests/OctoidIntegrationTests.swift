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
        let session = Session(token: configuration.token)
        let context = IntegrationContext()
        let resource = EventsResource(name: repo.name, owner: repo.owner)

        session.poll(
            target: resource,
            context: context,
            processors: processorGroup(
                named: "events",
                [
                    EventsCaptureProcessor().eraseToAnyProcessor(),
                    MessageProcessor<IntegrationContext>().eraseToAnyProcessor(),
                ]
            ),
            for: DispatchTime.now()
        )

        let events = try await context.awaitEvents()
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
        let session = Session(token: configuration.token)
        let context = IntegrationContext()

        // Discover workflows first, then fetch runs using workflow ID to avoid filename/case guesses.
        let workflowsResource = WorkflowsResource(name: repo.name, owner: repo.owner)
        session.poll(
            target: workflowsResource,
            context: context,
            processors: processorGroup(
                named: "workflows",
                [
                    WorkflowsCaptureProcessor().eraseToAnyProcessor(),
                    MessageProcessor<IntegrationContext>().eraseToAnyProcessor(),
                ]
            ),
            for: DispatchTime.now()
        )

        let workflows = try await context.awaitWorkflows()
        guard let discoveredWorkflow = workflows.preferredWorkflow else {
            throw IntegrationTestError.noWorkflows(context: await context.requestContext())
        }

        let resource = WorkflowResource(
            name: repo.name,
            owner: repo.owner,
            workflowID: discoveredWorkflow.id
        )
        session.poll(
            target: resource,
            context: context,
            processors: processorGroup(
                named: "workflow runs",
                [
                    WorkflowRunsCaptureProcessor().eraseToAnyProcessor(),
                    MessageProcessor<IntegrationContext>().eraseToAnyProcessor(),
                ]
            ),
            for: DispatchTime.now()
        )

        let runs = try await context.awaitRuns()
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
        let session = Session(token: configuration.token)
        let context = IntegrationContext()
        let resource = WorkflowsResource(name: repo.name, owner: repo.owner)

        session.poll(
            target: resource,
            context: context,
            processors: processorGroup(
                named: "workflows",
                [
                    WorkflowsCaptureProcessor().eraseToAnyProcessor(),
                    MessageProcessor<IntegrationContext>().eraseToAnyProcessor(),
                ]
            ),
            for: DispatchTime.now()
        )

        let workflows = try await context.awaitWorkflows()
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

    let session = Session(token: configuration.token)
    let context = IntegrationContext()
    let missingWorkflow = "definitely-not-a-real-workflow-\(UUID().uuidString)"
    let resource = WorkflowResource(
        name: "Logger", owner: "elegantchaos", workflow: missingWorkflow)
    session.poll(
        target: resource,
        context: context,
        processors: processorGroup(
            named: "workflow runs",
            [
                WorkflowRunsCaptureProcessor().eraseToAnyProcessor(),
                MessageProcessor<IntegrationContext>().eraseToAnyProcessor(),
            ]
        ),
        for: DispatchTime.now()
    )

    let message = try await context.awaitMessage()
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

private func processorGroup(
    named name: String,
    _ processors: [AnyProcessor<IntegrationContext>]
) -> AnyProcessorGroup<IntegrationContext> {
    AnyProcessorGroup(name: name, processors: processors)
}

private struct EventsCaptureProcessor: Processor {
    typealias Context = IntegrationContext
    typealias Payload = Events

    let name = "events capture"
    let codes = [200]

    func process(
        _ payload: Events,
        response: HTTPURLResponse,
        for request: Request<IntegrationContext>,
        in context: IntegrationContext
    ) async throws -> RepeatStatus {
        await context.capture(events: payload, response: response, request: request)
        return .cancel
    }
}

private struct WorkflowRunsCaptureProcessor: Processor {
    typealias Context = IntegrationContext
    typealias Payload = WorkflowRuns

    let name = "workflow runs capture"
    let codes = [200]

    func process(
        _ payload: WorkflowRuns,
        response: HTTPURLResponse,
        for request: Request<IntegrationContext>,
        in context: IntegrationContext
    ) async throws -> RepeatStatus {
        await context.capture(runs: payload, response: response, request: request)
        return .cancel
    }
}

private struct WorkflowsCaptureProcessor: Processor {
    typealias Context = IntegrationContext
    typealias Payload = Workflows

    let name = "workflows capture"
    let codes = [200]

    func process(
        _ payload: Workflows,
        response: HTTPURLResponse,
        for request: Request<IntegrationContext>,
        in context: IntegrationContext
    ) async throws -> RepeatStatus {
        await context.capture(workflows: payload, response: response, request: request)
        return .cancel
    }
}

private struct IntegrationRequestContext {
    let url: URL?
    let statusCode: Int?
}

private actor IntegrationContext: MessageReceiver {
    private var events: Events?
    private var runs: WorkflowRuns?
    private var workflows: Workflows?
    private var message: Message?
    private var lastRequestURL: URL?
    private var lastStatusCode: Int?

    private let defaultTimeout: TimeInterval = 90

    private func captureRequestContext(response: HTTPURLResponse) {
        lastRequestURL = response.url
        lastStatusCode = response.statusCode
    }

    func capture(events: Events, response: HTTPURLResponse, request _: Request<IntegrationContext>) {
        captureRequestContext(response: response)
        self.events = events
    }

    func capture(runs: WorkflowRuns, response: HTTPURLResponse, request _: Request<IntegrationContext>) {
        captureRequestContext(response: response)
        self.runs = runs
    }

    func capture(workflows: Workflows, response: HTTPURLResponse, request _: Request<IntegrationContext>) {
        captureRequestContext(response: response)
        self.workflows = workflows
    }

    func received(
        _ message: Message,
        response: HTTPURLResponse,
        for _: Request<IntegrationContext>
    ) async -> RepeatStatus {
        captureRequestContext(response: response)
        self.message = message
        return .cancel
    }

    func awaitEvents(timeout: TimeInterval? = nil) async throws -> Events {
        let timeout = timeout ?? defaultTimeout
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message {
                throw IntegrationTestError.api(message.description, context: requestContext())
            }
            if let events {
                return events
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout(context: requestContext())
    }

    func awaitRuns(timeout: TimeInterval? = nil) async throws -> WorkflowRuns {
        let timeout = timeout ?? defaultTimeout
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message {
                throw IntegrationTestError.api(message.description, context: requestContext())
            }
            if let runs {
                return runs
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout(context: requestContext())
    }

    func awaitWorkflows(timeout: TimeInterval? = nil) async throws -> Workflows {
        let timeout = timeout ?? defaultTimeout
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message {
                throw IntegrationTestError.api(message.description, context: requestContext())
            }
            if let workflows {
                return workflows
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout(context: requestContext())
    }

    func awaitMessage(timeout: TimeInterval? = nil) async throws -> Message {
        let timeout = timeout ?? defaultTimeout
        let expiry = Date().addingTimeInterval(timeout)
        while Date() < expiry {
            if let message {
                return message
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw IntegrationTestError.timeout(context: requestContext())
    }

    func requestContext() -> IntegrationRequestContext {
        IntegrationRequestContext(url: lastRequestURL, statusCode: lastStatusCode)
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
