import XCTest
@testable import Octoid

final class OctoidTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Octoid().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
