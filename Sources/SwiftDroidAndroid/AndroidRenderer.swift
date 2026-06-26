import SwiftDroid

/// Bridges a SwiftDroid view tree to Jetpack Compose on Android.
///
/// The mapping (`NodeElement` → `ComposeNode`) lives in the platform-agnostic core
/// and is fully unit-tested there. This adapter consumes that plan. The actual
/// `@Composable` emission — turning a `ComposeNode` into Compose `Column`/`Row`/
/// `Box`/`Text`/`Button`/`Spacer` calls — happens in the `#if canImport(Android)`
/// block via swift-java; see `docs/internals/android-renderer.md` for the build
/// (Swift Android SDK + swift-java + Gradle/JNI host).
public enum AndroidRenderer {
    /// The Compose plan for a root view — ready for the executor to render.
    /// Platform-agnostic, so it is exercised by tests on any host.
    public static func plan(for root: some View) -> ComposeNode {
        ComposeRenderer().render(root._makeNode())
    }

    /// A readable preview of the Compose tree a view maps to (logs / debugging).
    public static func describe(_ root: some View) -> String {
        var out = ""
        describe(plan(for: root), indent: 0, into: &out)
        return out
    }

    private static func describe(_ node: ComposeNode, indent: Int, into out: inout String) {
        let pad = String(repeating: "  ", count: indent)
        let label: String
        switch node.kind {
        case .text(let s):                     label = "Text(\"\(s)\")"
        case .button:                          label = "Button"
        case .column(let sp, let a):           label = "Column(spacing: \(sp), \(a))"
        case .row(let sp, let a):              label = "Row(spacing: \(sp), \(a))"
        case .box(let a):                      label = "Box(\(a))"
        case .spacer(let m):                   label = "Spacer(min: \(m))"
        }
        out += "\(pad)\(label)\n"
        for child in node.children { describe(child, indent: indent + 1, into: &out) }
    }
}

#if canImport(Android)
import Android

extension AndroidRenderer {
    /// Render `root` into Compose, re-rendering on `@State` changes.
    ///
    /// Wiring point for the JNI/Compose host: build the `ComposeNode` plan and
    /// emit it as `@Composable` calls. Requires the swift-java AndroidX Compose
    /// bindings (not yet a package dependency) — `emit(_:)` is the single TODO
    /// that turns the validated plan into live UI.
    public static func setContent(_ root: some View) {
        let host = ViewHost(root, engine: .monospace(), proposal: .infinity)
        host.onRender = { _ in /* TODO(swift-java): request Compose recomposition */ }
        emit(plan(for: root))
    }

    private static func emit(_ node: ComposeNode) {
        // TODO(swift-java): map each ComposeNode kind to its AndroidX Compose call:
        //   .column → Column(verticalArrangement = spacedBy(spacing)) { children }
        //   .row    → Row(horizontalArrangement = spacedBy(spacing))  { children }
        //   .box    → Box(contentAlignment = ...)                     { children }
        //   .text   → Text(text)
        //   .button → Button(onClick = action) { emit(label) }
        //   .spacer → Spacer(Modifier.weight(1f) or size(minLength))
        // Recurse into node.children. Requires Compose bindings via swift-java.
    }
}
#endif
