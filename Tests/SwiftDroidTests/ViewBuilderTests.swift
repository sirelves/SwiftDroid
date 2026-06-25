import XCTest
@testable import SwiftDroid

/// Verifies that the `@ViewBuilder` result-builder transform produces the
/// expected concrete types. These assertions are about *type identity* — that a
/// two-child block becomes `TupleView<(Text, Text)>`, an `if/else` becomes
/// `_ConditionalContent`, and so on — which is exactly the SwiftUI contract.
final class ViewBuilderTests: XCTestCase {

    // A helper view whose body exercises the builder, so we read `body`'s type.
    private struct Pair: View {
        var body: some View {
            Text("a")
            Text("b")
        }
    }

    // MARK: buildBlock arities

    func testEmptyBlockIsEmptyView() {
        let v = ViewBuilder.buildBlock()
        XCTAssertTrue(type(of: v) == EmptyView.self)
    }

    func testSingleChildIsPassedThroughUnchanged() {
        let v = ViewBuilder.buildBlock(Text("solo"))
        XCTAssertTrue(type(of: v) == Text.self)
    }

    func testTwoChildrenFoldIntoTupleView() {
        let v = ViewBuilder.buildBlock(Text("a"), Text("b"))
        XCTAssertTrue(type(of: v) == TupleView<(Text, Text)>.self)
    }

    func testTenChildrenFoldIntoTupleView() {
        let v = ViewBuilder.buildBlock(
            Text("0"), Text("1"), Text("2"), Text("3"), Text("4"),
            Text("5"), Text("6"), Text("7"), Text("8"), Text("9")
        )
        XCTAssertTrue(
            type(of: v) == TupleView<(Text, Text, Text, Text, Text, Text, Text, Text, Text, Text)>.self
        )
    }

    func testBodyBuilderProducesTupleView() {
        XCTAssertTrue(type(of: Pair().body) == TupleView<(Text, Text)>.self)
    }

    // MARK: Conditionals

    func testBuildEitherFirstAndSecondShareOneType() {
        let first = ViewBuilder.buildEither(first: Text("yes")) as _ConditionalContent<Text, Text>
        let second = ViewBuilder.buildEither(second: Text("no")) as _ConditionalContent<Text, Text>
        XCTAssertTrue(type(of: first) == type(of: second))
    }

    func testBuildOptionalWrapsInOptional() {
        let present = ViewBuilder.buildOptional(Text("here"))
        let absent: Text? = ViewBuilder.buildOptional(nil)
        XCTAssertNotNil(present)
        XCTAssertNil(absent)
    }
}
