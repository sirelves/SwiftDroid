import XCTest
@testable import SwiftDroid

final class ScrollInteractionTests: XCTestCase {

    private struct Row: View {
        let n: Int
        @State var taps = 0
        var body: some View { Button("row\(n) \(taps)") { taps += 1 } }
    }

    private struct Feed: View {
        @State var title = "feed"
        var body: some View {
            VStack(spacing: 0) {
                Button(title) { title += "!" }
                ScrollView {
                    VStack(spacing: 0) { ForEach(0..<20) { Row(n: $0) } }
                }
                .frame(height: 100)
            }
        }
    }

    private func texts(_ cmds: [DrawCommand]) -> [String] {
        cmds.compactMap { if case .text(let s) = $0.kind { return s } else { return nil } }
    }

    private func host() -> ViewHost<Feed> {
        ViewHost(Feed(), engine: .monospace(charWidth: 10, lineHeight: 20), proposal: ProposedSize(width: 200, height: 400))
    }

    func testScrollingRevealsLaterRowsWhichAreTappable() {
        let h = host()
        XCTAssertFalse(texts(h.commands).contains("row8 0"))
        h.scroll(at: Point(x: 10, y: 50), by: Point(x: 0, y: 140))
        XCTAssertTrue(texts(h.commands).contains("row8 0"))
        let f = h.commands.first { $0.kind == .text("row8 0") }!.frame
        h.tap(at: Point(x: f.origin.x + 1, y: f.origin.y + 10))
        XCTAssertTrue(texts(h.commands).contains("row8 1"))
    }

    func testScrollPositionSurvivesUnrelatedReRender() {
        let h = host()
        h.scroll(at: Point(x: 10, y: 50), by: Point(x: 0, y: 140))
        let title = h.commands.first { $0.kind == .text("feed") }!.frame
        h.tap(at: Point(x: title.origin.x + 1, y: title.origin.y + 1))   // re-renders the whole screen
        XCTAssertTrue(texts(h.commands).contains("feed!"))
        XCTAssertTrue(texts(h.commands).contains("row8 0"))
    }

    func testScrollIsClampedAtTheEnd() {
        let h = host()
        h.scroll(at: Point(x: 10, y: 50), by: Point(x: 0, y: 10_000))
        XCTAssertTrue(texts(h.commands).contains("row19 0"))
        XCTAssertEqual(h.commands.first { if case .scroll = $0.kind { return true }; return false }?.kind,
                       .scroll(axes: .vertical, offset: Point(x: 0, y: 300), content: Size(width: 70, height: 400)))
    }

    func testScrollOutsideAnyViewportDoesNothing() {
        let h = host()
        var renders = 0
        h.onRender = { _ in renders += 1 }
        h.scroll(at: Point(x: 10, y: 300), by: Point(x: 0, y: 50))
        XCTAssertEqual(renders, 0)
    }

    private struct Nested: View {
        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    ScrollView(.horizontal) { Text("wiiiiiiiiiiiiiiiiiiiiiide") }
                    ForEach(0..<20) { Text("line\($0)") }
                }
            }
        }
    }

    func testNestedScrollRendersOnce() {
        let h = ViewHost(Nested(), engine: .monospace(charWidth: 10, lineHeight: 20), proposal: ProposedSize(width: 100, height: 100))
        var renders = 0
        h.onRender = { _ in renders += 1 }
        h.scroll(at: Point(x: 5, y: 5), by: Point(x: 30, y: 10))
        XCTAssertEqual(renders, 1)
    }

    func testNestedScrollRoutesEachAxisToTheViewThatScrollsOnIt() {
        let h = ViewHost(Nested(), engine: .monospace(charWidth: 10, lineHeight: 20), proposal: ProposedSize(width: 100, height: 100))
        h.scroll(at: Point(x: 5, y: 5), by: Point(x: 30, y: 10))
        let scrolls = h.commands.compactMap { c -> Point? in if case .scroll(_, let o, _) = c.kind { return o } else { return nil } }
        XCTAssertEqual(scrolls, [Point(x: 0, y: 10), Point(x: 30, y: 0)])
    }
}
