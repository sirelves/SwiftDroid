import XCTest
@testable import SwiftDroid

final class FlexFrameParityTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    func testWidthAxisMatchesSwiftUI() {
        for c in flexFrameCases {
            let node = makeNode(Text("a").frame(width: 10, height: 10).frame(minWidth: c.min, idealWidth: c.ideal, maxWidth: c.max))
            let got = flexFrameProposals.map { engine.layout(node, proposal: ProposedSize(width: $0, height: nil)).size.width }
            XCTAssertEqual(got, c.expected, c.name)
        }
    }

    func testHeightAxisMatchesSwiftUI() {
        for c in flexFrameCases {
            let node = makeNode(Text("a").frame(width: 10, height: 10).frame(minHeight: c.min, idealHeight: c.ideal, maxHeight: c.max))
            let got = flexFrameProposals.map { engine.layout(node, proposal: ProposedSize(width: nil, height: $0)).size.height }
            XCTAssertEqual(got, c.expected, c.name)
        }
    }
}
