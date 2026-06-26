import XCTest
@testable import SwiftDroid

/// Verifies the SwiftDroid → Jetpack Compose mapping: stacks become
/// Column/Row/Box, leaves map across, transparent group/empty are flattened, and
/// button actions survive.
final class ComposeRendererTests: XCTestCase {

    private let r = ComposeRenderer()
    private func compose(_ view: some View) -> ComposeNode { r.render(makeNode(view)) }

    func testTextMapsToText() {
        XCTAssertEqual(compose(Text("hi")), ComposeNode(kind: .text("hi")))
    }

    func testVStackMapsToColumnFlatteningGroup() {
        let node = compose(VStack(alignment: .leading, spacing: 12) { Text("a"); Text("b") })
        XCTAssertEqual(node, ComposeNode(kind: .column(spacing: 12, alignment: .leading), children: [
            ComposeNode(kind: .text("a")),
            ComposeNode(kind: .text("b")),
        ]))
    }

    func testHStackMapsToRow() {
        let node = compose(HStack(alignment: .bottom, spacing: 4) { Text("x") })
        XCTAssertEqual(node, ComposeNode(kind: .row(spacing: 4, alignment: .bottom), children: [ComposeNode(kind: .text("x"))]))
    }

    func testZStackMapsToBox() {
        let node = compose(ZStack(alignment: .topTrailing) { Text("x") })
        XCTAssertEqual(node, ComposeNode(kind: .box(alignment: .topTrailing), children: [ComposeNode(kind: .text("x"))]))
    }

    func testSpacerMaps() {
        let node = compose(VStack(spacing: 0) { Spacer(minLength: 8) })
        XCTAssertEqual(node.children, [ComposeNode(kind: .spacer(minLength: 8))])
    }

    func testButtonMapsAndKeepsAction() {
        var taps = 0
        let node = compose(Button("ok") { taps += 1 })
        XCTAssertEqual(node.kind, .button)
        XCTAssertEqual(node.children, [ComposeNode(kind: .text("ok"))])
        node.action?()
        XCTAssertEqual(taps, 1)
    }

    func testEmptyIsDroppedFromContainers() {
        let withEmpty = compose(VStack(spacing: 0) { Text("a"); EmptyView(); Text("b") })
        XCTAssertEqual(withEmpty.children.map(\.kind), [.text("a"), .text("b")])
    }

    func testNestedCounterMapsToColumnWithTextAndButton() {
        let node = compose(VStack(spacing: 8) { Text("Count: 0"); Button("Increment") {} })
        XCTAssertEqual(node.kind, .column(spacing: 8, alignment: .center))
        XCTAssertEqual(node.children.map(\.kind), [.text("Count: 0"), .button])
        XCTAssertEqual(node.children[1].children, [ComposeNode(kind: .text("Increment"))])
    }
}
