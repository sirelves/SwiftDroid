import XCTest
@testable import SwiftDroid

final class SwiftDroidTests: XCTestCase {
    func testVersionIsNotEmpty() {
        XCTAssertFalse(swiftDroidVersion.isEmpty)
    }

    func testHelloReturnsNonEmptyString() {
        XCTAssertFalse(swiftDroidHello().isEmpty)
    }

    func testHelloContainsSwiftDroid() {
        XCTAssertTrue(swiftDroidHello().contains("SwiftDroid"))
    }
}
