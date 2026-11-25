#if canImport(SwiftUI)
import XCTest
import SwiftUI
import Combine

// Compiling the fixtures is the main assertion; these check they really are
// SwiftUI types and that SwiftUI can render each one.
@MainActor
final class SwiftUIParityTests: XCTestCase {

    private func assertRenders<V: SwiftUI.View>(_ view: V, file: StaticString = #filePath, line: UInt = #line) {
        let renderer = ImageRenderer(content: view.frame(width: 320, height: 480))
        XCTAssertNotNil(renderer.cgImage, "\(V.self) did not render", file: file, line: line)
    }

    func testFixturesRenderWithSwiftUI() {
        assertRenders(ParityCounter())
        assertRenders(ParityStacks())
        assertRenders(ParityConditional(flag: true))
        assertRenders(ParityConditional(flag: false))
        assertRenders(ParityBindingParent())
        assertRenders(ParityModelView(model: ParityModel()))
        assertRenders(ParityGroup())
    }

    func testModelUsesCombineSynthesisedPublisher() {
        let model = ParityModel()
        var fired = 0
        let c = model.objectWillChange.sink { fired += 1 }
        model.taps += 1
        model.name = "x"
        XCTAssertEqual(fired, 2)
        _ = c
    }
}
#endif
