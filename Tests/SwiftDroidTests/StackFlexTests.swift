import XCTest
@testable import SwiftDroid

final class StackFlexTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)
    private var r10: some View { Text("a").frame(width: 10, height: 10) }

    private func widths(_ w: Double, spacing: Double = 0, @ViewBuilder _ content: () -> some View) -> [Double] {
        engine.layout(makeNode(HStack(spacing: spacing, content: content)), proposal: ProposedSize(width: w, height: 50))
            .children.map(\.size.width)
    }

    func testLeastFlexibleFirstThenEqualShares() {
        XCTAssertEqual(widths(200) { r10; r10.frame(maxWidth: .infinity); r10.frame(maxWidth: .infinity) }, [10, 95, 95])
        XCTAssertEqual(widths(200) { r10.frame(maxWidth: .infinity); r10.frame(maxWidth: 30) }, [170, 30])
    }

    func testTiesKeepSourceOrder() {
        XCTAssertEqual(widths(200) { r10.frame(minWidth: 150, maxWidth: .infinity); r10.frame(maxWidth: .infinity) }, [150, 50])
    }

    func testOverflowWhenMinimaExceedSpace() {
        XCTAssertEqual(widths(30) { r10.frame(minWidth: 20, maxWidth: .infinity); r10.frame(minWidth: 20, maxWidth: .infinity) }, [20, 20])
    }

    func testSpacingIsReservedBeforeSharing() {
        XCTAssertEqual(widths(100, spacing: 5) { r10.frame(maxWidth: 30); r10.frame(maxWidth: 30); r10.frame(maxWidth: .infinity) }, [30, 30, 30])
    }

    func testSpacerCompetesWithFlexibleFrames() {
        XCTAssertEqual(widths(200) { r10; Spacer(minLength: 0); r10.frame(maxWidth: .infinity) }, [10, 95, 95])
    }

    func testUnspecifiedProposalUsesIdealSizes() {
        let r = engine.layout(makeNode(HStack(spacing: 0) { r10.frame(idealWidth: 40, maxWidth: .infinity); Spacer(minLength: 3) }), proposal: .unspecified)
        XCTAssertEqual(r.children.map(\.size.width), [40, 3])
    }

    func testNestedStacksMeasureEachLeafABoundedNumberOfTimes() {
        func tree(_ depth: Int) -> NodeElement {
            depth == 0 ? NodeElement(kind: .text("abc"))
                : NodeElement(kind: depth.isMultiple(of: 2) ? .vstack(spacing: 4, alignment: .center) : .hstack(spacing: 4, alignment: .center),
                              children: (0..<3).map { _ in tree(depth - 1) })
        }
        var calls = 0
        let counting = LayoutEngine { t, _ in calls += 1; return Size(width: Double(t.count) * 10, height: 20) }
        _ = counting.layout(tree(6), proposal: ProposedSize(width: 400, height: 800))
        XCTAssertLessThan(calls, 729 * 10)  // was 531_441 before memoisation
    }
}

final class SpacerDefaultTests: XCTestCase {
    func testDefaultMinLengthMatchesSwiftUI() {
        XCTAssertEqual(makeNode(Spacer()).kind, .spacer(minLength: 8))
        XCTAssertEqual(makeNode(Spacer(minLength: 0)).kind, .spacer(minLength: 0))
    }

    func testDefaultSpacerKeepsMinimumWhenSqueezed() {
        let node = makeNode(HStack(spacing: 0) { Text("a").frame(width: 10, height: 10); Spacer(); Text("b").frame(width: 10, height: 10) })
        let r = LayoutEngine.monospace().layout(node, proposal: ProposedSize(width: 20, height: 10))
        XCTAssertEqual(r.children.map(\.size.width), [10, 8, 10])
    }
}
