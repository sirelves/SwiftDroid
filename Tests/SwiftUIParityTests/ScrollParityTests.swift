#if canImport(AppKit)
import XCTest
import SwiftUI
import AppKit

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
final class ScrollParityTests: XCTestCase {
    private func measure<V: SwiftUI.View>(_ view: V, _ p: ProposedViewSize) -> [Double] {
        var out = CGSize.zero
        _ = NSHostingController(rootView: Probe(proposal: p, record: { out = $0 }) { view }).view.fittingSize
        return [Double(out.width), Double(out.height)]
    }

    func testScrollViewSizingMatchesTable() {
        let content = Color.clear.frame(width: 100, height: 300)
        for c in scrollCases {
            let p = ProposedViewSize(width: c.width.map { CGFloat($0) }, height: c.height.map { CGFloat($0) })
            XCTAssertEqual(measure(ScrollView { content }, p), [c.vertical.0, c.vertical.1], "vertical \(p)")
            XCTAssertEqual(measure(ScrollView(.horizontal) { content }, p), [c.horizontal.0, c.horizontal.1], "horizontal \(p)")
        }
    }
}
#endif
