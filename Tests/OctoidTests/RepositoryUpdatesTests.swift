import Foundation
import JSONSession
import Testing

@testable import Octoid

@Test
func repositoryUpdatesEmitsEventsPayload() async throws {
    let eventsPath = "/repos/elegantchaos/Octoid/events"
    let fetcher = ScriptedHTTPDataFetcher(
        scriptedResponses: [
            eventsPath: [
                .response(statusCode: 200, body: TestPayloads.events),
            ],
        ],
        defaultStep: .response(statusCode: 304, body: Data())
    )
    let session = Session(base: URL(string: "https://api.example.com")!, token: "test-token", fetcher: fetcher)
    let stream = session.repositoryUpdates(
        for: RepositoryReference(owner: "elegantchaos", name: "Octoid"),
        configuration: RepositoryPollConfiguration(interval: .milliseconds(25), pollEvents: true, pollWorkflows: false)
    )

    let updates = await collectUpdates(from: stream, count: 1, timeout: .seconds(2)) { update in
        if case .events = update {
            return true
        }
        return false
    }

    #expect(updates.count == 1)
    guard let first = updates.first else {
        Issue.record("Expected at least one events update.")
        return
    }

    switch first {
    case .events(let events):
        #expect(events.count == 1)
        #expect(events.first?.id == "evt-1")
    default:
        Issue.record("Expected an events update.")
    }
}

@Test
func repositoryUpdatesMapsGitHubMessagePayloads() async throws {
    let eventsPath = "/repos/elegantchaos/Octoid/events"
    let fetcher = ScriptedHTTPDataFetcher(
        scriptedResponses: [
            eventsPath: [
                .response(statusCode: 404, body: TestPayloads.notFoundMessage),
            ],
        ],
        defaultStep: .response(statusCode: 304, body: Data())
    )
    let session = Session(base: URL(string: "https://api.example.com")!, token: "test-token", fetcher: fetcher)
    let stream = session.repositoryUpdates(
        for: RepositoryReference(owner: "elegantchaos", name: "Octoid"),
        configuration: RepositoryPollConfiguration(interval: .milliseconds(25), pollEvents: true, pollWorkflows: false)
    )

    let updates = await collectUpdates(from: stream, count: 1, timeout: .seconds(2)) { update in
        if case .message = update {
            return true
        }
        return false
    }

    #expect(updates.count == 1)
    guard let first = updates.first else {
        Issue.record("Expected at least one message update.")
        return
    }

    switch first {
    case .message(let source, let message):
        #expect(source == .events)
        #expect(message.message == "Not Found")
    default:
        Issue.record("Expected a message update.")
    }
}

@Test
func repositoryUpdatesMapsTransportErrors() async throws {
    let eventsPath = "/repos/elegantchaos/Octoid/events"
    let fetcher = ScriptedHTTPDataFetcher(
        scriptedResponses: [
            eventsPath: [
                .failure("simulated network outage"),
            ],
        ],
        defaultStep: .response(statusCode: 304, body: Data())
    )
    let session = Session(base: URL(string: "https://api.example.com")!, token: "test-token", fetcher: fetcher)
    let stream = session.repositoryUpdates(
        for: RepositoryReference(owner: "elegantchaos", name: "Octoid"),
        configuration: RepositoryPollConfiguration(interval: .milliseconds(25), pollEvents: true, pollWorkflows: false)
    )

    let updates = await collectUpdates(from: stream, count: 1, timeout: .seconds(2)) { update in
        if case .transportError = update {
            return true
        }
        return false
    }

    #expect(updates.count == 1)
    guard let first = updates.first else {
        Issue.record("Expected at least one transport error update.")
        return
    }

    switch first {
    case .transportError(let source, let description):
        #expect(source == .events)
        #expect(description.contains("simulated network outage"))
    default:
        Issue.record("Expected a transport error update.")
    }
}

@Test
func repositoryUpdatesPollsOnlyActiveWorkflowRunsWhenAvailable() async throws {
    let workflowsPath = "/repos/elegantchaos/Octoid/actions/workflows"
    let activeRunsPath = "/repos/elegantchaos/Octoid/actions/workflows/10/runs"
    let disabledRunsPath = "/repos/elegantchaos/Octoid/actions/workflows/11/runs"
    let fetcher = ScriptedHTTPDataFetcher(
        scriptedResponses: [
            workflowsPath: [
                .response(statusCode: 200, body: TestPayloads.workflowsWithActive),
            ],
            activeRunsPath: [
                .response(statusCode: 200, body: TestPayloads.workflowRuns),
            ],
        ],
        defaultStep: .response(statusCode: 304, body: Data())
    )
    let session = Session(base: URL(string: "https://api.example.com")!, token: "test-token", fetcher: fetcher)
    let stream = session.repositoryUpdates(
        for: RepositoryReference(owner: "elegantchaos", name: "Octoid"),
        configuration: RepositoryPollConfiguration(interval: .seconds(1), pollEvents: false, pollWorkflows: true)
    )

    let updates = await collectUpdates(from: stream, count: 2, timeout: .seconds(3))
    #expect(updates.count == 2)

    let hasWorkflowsUpdate = updates.contains { update in
        if case .workflows = update {
            return true
        }
        return false
    }
    #expect(hasWorkflowsUpdate)

    let runTargets = updates.compactMap { update -> Int? in
        if case .workflowRuns(let target, _) = update {
            return target.workflowID
        }
        return nil
    }
    #expect(runTargets.contains(10))
    #expect(!runTargets.contains(11))

    let disabledCalls = await fetcher.callCount(forPath: disabledRunsPath)
    #expect(disabledCalls == 0)
}

@Test
func repositoryUpdatesPollsAllWorkflowRunsWhenNoWorkflowsAreActive() async throws {
    let workflowsPath = "/repos/elegantchaos/Octoid/actions/workflows"
    let firstRunsPath = "/repos/elegantchaos/Octoid/actions/workflows/20/runs"
    let secondRunsPath = "/repos/elegantchaos/Octoid/actions/workflows/21/runs"
    let fetcher = ScriptedHTTPDataFetcher(
        scriptedResponses: [
            workflowsPath: [
                .response(statusCode: 200, body: TestPayloads.workflowsWithoutActive),
            ],
            firstRunsPath: [
                .response(statusCode: 200, body: TestPayloads.workflowRuns),
            ],
            secondRunsPath: [
                .response(statusCode: 200, body: TestPayloads.workflowRuns),
            ],
        ],
        defaultStep: .response(statusCode: 304, body: Data())
    )
    let session = Session(base: URL(string: "https://api.example.com")!, token: "test-token", fetcher: fetcher)
    let stream = session.repositoryUpdates(
        for: RepositoryReference(owner: "elegantchaos", name: "Octoid"),
        configuration: RepositoryPollConfiguration(interval: .seconds(1), pollEvents: false, pollWorkflows: true)
    )

    let runUpdates = await collectUpdates(from: stream, count: 2, timeout: .seconds(3)) { update in
        if case .workflowRuns = update {
            return true
        }
        return false
    }
    #expect(runUpdates.count == 2)

    let identifiers = Set(runUpdates.compactMap { update -> Int? in
        if case .workflowRuns(let target, _) = update {
            return target.workflowID
        }
        return nil
    })
    #expect(identifiers == Set([20, 21]))

    let firstCalls = await fetcher.callCount(forPath: firstRunsPath)
    let secondCalls = await fetcher.callCount(forPath: secondRunsPath)
    #expect(firstCalls > 0)
    #expect(secondCalls > 0)
}

@Test
func repositoryUpdatesIgnoresNotModifiedResponses() async throws {
    let eventsPath = "/repos/elegantchaos/Octoid/events"
    let fetcher = ScriptedHTTPDataFetcher(
        scriptedResponses: [
            eventsPath: [
                .response(statusCode: 304, body: Data()),
            ],
        ],
        defaultStep: .response(statusCode: 304, body: Data())
    )
    let session = Session(base: URL(string: "https://api.example.com")!, token: "test-token", fetcher: fetcher)
    let stream = session.repositoryUpdates(
        for: RepositoryReference(owner: "elegantchaos", name: "Octoid"),
        configuration: RepositoryPollConfiguration(interval: .milliseconds(25), pollEvents: true, pollWorkflows: false)
    )

    let first = await firstUpdate(from: stream, timeout: .milliseconds(250))
    #expect(first == nil)
}

private enum ScriptedFetchStep: Sendable {
    case response(statusCode: Int, body: Data, headers: [String: String] = [:])
    case failure(String)
}

private struct ScriptedFetcherError: Error, Sendable, CustomStringConvertible {
    let message: String

    var description: String { message }
}

private actor ScriptedHTTPDataFetcher: HTTPDataFetcher {
    private var scriptedResponses: [String: [ScriptedFetchStep]]
    private let defaultStep: ScriptedFetchStep
    private var callCounts: [String: Int]

    init(scriptedResponses: [String: [ScriptedFetchStep]], defaultStep: ScriptedFetchStep) {
        self.scriptedResponses = scriptedResponses
        self.defaultStep = defaultStep
        callCounts = [:]
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url else {
            throw ScriptedFetcherError(message: "Missing URL on request.")
        }

        let path = url.path
        callCounts[path, default: 0] += 1

        var steps = scriptedResponses[path] ?? []
        let step = steps.isEmpty ? defaultStep : steps.removeFirst()
        scriptedResponses[path] = steps

        switch step {
        case .response(let statusCode, let body, let headers):
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            ) else {
                throw ScriptedFetcherError(message: "Failed to construct HTTPURLResponse for \(path).")
            }
            return (body, response)

        case .failure(let message):
            throw ScriptedFetcherError(message: message)
        }
    }

    func callCount(forPath path: String) -> Int {
        callCounts[path, default: 0]
    }
}

private enum TestPayloads {
    static let events = Data(
        """
        [
          {
            "id": "evt-1",
            "type": "PushEvent",
            "created_at": "2026-03-01T10:00:00Z",
            "public": true,
            "actor": {
              "display_login": "samdeane",
              "id": 206306,
              "login": "samdeane",
              "avatar_url": "https://avatars.githubusercontent.com/u/206306",
              "url": "https://api.github.com/users/samdeane",
              "gravatar_id": ""
            },
            "org": {
              "id": 1,
              "login": "elegantchaos",
              "avatar_url": "https://avatars.githubusercontent.com/u/1",
              "url": "https://api.github.com/orgs/elegantchaos",
              "gravatar_id": ""
            },
            "payload": {}
          }
        ]
        """.utf8
    )

    static let notFoundMessage = Data(
        """
        {
          "message": "Not Found",
          "documentation_url": "https://docs.github.com/rest"
        }
        """.utf8
    )

    static let workflowsWithActive = Data(
        """
        {
          "total_count": 2,
          "workflows": [
            {
              "id": 10,
              "name": "CI",
              "path": ".github/workflows/ci.yml",
              "state": "active"
            },
            {
              "id": 11,
              "name": "Disabled",
              "path": ".github/workflows/disabled.yml",
              "state": "disabled_manually"
            }
          ]
        }
        """.utf8
    )

    static let workflowsWithoutActive = Data(
        """
        {
          "total_count": 2,
          "workflows": [
            {
              "id": 20,
              "name": "OldCI",
              "path": ".github/workflows/old-ci.yml",
              "state": "disabled_inactivity"
            },
            {
              "id": 21,
              "name": "Legacy",
              "path": ".github/workflows/legacy.yml",
              "state": "disabled_manually"
            }
          ]
        }
        """.utf8
    )

    static let workflowRuns = Data(
        """
        {
          "total_count": 1,
          "workflow_runs": [
            {
              "id": 3001,
              "run_number": 41,
              "status": "queued",
              "conclusion": null,
              "head_commit": null
            }
          ]
        }
        """.utf8
    )
}

private func collectUpdates(
    from stream: AsyncStream<RepositoryUpdate>,
    count: Int,
    timeout: Duration,
    matching predicate: @escaping @Sendable (RepositoryUpdate) -> Bool = { _ in true }
) async -> [RepositoryUpdate] {
    let collector = Task<[RepositoryUpdate], Never> {
        var collected: [RepositoryUpdate] = []
        for await update in stream {
            if predicate(update) {
                collected.append(update)
            }
            if collected.count >= count {
                break
            }
        }
        return collected
    }

    let timeoutTask = Task {
        try? await Task.sleep(for: timeout)
        collector.cancel()
    }

    let updates = await collector.value
    timeoutTask.cancel()
    return updates
}

private func firstUpdate(
    from stream: AsyncStream<RepositoryUpdate>,
    timeout: Duration
) async -> RepositoryUpdate? {
    await withTaskGroup(of: RepositoryUpdate?.self) { group in
        group.addTask {
            for await update in stream {
                return update
            }
            return nil
        }

        group.addTask {
            try? await Task.sleep(for: timeout)
            return nil
        }

        let result = await group.next() ?? nil
        group.cancelAll()
        return result
    }
}
