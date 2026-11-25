import XCTest
@testable import SwiftDroid

private final class Item: SwiftDroid.ObservableObject {
    @SwiftDroid.Published var value = 0
}

final class ObservedObjectProjectionTests: XCTestCase {

    func testDollarProjectionYieldsReadWriteBinding() {
        let model = Item()
        let wrapper = ObservedObject(wrappedValue: model)
        let binding: Binding<Int> = wrapper.projectedValue.value
        binding.wrappedValue = 42
        XCTAssertEqual(model.value, 42)
        XCTAssertEqual(binding.wrappedValue, 42)
    }
}
