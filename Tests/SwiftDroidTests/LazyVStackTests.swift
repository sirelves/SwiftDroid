import XCTest
@testable import SwiftDroid

final class LazyVStackTests: XCTestCase {

    final class Built { var rows = Set<Int>() }

    struct Row: View {
        let n: Int
        let built: Built
        var height: Double = 20
        @State var taps = 0
        var body: some View {
            built.rows.insert(n)
            return Button("row\(n) \(taps)") { taps += 1 }.frame(height: height)
        }
    }

    struct Feed: View {
        let count: Int
        let built: Built
        var header = false
        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    if header { Text("header") }
                    LazyVStack(spacing: 0) { ForEach(0..<count) { Row(n: $0, built: built) } }
                }
            }
        }
    }

    private func host(_ view: some View, height: Double = 200) -> ViewHost<some View> {
        ViewHost(view, engine: .monospace(charWidth: 10, lineHeight: 20), proposal: ProposedSize(width: 300, height: height))
    }

    private func drawnRows(_ cmds: [DrawCommand]) -> [Int] {
        cmds.compactMap { c in
            guard case .text(let s) = c.kind, s.hasPrefix("row") else { return nil }
            return Int(s.dropFirst(3).split(separator: " ")[0])
        }
    }

    private func scrollContent(_ cmds: [DrawCommand]) -> Size? {
        cmds.lazy.compactMap { c -> Size? in if case .scroll(_, _, let s) = c.kind { return s } else { return nil } }.first
    }

    func testOnlyVisibleRowsAreBuiltAndHeightIsEstimated() {
        let built = Built()
        let h = host(Feed(count: 1000, built: built))
        XCTAssertEqual(built.rows, Set(0..<10))           // SwiftUI builds exactly rows 0...9 here
        XCTAssertEqual(scrollContent(h.commands)?.height, 20_000)
        XCTAssertEqual(drawnRows(h.commands), Array(0..<10))
    }

    func testScrollingBuildsOnlyTheNewWindow() {
        let built = Built()
        let h = host(Feed(count: 1000, built: built))
        built.rows.removeAll()
        h.scroll(at: Point(x: 10, y: 10), by: Point(x: 0, y: 5000))
        XCTAssertEqual(built.rows, Set(250..<260))
        XCTAssertEqual(drawnRows(h.commands), Array(250..<260))
    }

    func testHeaderAboveShiftsTheWindow() {
        let built = Built()
        let h = host(Feed(count: 1000, built: built, header: true))
        XCTAssertEqual(drawnRows(h.commands), Array(0..<9))   // header takes the first 20pt
        h.scroll(at: Point(x: 10, y: 10), by: Point(x: 0, y: 1000))
        XCTAssertEqual(drawnRows(h.commands), Array(49..<59))
    }

    func testOffscreenRowKeepsItsState() {
        let built = Built()
        let h = host(Feed(count: 1000, built: built))
        let f = h.commands.first { $0.kind == .text("row2 0") }!.frame
        h.tap(at: Point(x: f.origin.x + 1, y: f.origin.y + 1))
        h.scroll(at: Point(x: 10, y: 10), by: Point(x: 0, y: 5000))
        XCTAssertFalse(built.rows.isEmpty)
        h.scroll(at: Point(x: 10, y: 10), by: Point(x: 0, y: -5000))
        XCTAssertTrue(h.commands.contains { $0.kind == .text("row2 1") })
    }

    func testVaryingHeightsUseMeasuredRowsAndMeanEstimate() {
        struct Mixed: View {
            let built: Built
            var body: some View {
                ScrollView { LazyVStack(spacing: 0) { ForEach(0..<100) { Row(n: $0, built: built, height: $0 % 2 == 0 ? 10 : 30) } } }
            }
        }
        let h = host(Mixed(built: Built()), height: 100)
        // Built rows 0..4 (10+30+10+30+10 = 80) and row 5 (30) reach 110; mean of 6 = 20 for the other 94.
        XCTAssertEqual(drawnRows(h.commands), Array(0..<6))
        XCTAssertEqual(scrollContent(h.commands)?.height, 120 + 94 * 20)
    }

    func testWithoutScrollEverythingIsBuilt() {
        let built = Built()
        let r = LayoutEngine.monospace().layout(makeNode(LazyVStack(spacing: 0) { ForEach(0..<50) { Row(n: $0, built: built) } }),
                                                proposal: ProposedSize(width: 300, height: 100))
        XCTAssertEqual(built.rows.count, 50)
        XCTAssertEqual(r.size, Size(width: 300, height: 1000))
    }

    func testWidthIsProposedWidthOrContentWidth() {
        let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)
        let node = makeNode(LazyVStack { Text("abcde") })
        XCTAssertEqual(engine.layout(node, proposal: ProposedSize(width: 300, height: nil)).size.width, 300)
        XCTAssertEqual(engine.layout(node, proposal: ProposedSize(width: 10, height: nil)).size.width, 10)
        XCTAssertEqual(engine.layout(node, proposal: .unspecified).size.width, 50)
    }

    func testStaticAndForEachRowsMix() {
        let node = makeNode(LazyVStack { Text("top"); ForEach(0..<3) { Text("\($0)") }; if true { Text("end") } })
        XCTAssertEqual(node.lazyRows.count, 5)
        XCTAssertEqual(node.lazyRows.map { $0.makeNode().kind }, [.text("top"), .text("0"), .text("1"), .text("2"), .text("end")])
    }

    func testComposeMapsToLazyColumnWithOnDemandItems() {
        let built = Built()
        let node = ComposeRenderer().render(makeNode(LazyVStack(spacing: 4) { ForEach(0..<1000) { Row(n: $0, built: built) } }))
        XCTAssertEqual(node.kind, .lazyColumn(spacing: 4, alignment: .center))
        XCTAssertEqual(node.lazyItems.count, 1000)
        XCTAssertTrue(built.rows.isEmpty)
        _ = node.lazyItems[7]()
        XCTAssertEqual(built.rows, [7])
    }
}
