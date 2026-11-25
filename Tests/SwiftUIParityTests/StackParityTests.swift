#if canImport(AppKit)
import XCTest
import SwiftUI
import AppKit

private final class Placements { var sizes: [Int: CGSize] = [:] }

// Records the bounds its stack assigned to the wrapped child.
private struct Recorder: Layout {
    let index: Int
    let placements: Placements
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews[0].sizeThatFits(proposal)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        placements.sizes[index] = bounds.size
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

@MainActor
final class StackParityTests: XCTestCase {

    private func view(_ c: StackChild, horizontal: Bool) -> AnyView {
        let rigid = Color.clear.frame(width: 10, height: 10)
        switch c {
        case .rigid10: return AnyView(rigid)
        case .flex(let min, let max):
            let lo = min.map { CGFloat($0) }, hi = max.map { CGFloat($0) }
            return horizontal ? AnyView(rigid.frame(minWidth: lo, maxWidth: hi)) : AnyView(rigid.frame(minHeight: lo, maxHeight: hi))
        case .spacer(let min): return AnyView(Spacer(minLength: min.map { CGFloat($0) }))
        }
    }

    private func placed(_ c: StackCase, horizontal: Bool) -> [Double] {
        let placements = Placements()
        let kids = c.children.map { view($0, horizontal: horizontal) }
        let items = ForEach(kids.indices, id: \.self) { i in Recorder(index: i, placements: placements) { kids[i] } }
        let size = horizontal ? CGSize(width: c.length, height: 50) : CGSize(width: 50, height: c.length)
        let root = horizontal
            ? AnyView(HStack(spacing: CGFloat(c.spacing)) { items }.frame(width: size.width, height: size.height))
            : AnyView(VStack(spacing: CGFloat(c.spacing)) { items }.frame(width: size.width, height: size.height))
        let host = NSHostingView(rootView: root)
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        return kids.indices.map { Double(horizontal ? placements.sizes[$0]?.width ?? -1 : placements.sizes[$0]?.height ?? -1) }
    }

    func testHStackMatchesTable() {
        for c in stackCases { XCTAssertEqual(placed(c, horizontal: true), c.expected, c.name) }
    }

    func testVStackMatchesTable() {
        for c in stackCases { XCTAssertEqual(placed(c, horizontal: false), c.expected, c.name) }
    }
}
#endif
