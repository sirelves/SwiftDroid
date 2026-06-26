import XCTest
@testable import SwiftDroid

/// Covers `CommandRenderer`: flattening a laid-out tree into absolute-framed
/// draw commands, dropping non-visual nodes, and hit-testing button taps.
final class RendererTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)
    private let renderer = CommandRenderer()

    private func commands(_ view: some View) -> [DrawCommand] {
        renderer.render(engine.layout(makeNode(view), proposal: .unspecified))
    }

    func testTextBecomesAbsoluteFramedCommand() {
        let cmds = commands(Text("ab"))
        XCTAssertEqual(cmds, [DrawCommand(kind: .text("ab"), frame: Rect(origin: .zero, size: Size(width: 20, height: 20)))])
    }

    func testContainersAndEmptiesDrawNothingButOffsetChildren() {
        // VStack(spacing 8) { Text("a"); Text("cd") } — centered in width 20.
        let cmds = commands(VStack(spacing: 8) { Text("a"); Text("cd") })
        XCTAssertEqual(cmds.count, 2)
        XCTAssertEqual(cmds[0].frame, Rect(origin: Point(x: 5, y: 0), size: Size(width: 10, height: 20)))   // "a" centered
        XCTAssertEqual(cmds[1].frame, Rect(origin: Point(x: 0, y: 28), size: Size(width: 20, height: 20)))  // "cd" below + spacing
    }

    func testButtonEmitsTapSurfaceThenLabel() {
        let cmds = commands(VStack(spacing: 8) { Text("a"); Button("ok") {} })
        // text(a), button, text(ok-label)
        XCTAssertEqual(cmds.map(\.kind), [.text("a"), .button, .text("ok")])
        let button = cmds[1]
        XCTAssertEqual(button.frame, Rect(origin: Point(x: 0, y: 28), size: Size(width: 20, height: 20)))
        XCTAssertNotNil(button.action)
    }

    func testHitTestRoutesTapToButtonAction() {
        var taps = 0
        let cmds = commands(VStack(spacing: 8) { Text("a"); Button("ok") { taps += 1 } })

        // A point over the button fires; a point over the plain text does not.
        cmds.hitTest(Point(x: 5, y: 32))?.action?()
        XCTAssertEqual(taps, 1)

        XCTAssertNil(cmds.hitTest(Point(x: 5, y: 5)))  // only the "a" text is here
        XCTAssertEqual(taps, 1)
    }

    func testSpacerDrawsNothing() {
        let cmds = commands(VStack(spacing: 0) { Text("a"); Spacer(); Text("b") })
        XCTAssertEqual(cmds.map(\.kind), [.text("a"), .text("b")])
    }
}
