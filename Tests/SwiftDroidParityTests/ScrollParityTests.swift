import XCTest
@testable import SwiftDroid

final class ScrollParityTests: XCTestCase {
    func testScrollViewSizingMatchesSwiftUI() {
        let engine = LayoutEngine.monospace()
        let content = Text("a").frame(width: 100, height: 300)
        for c in scrollCases {
            let p = ProposedSize(width: c.width, height: c.height)
            let v = engine.layout(makeNode(ScrollView { content }), proposal: p).size
            let h = engine.layout(makeNode(ScrollView(.horizontal) { content }), proposal: p).size
            XCTAssertEqual([v.width, v.height], [c.vertical.0, c.vertical.1], "vertical \(p)")
            XCTAssertEqual([h.width, h.height], [c.horizontal.0, c.horizontal.1], "horizontal \(p)")
        }
    }
}
