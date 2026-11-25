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

final class ObservedObjectReRenderTests: XCTestCase {

    private final class Model: SwiftDroid.ObservableObject {
        @SwiftDroid.Published var taps = 0
    }

    private struct Screen: View {
        @SwiftDroid.ObservedObject var model: Model
        var body: some View {
            VStack {
                Text("Taps: \(model.taps)")
                Button("Tap") { model.taps += 1 }
            }
        }
    }

    private func texts(_ cmds: [DrawCommand]) -> [String] {
        cmds.compactMap { if case .text(let s) = $0.kind { return s } else { return nil } }
    }

    func testExternalMutationReRendersWithNewValue() {
        let model = Model()
        let host = ViewHost(Screen(model: model), engine: .monospace(), proposal: .unspecified)
        XCTAssertTrue(texts(host.commands).contains("Taps: 0"))
        model.taps = 3
        XCTAssertTrue(texts(host.commands).contains("Taps: 3"))
    }

    func testButtonMutatingModelReRenders() {
        let model = Model()
        let host = ViewHost(Screen(model: model), engine: .monospace(), proposal: .unspecified)
        let f = host.commands.first { $0.kind == .button }!.frame
        host.tap(at: Point(x: f.origin.x + f.width / 2, y: f.origin.y + f.height / 2))
        XCTAssertEqual(model.taps, 1)
        XCTAssertTrue(texts(host.commands).contains("Taps: 1"))
    }

    func testRepeatedRendersDoNotMultiplyInvalidations() {
        let model = Model()
        let host = ViewHost(Screen(model: model), engine: .monospace(), proposal: .unspecified)
        for _ in 0..<5 { host.render() }
        var renders = 0
        host.onRender = { _ in renders += 1 }
        model.taps = 1
        XCTAssertEqual(renders, 1)
    }
}
