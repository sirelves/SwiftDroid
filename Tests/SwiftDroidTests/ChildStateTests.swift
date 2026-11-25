import XCTest
@testable import SwiftDroid

final class ChildStateTests: XCTestCase {

    private struct Row: View {
        let title: String
        @State var taps = 0
        var body: some View {
            Button("\(title): \(taps)") { taps += 1 }
        }
    }

    private struct Screen: View {
        var body: some View {
            VStack { Row(title: "a"); Row(title: "b") }
        }
    }

    private func texts(_ cmds: [DrawCommand]) -> [String] {
        cmds.compactMap { if case .text(let s) = $0.kind { return s } else { return nil } }
    }

    private func tap(_ index: Int, _ host: ViewHost<some View>) {
        let f = host.commands.filter { $0.kind == .button }[index].frame
        host.tap(at: Point(x: f.origin.x + f.width / 2, y: f.origin.y + f.height / 2))
    }

    func testChildStateSurvivesParentReRender() {
        let host = ViewHost(Screen(), engine: .monospace(), proposal: .unspecified)
        tap(1, host)
        tap(1, host)
        tap(0, host)
        XCTAssertEqual(texts(host.commands), ["a: 1", "b: 2"])
    }

    private struct Toggling: View {
        @State var showFirst = true
        var body: some View {
            VStack {
                Button("switch") { showFirst.toggle() }
                if showFirst { Row(title: "x") } else { Row(title: "y") }
            }
        }
    }

    func testBranchesHaveSeparateStateAndRemovedStateIsDropped() {
        let host = ViewHost(Toggling(), engine: .monospace(), proposal: .unspecified)
        tap(1, host); tap(1, host)
        XCTAssertEqual(texts(host.commands).last, "x: 2")
        tap(0, host)
        XCTAssertEqual(texts(host.commands).last, "y: 0")
        tap(0, host)
        XCTAssertEqual(texts(host.commands).last, "x: 0", "x left the hierarchy, so its state was discarded")
    }

    private struct Hideable: View {
        @State var show = true
        var body: some View {
            VStack {
                Button("hide") { show.toggle() }
                if show { Row(title: "r") }
            }
        }
    }

    func testStoreOnlyKeepsReachableState() {
        let store = StateStore()
        let view = Hideable()
        _ = store.render { view._makeNode() }
        XCTAssertEqual(store.count, 2)   // Optional.show + Row.taps
        view.show = false
        _ = store.render { view._makeNode() }
        XCTAssertEqual(store.count, 1)
    }

    func testWithoutAHostStateStillWorksLocally() {
        let row = Row(title: "a")
        row.taps = 3
        XCTAssertEqual(makeNode(row).children.first?.kind, .text("a: 3"))
    }
}
