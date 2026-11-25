import XCTest
@testable import SwiftDroid

final class ScrollRenderTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    // Ten 20pt rows in a 50pt-tall viewport, scrolled to `y`.
    private func commands(scrolledTo y: Double, taps: (() -> Void)? = nil) -> [DrawCommand] {
        let rows = (0..<10).map { i -> NodeElement in
            i == 5 ? NodeElement(kind: .button, children: [NodeElement(kind: .text("btn"))], action: taps)
                   : NodeElement(kind: .text("r\(i)"))
        }
        let node = NodeElement(kind: .scroll(axes: .vertical, offset: Point(x: 0, y: y)),
                               children: [NodeElement(kind: .vstack(spacing: 0, alignment: .leading), children: rows)])
        return CommandRenderer().render(engine.layout(node, proposal: ProposedSize(width: 100, height: 50)))
    }

    private func texts(_ cmds: [DrawCommand]) -> [String] {
        cmds.compactMap { if case .text(let s) = $0.kind { return s } else { return nil } }
    }

    func testOnlyRowsIntersectingTheViewportAreDrawn() {
        XCTAssertEqual(texts(commands(scrolledTo: 0)), ["r0", "r1", "r2"])
        XCTAssertEqual(texts(commands(scrolledTo: 30)), ["r1", "r2", "r3"])
    }

    func testDrawnRowsCarryTheViewportClip() {
        let viewport = Rect(origin: .zero, size: Size(width: 30, height: 50))
        let row = commands(scrolledTo: 30).first { $0.kind == .text("r1") }!
        XCTAssertEqual(row.frame.origin.y, -10)
        XCTAssertEqual(row.clip, viewport)
    }

    func testScrollCommandDescribesViewportAndContent() {
        let scroll = commands(scrolledTo: 30).first!
        XCTAssertEqual(scroll.kind, .scroll(axes: .vertical, offset: Point(x: 0, y: 30), content: Size(width: 30, height: 200)))
        XCTAssertEqual(scroll.frame, Rect(origin: .zero, size: Size(width: 30, height: 50)))
    }

    func testClippedPartOfAButtonIsNotTappable() {
        var taps = 0
        // Button row spans y 100..120; scrolled to 80 it sits at 20..40, fully visible.
        let visible = commands(scrolledTo: 80) { taps += 1 }
        visible.hitTest(Point(x: 5, y: 30))?.action?()
        XCTAssertEqual(taps, 1)
        // Scrolled to 65 it sits at 35..55: the part below 50 is clipped.
        let partial = commands(scrolledTo: 65) { taps += 1 }
        XCTAssertNil(partial.hitTest(Point(x: 5, y: 52)))
        partial.hitTest(Point(x: 5, y: 40))?.action?()
        XCTAssertEqual(taps, 2)
        // Scrolled to 0 it is out of view entirely.
        XCTAssertNil(commands(scrolledTo: 0) { taps += 1 }.hitTest(Point(x: 5, y: 110)))
    }

    func testRectIntersection() {
        let a = Rect(origin: .zero, size: Size(width: 10, height: 10))
        XCTAssertEqual(a.intersection(Rect(origin: Point(x: 5, y: 5), size: Size(width: 10, height: 10))),
                       Rect(origin: Point(x: 5, y: 5), size: Size(width: 5, height: 5)))
        XCTAssertNil(a.intersection(Rect(origin: Point(x: 10, y: 0), size: Size(width: 5, height: 5))))
    }
}
