#if canImport(AppKit)
import XCTest
import SwiftUI
import AppKit

private final class Built { var rows = Set<Int>() }

private struct Row: View {
    let i: Int
    let built: Built
    var body: some View {
        built.rows.insert(i)
        return Color.clear.frame(width: 50, height: 20)
    }
}

private struct Probe: Layout {
    let proposal: ProposedViewSize
    let record: (CGSize) -> Void
    func sizeThatFits(proposal _: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let s = subviews[0].sizeThatFits(proposal)
        record(s)
        return CGSize(width: min(s.width, 1e5), height: min(s.height, 1e5))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {}
}

@MainActor
final class LazyParityTests: XCTestCase {

    func testSizingMatchesTable() {
        for c in lazyWidthCases {
            var out = CGSize.zero
            let stack = LazyVStack(spacing: 0) { ForEach(0..<1000) { Row(i: $0, built: Built()) } }
            let p = ProposedViewSize(width: c.proposedWidth.map { CGFloat($0) }, height: nil)
            _ = NSHostingController(rootView: Probe(proposal: p, record: { out = $0 }) { stack }).view.fittingSize
            XCTAssertEqual([Double(out.width), Double(out.height)], [c.width, lazyTotalHeight])
        }
    }

    func testBuiltRowsMatchTable() {
        let built = Built()
        let view = ScrollView { LazyVStack(spacing: 0) { ForEach(0..<1000) { Row(i: $0, built: built) } } }
            .frame(width: 300, height: 200)
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        host.layoutSubtreeIfNeeded()
        XCTAssertEqual(built.rows, lazyBuiltRows)
    }
}
#endif
