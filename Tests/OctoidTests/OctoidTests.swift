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
