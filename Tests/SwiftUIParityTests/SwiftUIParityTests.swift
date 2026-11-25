#if canImport(SwiftUI)
import XCTest
import SwiftUI
import Combine
#if canImport(AppKit)
import AppKit
#endif

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
        assertRenders(ParityModifiers())
        assertRenders(ParityStyles())
    }

    #if canImport(AppKit)
    // Same deltas over the text's natural size that SwiftDroidParityTests.testModifiersLayout expects.
    func testModifierLayoutMatchesCore() {
        func size<V: SwiftUI.View>(_ v: V) -> CGSize { NSHostingController(rootView: v).view.fittingSize }
        let t = size(Text("a"))
        XCTAssertEqual(size(Text("a").padding()), CGSize(width: t.width + 32, height: t.height + 32))
        XCTAssertEqual(size(Text("a").padding(8)), CGSize(width: t.width + 16, height: t.height + 16))
        XCTAssertEqual(size(Text("a").padding(.horizontal, 12)), CGSize(width: t.width + 24, height: t.height))
        XCTAssertEqual(size(Text("a").padding(EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4))),
                       CGSize(width: t.width + 6, height: t.height + 4))
        XCTAssertEqual(size(Text("a").frame(width: 100, height: 40, alignment: .topLeading)), CGSize(width: 100, height: 40))
        XCTAssertEqual(size(Text("a").frame(height: 30).padding(.top)), CGSize(width: t.width, height: 46))
        XCTAssertEqual(size(VStack(spacing: 0) { EmptyView().padding().frame(width: 50); Text("a") }), t)
    }

    // Same weight rules as StyleModifierTests, checked through text widths.
    func testBoldAndFontWeightRules() {
        func w<V: SwiftUI.View>(_ v: V) -> CGFloat { NSHostingController(rootView: v).view.fittingSize.width }
        let t = "WWWWWWWWWW"
        XCTAssertNotEqual(w(Text(t)), w(Text(t).bold()))
        XCTAssertEqual(w(VStack { Text(t).bold(false) }.bold()), w(Text(t)))
        XCTAssertEqual(w(VStack { Text(t).bold() }.fontWeight(.ultraLight)), w(Text(t).fontWeight(.ultraLight)))
        XCTAssertEqual(w(VStack { Text(t).fontWeight(.ultraLight) }.bold()), w(Text(t).fontWeight(.ultraLight)))
        XCTAssertEqual(w(VStack { Text(t).bold(false) }.fontWeight(.black)), w(Text(t).fontWeight(.black)))
        XCTAssertEqual(w(Text(t).font(.title.weight(.ultraLight)).bold()), w(Text(t).font(.title.bold())))
        XCTAssertEqual(w(Text(t).font(.headline).fontWeight(.regular)), w(Text(t)))
    }
    #endif

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
