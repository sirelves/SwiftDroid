import XCTest
@testable import SwiftDroid

/// Covers the `Button` view: node generation, the carried tap action, and that
/// it sizes to its label through the layout engine.
final class ButtonTests: XCTestCase {

    func testButtonNodeWrapsLabelAndIsAButton() {
        let node = makeNode(Button("Tap") {})
        XCTAssertEqual(node.kind, .button)
        XCTAssertEqual(node.children.map(\.kind), [.text("Tap")])
    }

    func testButtonCarriesActionInvokedOnDemand() {
        var taps = 0
        let node = makeNode(Button("Inc") { taps += 1 })
        XCTAssertNotNil(node.action)
        node.action?()
        node.action?()
        XCTAssertEqual(taps, 2)
    }

    func testButtonWithCustomViewLabel() {
        let node = makeNode(Button(action: {}) { Text("custom") })
        XCTAssertEqual(node.kind, .button)
        XCTAssertEqual(node.children.map(\.kind), [.text("custom")])
    }

    func testEqualityIsStructuralIgnoringAction() {
        // Two buttons with identical structure but different closures are equal.
        XCTAssertEqual(makeNode(Button("X") {}), makeNode(Button("X") { _ = 1 }))
        XCTAssertNotEqual(makeNode(Button("X") {}), makeNode(Button("Y") {}))
    }

    func testButtonSizesToLabel() {
        let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)
        let r = engine.layout(makeNode(Button("ab") {}), proposal: .unspecified)
        XCTAssertEqual(r.kind, .button)
        XCTAssertEqual(r.size, Size(width: 20, height: 20))
        XCTAssertEqual(r.children.map(\.kind), [.text("ab")])
    }
}
