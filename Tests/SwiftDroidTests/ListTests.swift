import XCTest
@testable import SwiftDroid

/// Expected positions were measured on the iOS 26.3 simulator (414x814 list)
/// with scripts/measure-ios-list.sh; y is relative to the list's top.
final class ListTests: XCTestCase {

    // iOS line heights for the fonts used here; widths don't matter.
    private let engine = LayoutEngine { text, font, _ in
        let lineHeight: [Double: Double] = [17: 20.5, 13: 16, 12: 14.5]
        return Size(width: Double(text.count) * 8, height: lineHeight[font.size] ?? font.size * 1.2)
    }

    private func origins(_ view: some View) -> [String: Point] {
        let cmds = CommandRenderer().render(engine.layout(makeNode(view), proposal: ProposedSize(width: 414, height: 814)))
        var out: [String: Point] = [:]
        for c in cmds { if case .text(let s) = c.kind { out[s] = c.frame.origin } }
        return out
    }

    private func y(_ o: [String: Point], _ k: String) -> Double? { o[k]?.y }

    func testInsetGroupedRows() {
        let o = origins(List { ForEach(0..<3) { Text("Row \($0)") } })
        XCTAssertEqual([y(o, "Row 0"), y(o, "Row 1"), y(o, "Row 2")], [50.75, 102.75, 154.75])
        XCTAssertEqual(o["Row 0"]?.x, 40)
    }

    func testInsetGroupedSectionsWithHeadersAndFooter() {
        let o = origins(List {
            Section { Text("A") } header: { Text("Head1") } footer: { Text("Foot1") }
            Section { Text("B") } header: { Text("Head2") }
            Section { Text("C") }
        })
        XCTAssertEqual(y(o, "Head1"), 10)
        XCTAssertEqual(y(o, "A"), 56.25)
        XCTAssertEqual(y(o, "Foot1"), 100.5)
        XCTAssertEqual(y(o, "Head2"), 132.5)
        XCTAssertEqual(y(o, "B"), 178.75)
        XCTAssertEqual(y(o, "C"), 265.75)
    }

    func testInsetGroupedHeaderAfterSectionWithoutFooter() {
        let o = origins(List {
            Section("First") { Text("A"); Text("B") }
            Section { Text("C") } header: { Text("Second") } footer: { Text("foot") }
        })
        XCTAssertEqual([y(o, "A"), y(o, "B"), y(o, "Second"), y(o, "C"), y(o, "foot")], [56.25, 108.25, 172, 218.25, 262.5])
    }

    func testRowHeightGrowsWithContent() {
        let o = origins(List { Text("x").frame(height: 80); Text("y") })
        XCTAssertEqual(y(o, "y"), 160.75)
        let caption = origins(List { Text("cap").font(.caption) })
        XCTAssertEqual(y(caption, "cap"), 53.75)   // row top 35 + (52 - 14.5) / 2
    }

    func testRowsGetTheInsetWidth() {
        let o = origins(List { HStack { Text("L"); Spacer(); Text("R") } })
        XCTAssertEqual(o["L"]?.x, 40)
        XCTAssertEqual(o["R"]?.x, 374 - 8)      // right edge at 414 - 40
    }

    func testPlainStyle() {
        let o = origins(List { ForEach(0..<2) { Text("Row \($0)") } }.listStyle(.plain))
        XCTAssertEqual([y(o, "Row 0"), y(o, "Row 1")], [15.75, 67.75])
        XCTAssertEqual(o["Row 0"]?.x, 20)
        let s = origins(List {
            Section { Text("A"); Text("A2") } header: { Text("Head1") } footer: { Text("Foot1") }
            Section { Text("B") } header: { Text("Head2") }
        }.listStyle(.plain))
        XCTAssertEqual([y(s, "Head1"), y(s, "A"), y(s, "A2"), y(s, "Foot1"), y(s, "Head2"), y(s, "B")],
                       [32, 78.25, 130.25, 182.25, 250.5, 296.75])
    }

    func testSeparatorsBetweenRowsOfASectionOnly() {
        let cmds = CommandRenderer().render(engine.layout(makeNode(List {
            Section { Text("a"); Text("b"); Text("c") }
            Section { Text("d") }
        }), proposal: ProposedSize(width: 414, height: 814)))
        let rules = cmds.filter { $0.kind == .rule }.map(\.frame)
        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(rules.first, Rect(origin: Point(x: 40, y: 35 + 52 - 0.5), size: Size(width: 354, height: 0.5)))
    }

    func testListIsGreedyAndScrolls() {
        let r = engine.layout(makeNode(List { Text("a") }), proposal: ProposedSize(width: 300, height: 500))
        XCTAssertEqual(r.size, Size(width: 300, height: 500))
        let host = ViewHost(List { ForEach(0..<100) { Text("r\($0)") } }, engine: engine, proposal: ProposedSize(width: 414, height: 814))
        XCTAssertFalse(host.commands.contains { $0.kind == .text("r40") })
        host.scroll(at: Point(x: 100, y: 100), by: Point(x: 0, y: 2000))
        XCTAssertTrue(host.commands.contains { $0.kind == .text("r40") })
    }

    func testDataInitialisersAndRowState() {
        struct Item: Identifiable { let id: Int }
        struct Row: View {
            let n: Int
            @State var on = false
            var body: some View { Button("\(n) \(on)") { on.toggle() } }
        }
        let host = ViewHost(List([Item(id: 1), Item(id: 2)]) { Row(n: $0.id) }, engine: engine, proposal: ProposedSize(width: 414, height: 814))
        let f = host.commands.first { $0.kind == .text("2 false") }!.frame
        host.tap(at: Point(x: f.origin.x + 1, y: f.origin.y + 1))
        XCTAssertTrue(host.commands.contains { $0.kind == .text("2 true") })
        XCTAssertEqual(makeNode(List(0..<3) { Text("\($0)") }).kind, makeNode(List { ForEach(0..<3) { Text("\($0)") } }).kind)
        XCTAssertNotNil(origins(List(["a", "b"], id: \.self) { Text($0) })["b"])
    }

    func testSectionOutsideListIsItsPartsStacked() {
        let node = ComposeRenderer().render(makeNode(VStack { Section { Text("c") } header: { Text("h") } footer: { Text("f") } }))
        XCTAssertEqual(node.children.map(\.kind), [.text("h"), .text("c"), .text("f")])
    }
}
