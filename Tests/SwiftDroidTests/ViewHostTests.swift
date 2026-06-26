import XCTest
@testable import SwiftDroid

/// End-to-end runtime test: a `@State` counter driven through `ViewHost`, proving
/// the tap → action → state → invalidation → re-render loop works.
final class ViewHostTests: XCTestCase {

    private struct Counter: View {
        @State var count = 0
        var body: some View {
            VStack {
                Text("Count: \(count)")
                Button("Increment") { count += 1 }
            }
        }
    }

    private func host() -> ViewHost<Counter> {
        ViewHost(Counter(), engine: .monospace(charWidth: 10, lineHeight: 20), proposal: .unspecified)
    }

    private func hasText(_ s: String, in cmds: [DrawCommand]) -> Bool {
        cmds.contains { $0.kind == .text(s) }
    }

    private func buttonCenter(_ cmds: [DrawCommand]) -> Point {
        let f = cmds.first { $0.kind == .button }!.frame
        return Point(x: f.origin.x + f.width / 2, y: f.origin.y + f.height / 2)
    }

    func testInitialRenderShowsZero() {
        let h = host()
        XCTAssertTrue(hasText("Count: 0", in: h.commands))
        XCTAssertFalse(h.commands.isEmpty)
    }

    func testTapIncrementsAndReRenders() {
        let h = host()
        h.tap(at: buttonCenter(h.commands))
        XCTAssertTrue(hasText("Count: 1", in: h.commands))
        XCTAssertFalse(hasText("Count: 0", in: h.commands))
    }

    func testMultipleTapsAccumulate() {
        let h = host()
        for _ in 0..<5 { h.tap(at: buttonCenter(h.commands)) }
        XCTAssertTrue(hasText("Count: 5", in: h.commands))
    }

    func testTapOutsideButtonDoesNothing() {
        let h = host()
        h.tap(at: Point(x: 1000, y: 1000)) // nowhere near the button
        XCTAssertTrue(hasText("Count: 0", in: h.commands))
    }

    func testResizeReRenders() {
        let h = host()
        var renders = 0
        h.onRender = { _ in renders += 1 }
        h.resize(to: ProposedSize(width: 300, height: 400))
        XCTAssertEqual(renders, 1)
        XCTAssertTrue(hasText("Count: 0", in: h.commands))
    }
}
