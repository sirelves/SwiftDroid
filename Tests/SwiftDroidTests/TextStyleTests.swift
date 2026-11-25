import XCTest
@testable import SwiftDroid

final class TextStyleTests: XCTestCase {

    func testInnerWinsPerAttribute() {
        let outer = TextStyle(font: .title, weight: .bold, color: .red)
        let inner = TextStyle(font: .caption)
        XCTAssertEqual(inner.inheriting(from: outer), TextStyle(font: .caption, weight: .bold, color: .red))
    }

    func testResolvedFontDefaultsToBodyAndAppliesWeight() {
        XCTAssertEqual(TextStyle().resolvedFont, .body)
        XCTAssertEqual(TextStyle(font: .headline).resolvedFont.weight, .semibold)
        XCTAssertEqual(TextStyle(font: .headline, weight: .regular).resolvedFont, .system(size: 17))
        XCTAssertEqual(TextStyle(weight: .bold).resolvedFont, .body.bold())
    }

    func testColorOpacityMultiplies() {
        XCTAssertEqual(Color.red.opacity(0.5).opacity, 0.5)
        XCTAssertEqual(Color.secondary.opacity(0.5).opacity, 0.3, accuracy: 1e-9)
    }
}
