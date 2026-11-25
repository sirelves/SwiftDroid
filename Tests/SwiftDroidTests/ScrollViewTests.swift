import XCTest
@testable import SwiftDroid

final class ScrollViewTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    private func scrollNode(_ offset: Point, axes: Axis.Set = .vertical) -> NodeElement {
        NodeElement(kind: .scroll(axes: axes, offset: offset),
                    children: [makeNode(Text("a").frame(width: 100, height: 300))])
    }

    func testContentGetsUnboundedScrollAxis() {
        var seen: ProposedSize?
        let spy = LayoutEngine { _, p in seen = p; return .zero }
        _ = spy.layout(makeNode(ScrollView { Text("x") }), proposal: ProposedSize(width: 200, height: 400))
        XCTAssertEqual(seen, ProposedSize(width: 200, height: nil))
        _ = spy.layout(makeNode(ScrollView(.horizontal) { Text("x") }), proposal: ProposedSize(width: 200, height: 400))
        XCTAssertEqual(seen, ProposedSize(width: nil, height: 400))
    }

    func testOffsetShiftsContentAndIsClamped() {
        let p = ProposedSize(width: 100, height: 200)
        XCTAssertEqual(engine.layout(scrollNode(Point(x: 0, y: 40)), proposal: p).children[0].origin, Point(x: 0, y: -40))
        let over = engine.layout(scrollNode(Point(x: 0, y: 999)), proposal: p)
        XCTAssertEqual(over.kind, .scroll(axes: .vertical, offset: Point(x: 0, y: 100)))
        XCTAssertEqual(over.children[0].origin, Point(x: 0, y: -100))
        XCTAssertEqual(engine.layout(scrollNode(Point(x: 0, y: -5)), proposal: p).children[0].origin, .zero)
    }

    func testContentSmallerThanViewportCannotScroll() {
        let r = engine.layout(scrollNode(Point(x: 0, y: 50)), proposal: ProposedSize(width: 100, height: 500))
        XCTAssertEqual(r.children[0].origin, .zero)
    }

    func testNonScrollingAxisIgnoresOffset() {
        let r = engine.layout(scrollNode(Point(x: 30, y: 0)), proposal: ProposedSize(width: 20, height: 100))
        XCTAssertEqual(r.children[0].origin.x, 0)
    }

    func testComposeMapping() {
        let r = ComposeRenderer()
        let v = r.render(makeNode(ScrollView { Text("a") }))
        XCTAssertEqual(v, ComposeNode(kind: .column(spacing: 0, alignment: .center), modifiers: [.verticalScroll], children: [ComposeNode(kind: .text("a"))]))
        XCTAssertEqual(r.render(makeNode(ScrollView(.horizontal) { Text("a") })).modifiers, [.horizontalScroll])
        XCTAssertEqual(r.render(makeNode(ScrollView([.horizontal, .vertical]) { Text("a") })).kind, .box(alignment: .topLeading))
    }
}
