import XCTest
@testable import SwiftDroid

/// Verifies that `_makeNode()` collapses a generic view graph into the expected
/// concrete `NodeElement` tree — leaves, grouping, composition, conditionals,
/// and optionals.
final class NodeTreeTests: XCTestCase {

    // MARK: Leaves

    func testTextRendersTextNode() {
        XCTAssertEqual(makeNode(Text("hi")), NodeElement(kind: .text("hi")))
    }

    func testEmptyViewRendersEmptyNode() {
        XCTAssertEqual(makeNode(EmptyView()), NodeElement(kind: .empty))
    }

    // MARK: Grouping via TupleView

    func testTupleViewRendersGroupOfChildren() {
        let node = makeNode(TupleView((Text("a"), Text("b"))))
        XCTAssertEqual(
            node,
            NodeElement(kind: .group, children: [
                NodeElement(kind: .text("a")),
                NodeElement(kind: .text("b")),
            ])
        )
    }

    func testTupleViewPreservesChildOrder() {
        let node = makeNode(TupleView((Text("1"), Text("2"), Text("3"))))
        XCTAssertEqual(node.children.map(\.kind), [.text("1"), .text("2"), .text("3")])
    }

    // MARK: Composition — a user view's body is walked recursively

    private struct Greeting: View {
        var body: some View {
            Text("hello")
            Text("world")
        }
    }

    func testCompositeViewRecursesIntoBody() {
        XCTAssertEqual(
            makeNode(Greeting()),
            NodeElement(kind: .group, children: [
                NodeElement(kind: .text("hello")),
                NodeElement(kind: .text("world")),
            ])
        )
    }

    private struct Nested: View {
        var body: some View {
            Greeting()
            Text("!")
        }
    }

    func testNestedCompositionProducesNestedGroups() {
        XCTAssertEqual(
            makeNode(Nested()),
            NodeElement(kind: .group, children: [
                NodeElement(kind: .group, children: [
                    NodeElement(kind: .text("hello")),
                    NodeElement(kind: .text("world")),
                ]),
                NodeElement(kind: .text("!")),
            ])
        )
    }

    // MARK: Conditionals — only the live branch renders, dynamically dispatched

    private struct Toggle: View {
        let on: Bool
        var body: some View {
            if on {
                Text("ON")
            } else {
                Text("OFF")
            }
        }
    }

    func testConditionalRendersLiveBranch() {
        XCTAssertEqual(makeNode(Toggle(on: true)), NodeElement(kind: .text("ON")))
        XCTAssertEqual(makeNode(Toggle(on: false)), NodeElement(kind: .text("OFF")))
    }

    // MARK: Optional — absent branch renders an empty node, keeping its position

    private struct Maybe: View {
        let show: Bool
        var body: some View {
            if show {
                Text("visible")
            }
        }
    }

    func testOptionalPresentRendersWrapped() {
        XCTAssertEqual(makeNode(Maybe(show: true)), NodeElement(kind: .text("visible")))
    }

    func testOptionalAbsentRendersEmpty() {
        XCTAssertEqual(makeNode(Maybe(show: false)), NodeElement(kind: .empty))
    }

    // MARK: Dynamic dispatch through `any View`

    func testLeafOverrideDispatchesThroughExistential() {
        // The crux of the design: a leaf's `_makeNode()` must run even when the
        // value is only known as `any View` (how TupleView holds its children).
        let erased: any View = Text("erased")
        XCTAssertEqual(erased._makeNode(), NodeElement(kind: .text("erased")))
    }
}
