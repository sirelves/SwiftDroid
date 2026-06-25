import XCTest
@testable import SwiftDroid

/// Verifies the `NodeElement` IR that container views emit — that spacing,
/// alignment, and the spacer's `minLength` survive into the tree the layout
/// engine consumes. (Layout *math* is covered by `LayoutEngineTests`.)
final class StackNodeTests: XCTestCase {

    func testVStackCarriesSpacingAndAlignment() {
        let node = makeNode(VStack(alignment: .leading, spacing: 12) { Text("x") })
        XCTAssertEqual(node.kind, .vstack(spacing: 12, alignment: .leading))
    }

    func testHStackCarriesSpacingAndAlignment() {
        let node = makeNode(HStack(alignment: .bottom, spacing: 4) { Text("x") })
        XCTAssertEqual(node.kind, .hstack(spacing: 4, alignment: .bottom))
    }

    func testZStackCarriesAlignment() {
        let node = makeNode(ZStack(alignment: .topTrailing) { Text("x") })
        XCTAssertEqual(node.kind, .zstack(alignment: .topTrailing))
    }

    func testSpacerCarriesMinLength() {
        XCTAssertEqual(makeNode(Spacer(minLength: 16)).kind, .spacer(minLength: 16))
    }

    func testStackWrapsMultiChildContentInGroup() {
        // Two children fold into a TupleView → a single `group` child under the stack.
        let node = makeNode(VStack { Text("a"); Text("b") })
        XCTAssertEqual(node.children.count, 1)
        XCTAssertEqual(node.children[0].kind, .group)
        XCTAssertEqual(node.children[0].children.map(\.kind), [.text("a"), .text("b")])
    }
}
