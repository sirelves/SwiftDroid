import XCTest
@testable import SwiftDroid

private final class Synthesised: SwiftDroid.ObservableObject {
    @SwiftDroid.Published var value = 0
    @SwiftDroid.Published var other = ""
}

private class BaseModel: SwiftDroid.ObservableObject {
    @SwiftDroid.Published var base = 0
}

private final class DerivedModel: BaseModel {
    var plain = 0
}

private final class NoPublished: SwiftDroid.ObservableObject {
    var plain = 0
}

final class SynthesisedObjectWillChangeTests: XCTestCase {

    func testSynthesisedSubjectIsStablePerObject() {
        let a = Synthesised(), b = Synthesised()
        XCTAssertTrue(a.objectWillChange === a.objectWillChange)
        XCTAssertFalse(a.objectWillChange === b.objectWillChange)
    }

    func testEveryPublishedPropertyFiresTheSameSubject() {
        let model = Synthesised()
        var fired = 0
        let c = model.objectWillChange.sink { fired += 1 }
        model.value = 1
        model.other = "x"
        XCTAssertEqual(fired, 2)
        _ = c
    }

    func testFiresBeforeTheValueChanges() {
        let model = Synthesised()
        var seen: Int?
        let c = model.objectWillChange.sink { seen = model.value }
        model.value = 5
        XCTAssertEqual(seen, 0)
        _ = c
    }

    func testSubclassFindsPublishedInSuperclass() {
        let model = DerivedModel()
        XCTAssertTrue(model.objectWillChange === model.objectWillChange)
        var fired = false
        let c = model.objectWillChange.sink { fired = true }
        model.base = 1
        XCTAssertTrue(fired)
        _ = c
    }

    func testNoPublishedGetsFreshSubjectEachAccess() {
        let model = NoPublished()
        XCTAssertFalse(model.objectWillChange === model.objectWillChange)
    }
}
