import XCTest
@testable import SwiftDroid

final class EdgeInsetsTests: XCTestCase {

    func testEdgeSetComposites() {
        XCTAssertEqual(Edge.Set.horizontal, [.leading, .trailing])
        XCTAssertEqual(Edge.Set.vertical, [.top, .bottom])
        XCTAssertEqual(Edge.Set.all, [.horizontal, .vertical])
    }

    func testInsetsFromEdgeSet() {
        XCTAssertEqual(EdgeInsets(.horizontal, 12), EdgeInsets(leading: 12, trailing: 12))
        XCTAssertEqual(EdgeInsets(.all, 4), EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        XCTAssertEqual(EdgeInsets([], 9), EdgeInsets())
    }

    func testAxisTotals() {
        let i = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        XCTAssertEqual(i.horizontal, 6)
        XCTAssertEqual(i.vertical, 4)
    }
}
