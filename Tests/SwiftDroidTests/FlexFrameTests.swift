import XCTest
@testable import SwiftDroid

final class FlexFrameTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    func testChildProposalIsClampedOrIdeal() {
        var seen: [ProposedSize] = []
        let spy = LayoutEngine { _, p in seen.append(p); return .zero }
        let node = makeNode(Text("x").frame(minWidth: 30, maxWidth: 60, idealHeight: 7))
        _ = spy.layout(node, proposal: ProposedSize(width: 200, height: nil))
        _ = spy.layout(node, proposal: ProposedSize(width: 0, height: 5))
        XCTAssertEqual(seen, [ProposedSize(width: 60, height: 7), ProposedSize(width: 30, height: 5)])
    }

    func testMaxWidthInfinityFillsVStackWidth() {
        let r = engine.layout(makeNode(VStack(alignment: .leading) { Text("a").frame(maxWidth: .infinity, alignment: .leading); Text("bb") }),
                              proposal: ProposedSize(width: 300, height: 400))
        XCTAssertEqual(r.size.width, 300)
        XCTAssertEqual(r.children[0].size.width, 300)
        XCTAssertEqual(r.children[0].children[0].origin, .zero)
    }

    func testFlexFramedEmptyTakesNoSpace() {
        XCTAssertEqual(makeNode(EmptyView().frame(minWidth: 50)).kind, .empty)
    }

    func testComposeModifiers() {
        let r = ComposeRenderer()
        XCTAssertEqual(r.render(makeNode(Text("a").frame(maxWidth: .infinity))).modifiers, [.fillMaxWidth])
        XCTAssertEqual(r.render(makeNode(Text("a").frame(minWidth: 10, maxWidth: 40, minHeight: 5, maxHeight: .infinity))).modifiers,
                       [.widthIn(min: 10, max: 40), .fillMaxHeight, .heightIn(min: 5, max: nil)])
        XCTAssertEqual(r.render(makeNode(Text("a").frame(idealWidth: 40))).modifiers, [])
    }
}
