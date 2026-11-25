import XCTest
@testable import SwiftDroid

final class StyleModifierTests: XCTestCase {

    private let engine = LayoutEngine.monospace(charWidth: 10, lineHeight: 20)

    private func commands(_ view: some View) -> [DrawCommand] {
        CommandRenderer().render(engine.layout(makeNode(view), proposal: ProposedSize(width: 500, height: 500)))
    }

    private func styles(_ view: some View) -> [String: TextStyle] {
        Dictionary(uniqueKeysWithValues: commands(view).compactMap { c in
            if case .text(let s) = c.kind { return (s, c.style) } else { return nil }
        })
    }

    func testModifiersEmitTextStyleNodes() {
        XCTAssertEqual(makeNode(Text("a").font(.title)).kind, .textStyle(TextStyle(font: .title)))
        XCTAssertEqual(makeNode(Text("a").bold()).kind, .textStyle(TextStyle(bold: true)))
        XCTAssertEqual(makeNode(Text("a").fontWeight(.light)).kind, .textStyle(TextStyle(weight: .light)))
        XCTAssertEqual(makeNode(Text("a").foregroundColor(.red)).kind, .textStyle(TextStyle(color: .red)))
    }

    func testFontSizeDrivesMeasurement() {
        let r = engine.layout(makeNode(Text("ab").font(.system(size: 34))), proposal: .unspecified)
        XCTAssertEqual(r.size, Size(width: 40, height: 40))
    }

    func testStyleInheritsInnerWins() {
        let s = styles(VStack {
            Text("a")
            Text("b").font(.caption)
            Text("c").foregroundColor(.blue)
        }.font(.title).foregroundColor(.red))
        XCTAssertEqual(s["a"], TextStyle(font: .title, color: .red))
        XCTAssertEqual(s["b"], TextStyle(font: .caption, color: .red))
        XCTAssertEqual(s["c"], TextStyle(font: .title, color: .blue))
    }

    func testUnstyledTextKeepsDefaultStyle() {
        XCTAssertEqual(styles(Text("a"))["a"], TextStyle())
    }

    func testOuterWeightAppliesOverInnerFont() {
        let s = styles(VStack { Text("a").font(.title) }.bold())
        XCTAssertEqual(s["a"]?.resolvedFont, Font.title.bold())
    }

    // The next three mirror SwiftUI measurements (bold and fontWeight are separate).
    func testInnerBoldFalseUndoesOuterBold() {
        XCTAssertEqual(styles(VStack { Text("a").bold(false) }.bold())["a"]?.resolvedFont, .body)
    }

    func testExplicitWeightBeatsBoldAtAnyNesting() {
        XCTAssertEqual(styles(VStack { Text("a").bold() }.fontWeight(.ultraLight))["a"]?.resolvedFont, Font.body.weight(.ultraLight))
        XCTAssertEqual(styles(VStack { Text("a").fontWeight(.ultraLight) }.bold())["a"]?.resolvedFont, Font.body.weight(.ultraLight))
        XCTAssertEqual(styles(VStack { Text("a").bold(false) }.fontWeight(.black))["a"]?.resolvedFont, Font.body.weight(.black))
    }

    func testBoldBeatsFontsOwnWeightButBoldFalseKeepsIt() {
        XCTAssertEqual(styles(Text("a").font(.title.weight(.ultraLight)).bold())["a"]?.resolvedFont, Font.title.bold())
        XCTAssertEqual(styles(Text("a").font(.headline).bold(false))["a"]?.resolvedFont, .headline)
    }

    func testStyledGroupStillFlattensIntoStack() {
        let node = makeNode(VStack(spacing: 0) { Group { Text("a"); Text("b") }.bold(); Text("c") })
        let compose = ComposeRenderer().render(node)
        XCTAssertEqual(compose.children.map(\.kind), [.text("a"), .text("b"), .text("c")])
        XCTAssertEqual(compose.children.map(\.textStyle.bold), [true, true, nil])
        XCTAssertEqual(engine.layout(node, proposal: .unspecified).children.count, 3)
    }

    func testButtonLabelInheritsStyle() {
        XCTAssertEqual(styles(Button("ok") {}.foregroundColor(.red))["ok"]?.color, .red)
    }

    func testStyledEmptyStaysEmpty() {
        XCTAssertEqual(makeNode(EmptyView().font(.title)).kind, .empty)
    }

    func testComposeTextCarriesResolvedStyle() {
        let node = ComposeRenderer().render(makeNode(Text("a").font(.headline).foregroundColor(.green)))
        XCTAssertEqual(node, ComposeNode(kind: .text("a"), textStyle: TextStyle(font: .headline, color: .green)))
    }

    func testStyleDoesNotLeakToSiblings() {
        let s = styles(HStack { Text("a").bold(); Text("b") })
        XCTAssertEqual(s["a"]?.bold, true)
        XCTAssertEqual(s["b"], TextStyle())
    }
}
