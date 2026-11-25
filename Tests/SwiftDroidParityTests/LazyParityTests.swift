import XCTest
@testable import SwiftDroid

final class LazyParityTests: XCTestCase {

    final class Built { var rows = Set<Int>() }

    struct Row: View {
        let i: Int
        let built: Built
        var body: some View {
            built.rows.insert(i)
            return Text("r").frame(width: 50, height: 20)
        }
    }

    private func stack(_ built: Built) -> LazyVStack<ForEach<Range<Int>, Int, Row>> {
        LazyVStack(spacing: 0) { ForEach(0..<1000) { Row(i: $0, built: built) } }
    }

    func testSizingMatchesSwiftUI() {
        let engine = LayoutEngine.monospace()
        for c in lazyWidthCases {
            let size = engine.layout(makeNode(stack(Built())), proposal: ProposedSize(width: c.proposedWidth, height: nil)).size
            XCTAssertEqual(size, Size(width: c.width, height: lazyTotalHeight), "\(String(describing: c.proposedWidth))")
        }
    }

    func testBuiltRowsMatchSwiftUI() {
        let built = Built()
        struct Screen: View {
            let built: Built
            var body: some View { ScrollView { LazyVStack(spacing: 0) { ForEach(0..<1000) { Row(i: $0, built: built) } } } }
        }
        _ = ViewHost(Screen(built: built), engine: .monospace(), proposal: ProposedSize(width: 300, height: 200))
        XCTAssertEqual(built.rows, lazyBuiltRows)
    }
}
