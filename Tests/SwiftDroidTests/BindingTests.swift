import XCTest
@testable import SwiftDroid

final class BindingTests: XCTestCase {

    func testBindingReadsFromState() {
        let state = State(wrappedValue: 5)
        let binding = state.projectedValue

        XCTAssertEqual(binding.wrappedValue, 5)
    }

    func testWritingBindingUpdatesState() {
        let state = State(wrappedValue: 0)
        let binding = state.projectedValue

        binding.wrappedValue = 42

        XCTAssertEqual(state.wrappedValue, 42)
    }

    func testStateNotifiesWhenUpdatedViaBinding() {
        let state = State(wrappedValue: 0)
        var notified = false
        let obs = AnyObservation { notified = true }
        state.storage.addObserver(obs)

        let binding = state.projectedValue
        binding.wrappedValue = 1

        XCTAssertTrue(notified)
    }

    func testConstantBindingNeverTriggers() {
        let binding = Binding<Int>.constant(100)
        // Writing a constant binding is a no-op; the value never changes.
        binding.wrappedValue = 999
        XCTAssertEqual(binding.wrappedValue, 100)
    }

    func testChainedBindingPropagates() {
        // A binding derived from another binding should write through to the source.
        let state = State(wrappedValue: 0)
        let bindingA = state.projectedValue
        let bindingB = Binding<Int>(
            get: { bindingA.wrappedValue },
            set: { bindingA.wrappedValue = $0 }
        )

        bindingB.wrappedValue = 77

        XCTAssertEqual(state.wrappedValue, 77)
    }

    func testBindingProjectedValueReturnsSelf() {
        let binding = Binding<String>(get: { "hi" }, set: { _ in })
        // $binding should give back the same binding for forwarding to child views.
        let projected = binding.projectedValue
        XCTAssertEqual(projected.wrappedValue, "hi")
    }
}
