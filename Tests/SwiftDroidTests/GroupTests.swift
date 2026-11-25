import XCTest
@testable import SwiftDroid

final class GroupTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    func testGroupEmitsGroupNodeWrappingContent() {
        let node = makeNode(Group { Text("a"); Text("b") })
        XCTAssertEqual(node.kind, .group)
        XCTAssertEqual(node.children.count, 1)
        XCTAssertEqual(node.children[0].children.map(\.kind), [.text("a"), .text("b")])
    }

    func testGroupLiftsTenChildLimit() {
        let node = makeNode(VStack {
            Group {
                Text("1"); Text("2"); Text("3"); Text("4"); Text("5")
                Text("6"); Text("7"); Text("8"); Text("9"); Text("10")
            }
            Text("11")
        })
        let compose = ComposeRenderer().render(node)
        XCTAssertEqual(compose.children.count, 11)
        XCTAssertEqual(compose.children.last?.kind, .text("11"))
    }

    func testGroupDoesNotAffectLayout() {
        let grouped = makeNode(VStack(spacing: 4) { Group { Text("a"); Text("bb") }; Text("ccc") })
        let flat = makeNode(VStack(spacing: 4) { Text("a"); Text("bb"); Text("ccc") })
        let p = ProposedSize(width: 200, height: 200)
        let render = CommandRenderer()
        XCTAssertEqual(render.render(engine.layout(grouped, proposal: p)),
                       render.render(engine.layout(flat, proposal: p)))
    }

    func testGroupIsTransparentInComposeMapping() {
        let grouped = ComposeRenderer().render(makeNode(HStack { Group { Text("a"); Text("b") } }))
        let flat = ComposeRenderer().render(makeNode(HStack { Text("a"); Text("b") }))
        XCTAssertEqual(grouped, flat)
    }
}
