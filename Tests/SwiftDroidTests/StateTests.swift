import XCTest
@testable import SwiftDroid

final class StateTests: XCTestCase {

    // MARK: Basic value semantics

    func testInitialValueIsCorrect() {
        let state = State(wrappedValue: 42)
        XCTAssertEqual(state.wrappedValue, 42)
    }

    func testWriteUpdatesValue() {
        let state = State(wrappedValue: 0)
        state.wrappedValue = 99
        XCTAssertEqual(state.wrappedValue, 99)
    }

    // MARK: Notification

    func testSubscriberIsNotifiedAfterWrite() {
        let state = State(wrappedValue: 0)
        var notified = false
        let obs = AnyObservation { notified = true }
        state.storage.addObserver(obs)

        state.wrappedValue = 1

        XCTAssertTrue(notified)
    }

    func testMultipleSubscribersAreAllNotified() {
        let state = State(wrappedValue: 0)
        var count = 0
        let obs1 = AnyObservation { count += 1 }
        let obs2 = AnyObservation { count += 1 }
        let obs3 = AnyObservation { count += 1 }
        state.storage.addObserver(obs1)
        state.storage.addObserver(obs2)
        state.storage.addObserver(obs3)

        state.wrappedValue = 1

        XCTAssertEqual(count, 3)
    }

    // MARK: Equatable short-circuit

    func testNoNotificationWhenEquatableValueUnchanged() {
        // State<Int> uses the Equatable init, so == writes are suppressed.
        let state = State(wrappedValue: 7)
        var notified = false
        let obs = AnyObservation { notified = true }
        state.storage.addObserver(obs)

        state.wrappedValue = 7  // same value — no notification expected

        XCTAssertFalse(notified)
    }

    func testNotificationForChangedEquatableValue() {
        let state = State(wrappedValue: 7)
        var notified = false
        let obs = AnyObservation { notified = true }
        state.storage.addObserver(obs)

        state.wrappedValue = 8

        XCTAssertTrue(notified)
    }

    // MARK: Projected value

    func testProjectedValueIsBinding() {
        let state = State(wrappedValue: 10)
        let binding = state.projectedValue

        XCTAssertEqual(binding.wrappedValue, 10)

        binding.wrappedValue = 20
        XCTAssertEqual(state.wrappedValue, 20)
    }
}
