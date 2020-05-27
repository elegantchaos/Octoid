import XCTest
import XCTestExtensions

@testable import Octoid

final class OctoidTests: XCTestCase {
    func testEventDecoding() {
        let data = self.testData(named: "events", withExtension: "json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let formatter = ISO8601DateFormatter()
        
        let events = try! decoder.decode(Events.self, from: data)
        XCTAssertEqual(events.count, 5)
        
        let event = events.first!
        XCTAssertEqual(event.id, "12444868583")
        XCTAssertEqual(event.type, "PushEvent")
        XCTAssertEqual(event.created_at, formatter.date(from: "2020-05-26T19:06:39Z"))
    }
}
