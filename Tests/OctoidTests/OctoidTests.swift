import Foundation
import Testing

@testable import Octoid

private func testData(named name: String, withExtension ext: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: name, withExtension: ext) else {
        throw TestFixtureError.notFound(name: name, ext: ext)
    }
    return try Data(contentsOf: url)
}

private enum TestFixtureError: Error {
    case notFound(name: String, ext: String)
}

@Test
func eventDecoding() throws {
    let data = try testData(named: "events", withExtension: "json")
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let formatter = ISO8601DateFormatter()

    let events = try decoder.decode(Events.self, from: data)
    #expect(events.count == 5)

    let event = try #require(events.first)
    #expect(event.id == "12444868583")
    #expect(event.type == "PushEvent")
    #expect(event.created_at == formatter.date(from: "2020-05-26T19:06:39Z"))

    let actor = event.actor
    #expect(actor.display_login == "samdeane")
    #expect(actor.id == 206306)
    #expect(actor.login == "samdeane")
    #expect(actor.avatar_url == "https://avatars.githubusercontent.com/u/206306?")
    #expect(actor.url == "https://api.github.com/users/samdeane")
    #expect(actor.gravatar_id == "")
}

@Test
func workflowDecoding() throws {
    let data = try testData(named: "runs", withExtension: "json")
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let runs = try decoder.decode(WorkflowRuns.self, from: data)
    #expect(runs.total_count == 1)

    let run = runs.latestRun
    #expect(run.id == 115887997)
    #expect(run.status == "in_progress")
    #expect(run.conclusion == nil)
}

@Test
func workflowResourcePathForBareWorkflowName() {
    let resource = WorkflowResource(name: "Logger", owner: "elegantchaos", workflow: "tests")
    let session = Session(token: "test-token")

    #expect(resource.path(in: session) == "repos/elegantchaos/Logger/actions/workflows/tests.yml/runs")
}

@Test
func workflowResourcePathStripsYMLExtension() {
    let resource = WorkflowResource(name: "Logger", owner: "elegantchaos", workflow: "tests.yml")
    let session = Session(token: "test-token")

    #expect(resource.path(in: session) == "repos/elegantchaos/Logger/actions/workflows/tests.yml/runs")
}

@Test
func workflowResourcePathStripsYAMLExtension() {
    let resource = WorkflowResource(name: "Logger", owner: "elegantchaos", workflow: "tests.yaml")
    let session = Session(token: "test-token")

    #expect(resource.path(in: session) == "repos/elegantchaos/Logger/actions/workflows/tests.yml/runs")
}

@Test
func workflowResourcePathForAllWorkflows() {
    let resource = WorkflowResource.allWorkflows(name: "Logger", owner: "elegantchaos")
    let session = Session(token: "test-token")

    #expect(resource.path(in: session) == "repos/elegantchaos/Logger/actions/runs")
}

@Test
func workflowResourcePathForWorkflowID() {
    let resource = WorkflowResource(name: "Logger", owner: "elegantchaos", workflowID: 12345)
    let session = Session(token: "test-token")

    #expect(resource.path(in: session) == "repos/elegantchaos/Logger/actions/workflows/12345/runs")
}

@Test
func workflowsResourcePath() {
    let resource = WorkflowsResource(name: "Logger", owner: "elegantchaos")
    let session = Session(token: "test-token")

    #expect(resource.path(in: session) == "repos/elegantchaos/Logger/actions/workflows")
}

@Test
func workflowsDecoding() throws {
    let json = """
    {
      "total_count": 1,
      "workflows": [
        {
          "id": 12345,
          "name": "tests",
          "path": ".github/workflows/tests.yml",
          "state": "active"
        }
      ]
    }
    """.data(using: .utf8)!

    let workflows = try JSONDecoder().decode(Workflows.self, from: json)
    #expect(workflows.total_count == 1)
    #expect(workflows.workflows.count == 1)

    let workflow = try #require(workflows.workflows.first)
    #expect(workflow.id == 12345)
    #expect(workflow.name == "tests")
    #expect(workflow.path == ".github/workflows/tests.yml")
    #expect(workflow.state == "active")
}
