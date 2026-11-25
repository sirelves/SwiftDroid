#if canImport(AppKit)
import XCTest
import SwiftUI
import AppKit

// Proposes an exact size to its child and records the answer (clamped for the host).
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
final class FlexFrameParityTests: XCTestCase {

    private func measure<V: SwiftUI.View>(_ view: V, _ proposal: ProposedViewSize) -> CGSize {
        var out = CGSize.zero
        _ = NSHostingController(rootView: Probe(proposal: proposal, record: { out = $0 }) { view }).view.fittingSize
        return out
    }

    private func cg(_ v: Double?) -> CGFloat? { v.map { CGFloat($0) } }

    func testWidthAxisMatchesTable() {
        for c in flexFrameCases {
            let view = Text("a").frame(width: 10, height: 10).frame(minWidth: cg(c.min), idealWidth: cg(c.ideal), maxWidth: cg(c.max))
            let got = flexFrameProposals.map { Double(measure(view, ProposedViewSize(width: cg($0), height: nil)).width) }
            XCTAssertEqual(got, c.expected, c.name)
        }
    }

    func testHeightAxisMatchesTable() {
        for c in flexFrameCases {
            let view = Text("a").frame(width: 10, height: 10).frame(minHeight: cg(c.min), idealHeight: cg(c.ideal), maxHeight: cg(c.max))
            let got = flexFrameProposals.map { Double(measure(view, ProposedViewSize(width: nil, height: cg($0))).height) }
            XCTAssertEqual(got, c.expected, c.name)
        }
    }
}
#endif
