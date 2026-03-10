import XCTest
@testable import SwiftDroid

final class DependencyGraphTests: XCTestCase {

    // MARK: - Dependency registration

    func testReadingStateRegistersObserver() {
        let storage = StateStorage(0)
        var notified = false
        let obs = AnyObservation { notified = true }

        DependencyTracker.shared.withObservation(obs) {
            _ = storage.value   // registers obs
        }

        storage.value = 1
        XCTAssertTrue(notified)
    }

    func testReadingTwoStatesRegistersOnBoth() {
        let state1 = StateStorage(0)
        let state2 = StateStorage(0)
        var count = 0
        let obs = AnyObservation { count += 1 }

        DependencyTracker.shared.withObservation(obs) {
            _ = state1.value
            _ = state2.value
        }

        state1.value = 1
        XCTAssertEqual(count, 1, "Writing state1 should invalidate observer")

        // Re-register before checking state2.
        DependencyTracker.shared.withObservation(obs) {
            _ = state1.value
            _ = state2.value
        }

        state2.value = 1
        XCTAssertEqual(count, 2, "Writing state2 should also invalidate observer")
    }

    func testNotReadingStateDoesNotInvalidate() {
        let state1 = StateStorage(0)
        let state2 = StateStorage(0)  // never read
        var count = 0
        let obs = AnyObservation { count += 1 }

        DependencyTracker.shared.withObservation(obs) {
            _ = state1.value   // only state1 is read
        }

        state2.value = 99   // should NOT notify obs
        XCTAssertEqual(count, 0)

        state1.value = 1    // SHOULD notify obs
        XCTAssertEqual(count, 1)
    }

    func testNoObserverRegisteredOutsideTrackingContext() {
        let storage = StateStorage(0)
        var notified = false
        let obs = AnyObservation { notified = true }

        // Read without pushing obs onto the tracker.
        _ = storage.value

        // Manually add obs so we can verify the read above did NOT add it twice.
        storage.addObserver(obs)
        storage.value = 1

        XCTAssertTrue(notified)  // added manually — fires once
    }

    // MARK: - Batching

    func testBatchingCollapses3WritesTo1Notification() {
        let state = State(wrappedValue: 0)
        var notificationCount = 0
        let obs = AnyObservation { notificationCount += 1 }
        state.storage.addObserver(obs)

        InvalidationQueue.shared.transaction {
            state.wrappedValue = 1
            state.wrappedValue = 2
            state.wrappedValue = 3
        }

        XCTAssertEqual(notificationCount, 1)
    }

    func testWritesOutsideTransactionFireImmediately() {
        let state = State(wrappedValue: 0)
        var notificationCount = 0
        let obs = AnyObservation { notificationCount += 1 }
        state.storage.addObserver(obs)

        state.wrappedValue = 1
        state.wrappedValue = 2
        state.wrappedValue = 3

        XCTAssertEqual(notificationCount, 3)
    }

    func testNestedTransactionFlushesOnlyAtOutermostExit() {
        let state = State(wrappedValue: 0)
        var notificationCount = 0
        let obs = AnyObservation { notificationCount += 1 }
        state.storage.addObserver(obs)

        InvalidationQueue.shared.transaction {
            InvalidationQueue.shared.transaction {
                state.wrappedValue = 1  // still inside outer transaction
            }
            // Inner transaction exited but outer is still open — no flush yet.
            XCTAssertEqual(notificationCount, 0)
        }
        // Now outer exited — should flush once.
        XCTAssertEqual(notificationCount, 1)
    }
}
