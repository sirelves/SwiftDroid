import XCTest
@testable import SwiftDroid

final class DividerTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    func testInVStackIsAFullWidthHairline() {
        // Measured on iOS: VStack { Text; Divider() } → divider 414 x 0.5, stack takes the width.
        let r = engine.layout(makeNode(VStack(spacing: 0) { Text("ab"); Divider() }), proposal: ProposedSize(width: 414, height: nil))
        XCTAssertEqual(r.children[1].size, Size(width: 414, height: 0.5))
        XCTAssertEqual(r.size.width, 414)
    }

    func testInHStackIsVertical() {
        let r = engine.layout(makeNode(HStack(spacing: 0) { Text("a"); Divider(); Text("b") }), proposal: ProposedSize(width: 200, height: 40))
        XCTAssertEqual(r.children[1].size, Size(width: 0.5, height: 40))
    }

    func testDrawsARule() {
        let cmds = CommandRenderer().render(engine.layout(makeNode(Divider()), proposal: ProposedSize(width: 100, height: nil)))
        XCTAssertEqual(cmds, [DrawCommand(kind: .rule, frame: Rect(origin: .zero, size: Size(width: 100, height: 0.5)))])
    }

    func testComposeMapping() {
        XCTAssertEqual(ComposeRenderer().render(makeNode(VStack { Divider() })).children, [ComposeNode(kind: .divider)])
    }
}
