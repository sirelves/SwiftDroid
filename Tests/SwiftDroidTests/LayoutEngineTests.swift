import XCTest
@testable import SwiftDroid

/// Exercises the propose/respond layout engine. A deterministic measurer
/// (`charWidth: 10`, `lineHeight: 20`, single line) makes every size and origin
/// exactly predictable, so these assertions verify the algorithm, not fonts.
final class LayoutEngineTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    private func layout(_ view: some View, _ proposal: ProposedSize = .unspecified) -> LayoutResult {
        engine.layout(makeNode(view), proposal: proposal)
    }

    // MARK: Leaves

    func testTextSizesToContent() {
        let r = layout(Text("ab"))
        XCTAssertEqual(r.size, Size(width: 20, height: 20))
    }

    func testEmptyIsZeroSized() {
        XCTAssertEqual(layout(EmptyView()).size, .zero)
    }

    // MARK: VStack sizing & placement

    func testVStackSumsHeightsAddsSpacingTakesMaxWidth() {
        let r = layout(VStack(spacing: 5) {
            Text("ab")    // 20 x 20
            Text("cdef")  // 40 x 20
        })
        // height = 20 + 20 + 5 spacing; width = max(20, 40)
        XCTAssertEqual(r.size, Size(width: 40, height: 45))
    }

    func testVStackCenterAlignmentCentersChildrenHorizontally() {
        let r = layout(VStack(alignment: .center, spacing: 5) {
            Text("ab")    // width 20 → x = (40-20)/2 = 10
            Text("cdef")  // width 40 → x = 0
        })
        XCTAssertEqual(r.children.map(\.origin), [Point(x: 10, y: 0), Point(x: 0, y: 25)])
    }

    func testVStackLeadingAndTrailingAlignment() {
        let leading = layout(VStack(alignment: .leading, spacing: 0) {
            Text("ab"); Text("cdef")
        })
        XCTAssertEqual(leading.children.map(\.origin.x), [0, 0])

        let trailing = layout(VStack(alignment: .trailing, spacing: 0) {
            Text("ab"); Text("cdef")  // ab trailing → x = 40-20 = 20
        })
        XCTAssertEqual(trailing.children.map(\.origin.x), [20, 0])
    }

    // MARK: Spacer flexibility

    func testSpacerFillsRemainingMainSpace() {
        let r = layout(VStack(spacing: 0) {
            Text("ab")   // 20 tall
            Spacer()
            Text("cd")   // 20 tall
        }, ProposedSize(width: nil, height: 100))
        // remaining = 100 - 40 = 60 to the single spacer
        XCTAssertEqual(r.size.height, 100)
        let spacer = r.children[1]
        if case .spacer = spacer.kind {} else { XCTFail("expected spacer in slot 1") }
        XCTAssertEqual(spacer.size.height, 60)
        XCTAssertEqual(r.children.map(\.origin.y), [0, 20, 80])
    }

    func testTwoSpacersSplitRemainderEqually() {
        let r = layout(VStack(spacing: 0) {
            Spacer()
            Text("ab")   // 20 tall
            Spacer()
        }, ProposedSize(width: nil, height: 100))
        // remaining = 100 - 20 = 80, split → 40 each
        XCTAssertEqual(r.children.map(\.size.height), [40, 20, 40])
        XCTAssertEqual(r.children.map(\.origin.y), [0, 40, 60])
    }

    func testSpacerWithoutBoundedSpaceCollapsesToMinLength() {
        let r = layout(VStack(spacing: 0) {
            Text("ab")
            Spacer(minLength: 8)
        }, .unspecified) // no bounded height → spacer gets just its minLength
        XCTAssertEqual(r.children[1].size.height, 8)
        XCTAssertEqual(r.size.height, 28)
    }

    // MARK: HStack mirrors VStack on the other axis

    func testHStackSumsWidthsTakesMaxHeight() {
        let r = layout(HStack(spacing: 5) {
            Text("ab")    // 20 x 20
            Text("cdef")  // 40 x 20
        })
        XCTAssertEqual(r.size, Size(width: 65, height: 20))
        XCTAssertEqual(r.children.map(\.origin.x), [0, 25])
    }

    func testHStackTopAndBottomAlignment() {
        // Both children are 20 tall here, so cross offsets are 0 — assert the
        // axis mapping is correct (vertical alignment, horizontal placement).
        let r = layout(HStack(alignment: .top, spacing: 0) { Text("ab"); Text("cd") })
        XCTAssertEqual(r.children.map(\.origin), [Point(x: 0, y: 0), Point(x: 20, y: 0)])
    }

    // MARK: ZStack

    func testZStackSizesToBoundingBoxAndCenters() {
        let r = layout(ZStack {
            Text("ab")    // 20 x 20 → centered in 40x20 → x = 10
            Text("cdef")  // 40 x 20 → x = 0
        })
        XCTAssertEqual(r.size, Size(width: 40, height: 20))
        XCTAssertEqual(r.children.map(\.origin), [Point(x: 10, y: 0), Point(x: 0, y: 0)])
    }

    func testZStackTopLeadingAlignment() {
        let r = layout(ZStack(alignment: .topLeading) { Text("ab"); Text("cdef") })
        XCTAssertEqual(r.children.map(\.origin), [Point(x: 0, y: 0), Point(x: 0, y: 0)])
    }

    // MARK: Composition

    func testNestedStacksResolveRelativeOrigins() {
        let r = layout(VStack(spacing: 0) {
            Text("a")          // 10 x 20
            HStack(spacing: 0) {
                Text("bb")     // 20 x 20
                Text("cc")     // 20 x 20
            }                  // → 40 x 20
        })
        // Outer width = max(10, 40) = 40; height = 20 + 20 = 40
        XCTAssertEqual(r.size, Size(width: 40, height: 40))
        // Inner HStack placed at y = 20; its children keep HStack-relative origins
        let inner = r.children[1]
        XCTAssertEqual(inner.origin.y, 20)
        XCTAssertEqual(inner.children.map(\.origin.x), [0, 20])
    }

    func testEmptyViewInStackTakesNoSlotOrSpacing() {
        let withEmpty = layout(VStack(spacing: 5) {
            Text("ab")
            EmptyView()   // contributes no size and no spacing slot
            Text("cd")
        })
        let withoutEmpty = layout(VStack(spacing: 5) {
            Text("ab")
            Text("cd")
        })
        XCTAssertEqual(withEmpty.size, withoutEmpty.size)
        XCTAssertEqual(withEmpty.size, Size(width: 20, height: 45))
    }
}
