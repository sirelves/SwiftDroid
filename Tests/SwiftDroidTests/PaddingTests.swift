import XCTest
@testable import SwiftDroid

final class PaddingTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    private func layout(_ view: some View, _ proposal: ProposedSize = .unspecified) -> LayoutResult {
        engine.layout(makeNode(view), proposal: proposal)
    }

    func testOverloadsProduceInsets() {
        XCTAssertEqual(makeNode(Text("a").padding()).kind, .padding(EdgeInsets(.all, 16)))
        XCTAssertEqual(makeNode(Text("a").padding(8)).kind, .padding(EdgeInsets(.all, 8)))
        XCTAssertEqual(makeNode(Text("a").padding(.horizontal, 12)).kind, .padding(EdgeInsets(leading: 12, trailing: 12)))
        XCTAssertEqual(makeNode(Text("a").padding(.top)).kind, .padding(EdgeInsets(top: 16)))
        let custom = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        XCTAssertEqual(makeNode(Text("a").padding(custom)).kind, .padding(custom))
    }

    func testPaddingGrowsSizeAndOffsetsChild() {
        let r = layout(Text("abc").padding(EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)))
        XCTAssertEqual(r.size, Size(width: 36, height: 24))
        XCTAssertEqual(r.children[0].origin, Point(x: 2, y: 1))
        XCTAssertEqual(r.children[0].size, Size(width: 30, height: 20))
    }

    func testPaddingShrinksProposalForChild() {
        var seen: ProposedSize?
        let spy = LayoutEngine { _, p in seen = p; return .zero }
        _ = spy.layout(makeNode(Text("x").padding(10)), proposal: ProposedSize(width: 100, height: 15))
        XCTAssertEqual(seen, ProposedSize(width: 80, height: 0))
    }

    func testNestedPaddingAccumulatesInDrawCommands() {
        let cmds = CommandRenderer().render(layout(Text("ab").padding(4).padding(6)))
        XCTAssertEqual(cmds, [DrawCommand(kind: .text("ab"), frame: Rect(origin: Point(x: 10, y: 10), size: Size(width: 20, height: 20)))])
    }

    func testPaddedButtonHitAreaIsLabelNotPadding() {
        var taps = 0
        let cmds = CommandRenderer().render(layout(Button("ok") { taps += 1 }.padding(20)))
        cmds.hitTest(Point(x: 5, y: 5))?.action?()
        XCTAssertEqual(taps, 0)
        cmds.hitTest(Point(x: 25, y: 25))?.action?()
        XCTAssertEqual(taps, 1)
    }

    func testPaddingInsideStack() {
        let r = layout(VStack(spacing: 0) { Text("a").padding(.vertical, 5); Text("b") })
        XCTAssertEqual(r.size, Size(width: 10, height: 50))
        XCTAssertEqual(r.children[1].origin, Point(x: 0, y: 30))
    }

    func testComposeMapsPaddingToModifierOnChild() {
        let node = ComposeRenderer().render(makeNode(Text("a").padding(8).padding(.top, 2)))
        XCTAssertEqual(node, ComposeNode(kind: .text("a"), modifiers: [.padding(EdgeInsets(top: 2)), .padding(EdgeInsets(.all, 8))]))
    }

    func testPaddedEmptyTakesNoSpace() {
        XCTAssertEqual(makeNode(EmptyView().padding()).kind, .empty)
        XCTAssertEqual(layout(VStack(spacing: 0) { EmptyView().padding(); Text("a") }).size, Size(width: 10, height: 20))
    }

    func testComposePaddingOfEmptyIsDropped() {
        let node = ComposeRenderer().render(makeNode(VStack { EmptyView().padding(); Text("a") }))
        XCTAssertEqual(node.children, [ComposeNode(kind: .text("a"))])
    }
}
