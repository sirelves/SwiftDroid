/// The base protocol for everything that can be drawn.
///
/// Mirrors SwiftUI's `View`: an associated `Body` (itself a `View`) and a
/// `@ViewBuilder`-annotated `body` getter. Because `Body` is an associated type,
/// `View` is a generic protocol — it cannot be used as a plain existential
/// without `any`, and every concrete view declares its `body` type at compile
/// time. Opaque `some View` return types let authors keep that type private
/// while the compiler still resolves it concretely (zero-cost, no boxing).
///
/// ### `_makeNode()` is a requirement, not an extension
///
/// Collapsing a view graph into a `NodeElement` tree happens by walking children
/// that have been erased to `any View` (see `TupleView`). A method called on an
/// existential dispatches *dynamically* only when it is a protocol requirement —
/// a method that lived solely in a protocol extension would always resolve to
/// the default, and leaf overrides like `Text`'s would never run. So `_makeNode()`
/// is declared here and the recursive default lives in the extension below.
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }

    /// Collapse this view into a concrete `NodeElement` tree.
    /// Composite views inherit the recursive default; primitive (leaf) views
    /// override it to emit their own node.
    func _makeNode() -> NodeElement
}

extension View {
    /// Default for composite views: a view's rendered form is its body's
    /// rendered form. Recursion terminates at primitives, which override this,
    /// and ultimately at `Never` (which is never instantiated).
    public func _makeNode() -> NodeElement {
        body._makeNode()
    }
}

/// `Never` is the leaf base case of the `Body` recursion. Primitive views
/// (`Text`, `EmptyView`, …) declare `Body == Never`; their `body` is
/// unreachable by construction, so it traps. This terminates the recursive
/// type tree the compiler builds when resolving `some View`.
extension Never: View {
    public var body: Never { fatalError("Never has no body") }
}

/// Render any view into its `NodeElement` tree. The public entry point used by
/// renderers and tests; thin wrapper over the `_makeNode()` requirement.
public func makeNode<V: View>(_ view: V) -> NodeElement {
    view._makeNode()
}
