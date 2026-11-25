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

    func testModifiersLayout() {
        let r = LayoutEngine.monospace(charWidth: 10, lineHeight: 20).layout(makeNode(ParityModifiers()), proposal: .unspecified)
        XCTAssertEqual(r.children.map(\.size), [
            Size(width: 42, height: 52),
            Size(width: 26, height: 36),
            Size(width: 34, height: 20),
            Size(width: 16, height: 24),
            Size(width: 100, height: 40),
            Size(width: 10, height: 46),
            Size(width: 20, height: 20),
        ])
        XCTAssertEqual(r.size.height, 52 + 36 + 20 + 24 + 40 + 46 + 20)
    }

    func testStylesResolve() {
        let node = compose(ParityStyles())
        let styles = Dictionary(uniqueKeysWithValues: node.children.compactMap { c -> (String, TextStyle)? in
            let leaf = c.kind == .button ? c.children[0] : c
            if case .text(let s) = leaf.kind { return (s, leaf.textStyle) } else { return nil }
        })
        XCTAssertEqual(styles["title"], TextStyle(font: .title, color: .primary))
        XCTAssertEqual(styles["headline"], TextStyle(font: .headline, color: .secondary))
        XCTAssertEqual(styles["g1"]?.resolvedFont, Font.callout.bold())
        XCTAssertEqual(styles["g2"]?.resolvedFont, .callout)  // inner bold(false) undoes the outer bold (measured)
        XCTAssertEqual(styles["styled"], TextStyle(font: .caption, color: .red))
        XCTAssertEqual(styles.count, 10)
    }

    func testListRowStateFollowsIdentity() {
        let h = host(ParityLists(list: ParityTodoList()))
        XCTAssertEqual(texts(h.commands), ["○ milk", "○ eggs", "a", "b", "#0", "#1", "reverse"])
        tapButton(1, in: h.commands, h.tap)  // check "eggs"
        tapButton(2, in: h.commands, h.tap)  // reverse
        XCTAssertEqual(Array(texts(h.commands).prefix(2)), ["✓ eggs", "○ milk"])
    }

    func testScrollingFixtureCullsAndScrolls() {
        let h = ViewHost(ParityScrolling(), engine: .monospace(charWidth: 10, lineHeight: 20), proposal: ProposedSize(width: 300, height: 600))
        XCTAssertFalse(texts(h.commands).contains("line 16"))  // rows are 28pt (20 + spacing 8)
        h.scroll(at: Point(x: 150, y: 10), by: Point(x: 0, y: 400))
        XCTAssertTrue(texts(h.commands).contains("line 16"))
    }

    func testGroupFlattensElevenChildren() {
        XCTAssertEqual(compose(ParityGroup()).children.count, 11)
    }
}
