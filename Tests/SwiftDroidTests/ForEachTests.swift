import XCTest
@testable import SwiftDroid

final class ForEachTests: XCTestCase {

    private struct Item: Identifiable, Equatable {
        let id: String
    }

    private struct Row: View {
        let name: String
        @State var taps = 0
        var body: some View { Button("\(name) \(taps)") { taps += 1 } }
    }

    private final class Model: SwiftDroid.ObservableObject {
        @SwiftDroid.Published var items: [Item] = [Item(id: "a"), Item(id: "b"), Item(id: "c")]
    }

    private struct List: View {
        @SwiftDroid.ObservedObject var model: Model
        var body: some View {
            VStack(spacing: 0) {
                ForEach(model.items) { Row(name: $0.id) }
            }
        }
    }

    private func texts(_ cmds: [DrawCommand]) -> [String] {
        cmds.compactMap { if case .text(let s) = $0.kind { return s } else { return nil } }
    }

    private func tap(_ label: String, _ host: ViewHost<some View>) {
        let i = texts(host.commands).firstIndex(of: label)!
        let f = host.commands.filter { $0.kind == .button }[i].frame
        host.tap(at: Point(x: f.origin.x + f.width / 2, y: f.origin.y + f.height / 2))
    }

    func testAllThreeInitialisers() {
        let words = ["x", "y"]
        XCTAssertEqual(makeNode(ForEach(words, id: \.self) { Text($0) }).children.map(\.kind), [.text("x"), .text("y")])
        XCTAssertEqual(makeNode(ForEach([Item(id: "p")]) { Text($0.id) }).children.map(\.kind), [.text("p")])
        XCTAssertEqual(makeNode(ForEach(0..<3) { Text("\($0)") }).children.map(\.kind), [.text("0"), .text("1"), .text("2")])
    }

    func testRowsFlattenIntoTheStack() {
        let node = ComposeRenderer().render(makeNode(VStack { Text("head"); ForEach(0..<2) { Text("\($0)") } }))
        XCTAssertEqual(node.children.map(\.kind), [.text("head"), .text("0"), .text("1")])
    }

    func testEmptyDataRendersNothing() {
        let r = LayoutEngine.monospace().layout(makeNode(VStack(spacing: 0) { ForEach([String](), id: \.self) { Text($0) }; Text("z") }), proposal: .unspecified)
        XCTAssertEqual(r.children.count, 1)
    }

    func testRowStateFollowsIdAcrossReorder() {
        let model = Model()
        let host = ViewHost(List(model: model), engine: .monospace(), proposal: .unspecified)
        tap("b 0", host); tap("b 1", host)
        model.items.reverse()
        XCTAssertEqual(texts(host.commands), ["c 0", "b 2", "a 0"])
        model.items.insert(Item(id: "new"), at: 0)
        XCTAssertEqual(texts(host.commands), ["new 0", "c 0", "b 2", "a 0"])
    }

    func testRemovedRowStateIsDiscarded() {
        let model = Model()
        let host = ViewHost(List(model: model), engine: .monospace(), proposal: .unspecified)
        tap("a 0", host)
        model.items.removeFirst()
        model.items.append(Item(id: "a"))
        XCTAssertEqual(texts(host.commands), ["b 0", "c 0", "a 0"])
    }

    func testNestedForEachKeepsIndependentState() {
        struct Grid: View {
            var body: some View {
                VStack { ForEach(0..<2) { r in HStack { ForEach(0..<2) { c in Row(name: "\(r)\(c)") } } } }
            }
        }
        let host = ViewHost(Grid(), engine: .monospace(), proposal: .unspecified)
        tap("10 0", host)
        XCTAssertEqual(texts(host.commands), ["00 0", "01 0", "10 1", "11 0"])
    }
}
