import XCTest
@testable import SwiftDroid

// MARK: - Test fixture
// Fully-qualified names avoid ambiguity with Combine's ObservableObject / Published
// that Foundation re-exports on macOS. On Android/Linux there is no Combine so
// the conflict does not exist there.

private final class Counter: SwiftDroid.ObservableObject {
    let objectWillChange = PassthroughSubject<Void>()

    @SwiftDroid.Published var count = 0
    @SwiftDroid.Published var label = "hello"
}

// MARK: - Tests

final class ObservedObjectTests: XCTestCase {

    func testPublishedMutationTriggersObjectWillChange() {
        let counter = Counter()
        var fired = false
        let cancellable = counter.objectWillChange.sink { fired = true }

        counter.count += 1

        XCTAssertTrue(fired)
        _ = cancellable  // keep alive
    }

    func testMultipleSubscribersAllNotified() {
        let counter = Counter()
        var count1 = 0
        var count2 = 0
        let c1 = counter.objectWillChange.sink { count1 += 1 }
        let c2 = counter.objectWillChange.sink { count2 += 1 }

        counter.count = 10

        XCTAssertEqual(count1, 1)
        XCTAssertEqual(count2, 1)
        _ = (c1, c2)
    }

    func testDifferentPublishedPropertiesBothTrigger() {
        let counter = Counter()
        var fireCount = 0
        let cancellable = counter.objectWillChange.sink { fireCount += 1 }

        counter.count = 1
        counter.label = "world"

        XCTAssertEqual(fireCount, 2)
        _ = cancellable
    }

    func testCancellableStopsNotifications() {
        let counter = Counter()
        var fireCount = 0
        var cancellable: AnyCancellable? = counter.objectWillChange.sink { fireCount += 1 }

        counter.count = 1
        XCTAssertEqual(fireCount, 1)

        cancellable = nil   // dealloc triggers cancel
        counter.count = 2
        XCTAssertEqual(fireCount, 1, "Notifications should stop after cancellation")
    }

    func testObservedObjectStoresObject() {
        let counter = Counter()
        let wrapper = ObservedObject(wrappedValue: counter)
        XCTAssertTrue(wrapper.wrappedValue === counter)
    }
}
