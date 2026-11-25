import XCTest
@testable import SwiftDroid

final class FrameTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    private func layout(_ view: some View, _ proposal: ProposedSize = .unspecified) -> LayoutResult {
        engine.layout(makeNode(view), proposal: proposal)
    }

    func testFrameNode() {
        XCTAssertEqual(makeNode(Text("a").frame(width: 30)).kind, .frame(width: 30, height: nil, alignment: .center))
    }

    func testFixedSizeCentersChild() {
        let r = layout(Text("ab").frame(width: 100, height: 40))
        XCTAssertEqual(r.size, Size(width: 100, height: 40))
        XCTAssertEqual(r.children[0].origin, Point(x: 40, y: 10))
    }

    func testNilAxisTakesChildSize() {
        XCTAssertEqual(layout(Text("abc").frame(width: 100)).size, Size(width: 100, height: 20))
        XCTAssertEqual(layout(Text("abc").frame(height: 50)).size, Size(width: 30, height: 50))
    }

    func testAlignmentPlacesChild() {
        XCTAssertEqual(layout(Text("a").frame(width: 30, height: 40, alignment: .topLeading)).children[0].origin, .zero)
        XCTAssertEqual(layout(Text("a").frame(width: 30, height: 40, alignment: .bottomTrailing)).children[0].origin, Point(x: 20, y: 20))
    }

    func testFrameProposesItsSizeToChild() {
        var seen: ProposedSize?
        let spy = LayoutEngine { _, p in seen = p; return .zero }
        _ = spy.layout(makeNode(Text("x").frame(width: 20)), proposal: ProposedSize(width: 300, height: 70))
        XCTAssertEqual(seen, ProposedSize(width: 20, height: 70))
    }

    func testFramedEmptyTakesNoSpace() {
        XCTAssertEqual(makeNode(EmptyView().frame(width: 50, height: 30)).kind, .empty)
    }

    func testFrameThenPaddingInDrawCommands() {
        let cmds = CommandRenderer().render(layout(Text("a").frame(width: 30, height: 20, alignment: .leading).padding(5)))
        XCTAssertEqual(cmds, [DrawCommand(kind: .text("a"), frame: Rect(origin: Point(x: 5, y: 5), size: Size(width: 10, height: 20)))])
    }

    func testComposeMapsFrameToSizedBox() {
        let node = ComposeRenderer().render(makeNode(Text("a").frame(width: 30, alignment: .leading)))
        XCTAssertEqual(node, ComposeNode(kind: .box(alignment: .leading), modifiers: [.size(width: 30, height: nil)],
                                         children: [ComposeNode(kind: .text("a"))]))
    }
}
