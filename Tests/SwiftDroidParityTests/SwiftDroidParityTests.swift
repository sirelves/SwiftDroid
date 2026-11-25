import XCTest
@testable import SwiftDroid

final class SwiftDroidParityTests: XCTestCase {

    private func compose(_ view: some View) -> ComposeNode {
        ComposeRenderer().render(makeNode(view))
    }

    private func host<V: View>(_ view: V) -> ViewHost<V> {
        ViewHost(view, engine: .monospace(charWidth: 10, lineHeight: 20), proposal: .unspecified)
    }

    private func texts(_ cmds: [DrawCommand]) -> [String] {
        cmds.compactMap { if case .text(let s) = $0.kind { return s } else { return nil } }
    }

    private func tapButton(_ index: Int, in cmds: [DrawCommand], _ tap: (Point) -> Void) {
        let f = cmds.filter { $0.kind == .button }[index].frame
        tap(Point(x: f.origin.x + f.width / 2, y: f.origin.y + f.height / 2))
    }

    func testCounterTree() {
        XCTAssertEqual(compose(ParityCounter()), ComposeNode(kind: .column(spacing: 8, alignment: .center), children: [
            ComposeNode(kind: .text("Count: 0")),
            ComposeNode(kind: .button, children: [ComposeNode(kind: .text("Increment"))]),
        ]))
    }

    func testCounterIncrements() {
        let h = host(ParityCounter())
        tapButton(0, in: h.commands, h.tap)
        XCTAssertTrue(texts(h.commands).contains("Count: 1"))
    }

    func testStacksTree() {
        let node = compose(ParityStacks())
        XCTAssertEqual(node.kind, .column(spacing: 4, alignment: .leading))
        XCTAssertEqual(node.children.map(\.kind), [
            .row(spacing: 12, alignment: .top),
            .box(alignment: .topTrailing),
            .spacer(minLength: 16),
            .row(spacing: 8, alignment: .center),
            .box(alignment: .center),
        ])
    }

    func testConditionalBranches() {
        XCTAssertEqual(compose(ParityConditional(flag: true)).children.map(\.kind), [.text("on"), .text("only when on")])
        XCTAssertEqual(compose(ParityConditional(flag: false)).children.map(\.kind), [.text("off")])
    }

    func testBindingToggleWritesParentState() {
        let h = host(ParityBindingParent())
        XCTAssertEqual(texts(h.commands), ["OFF", "ON"])
        tapButton(0, in: h.commands, h.tap)
        XCTAssertEqual(texts(h.commands), ["ON", "ON"])
    }

    func testObservedModelReRendersOnTapAndBinding() {
        let model = ParityModel()
        let h = host(ParityModelView(model: model))
        XCTAssertTrue(texts(h.commands).contains("model: 0"))
        tapButton(0, in: h.commands, h.tap)
        XCTAssertTrue(texts(h.commands).contains("model: 1"))
        tapButton(1, in: h.commands, h.tap)
        XCTAssertEqual(model.name, "renamed")
        XCTAssertTrue(texts(h.commands).contains("renamed: 1"))
    }

    func testGroupFlattensElevenChildren() {
        XCTAssertEqual(compose(ParityGroup()).children.count, 11)
    }
}
