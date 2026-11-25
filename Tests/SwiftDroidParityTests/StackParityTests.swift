import XCTest
@testable import SwiftDroid

final class StackParityTests: XCTestCase {

    private let engine = LayoutEngine.monospace()

    private func node(_ c: StackChild, horizontal: Bool) -> NodeElement {
        let rigid = Text("a").frame(width: 10, height: 10)
        switch c {
        case .rigid10: return makeNode(rigid)
        case .flex(let min, let max):
            return horizontal ? makeNode(rigid.frame(minWidth: min, maxWidth: max)) : makeNode(rigid.frame(minHeight: min, maxHeight: max))
        case .spacer(let min): return makeNode(Spacer(minLength: min))
        }
    }

    func testHStackMatchesSwiftUI() {
        for c in stackCases {
            let stack = NodeElement(kind: .hstack(spacing: c.spacing, alignment: .center), children: c.children.map { node($0, horizontal: true) })
            let got = engine.layout(stack, proposal: ProposedSize(width: c.length, height: 50)).children.map(\.size.width)
            XCTAssertEqual(got, c.expected, c.name)
        }
    }

    func testVStackMatchesSwiftUI() {
        for c in stackCases {
            let stack = NodeElement(kind: .vstack(spacing: c.spacing, alignment: .center), children: c.children.map { node($0, horizontal: false) })
            let got = engine.layout(stack, proposal: ProposedSize(width: 50, height: c.length)).children.map(\.size.height)
            XCTAssertEqual(got, c.expected, c.name)
        }
    }
}
