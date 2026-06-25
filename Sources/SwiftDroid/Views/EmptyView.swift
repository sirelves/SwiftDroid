/// A view that draws nothing. Produced by an empty `@ViewBuilder` block and used
/// as the neutral element wherever a view is required but none should appear.
///
/// A primitive (leaf) view: `Body == Never`, and it overrides `_makeNode()` to
/// emit an `empty` node directly rather than recursing into a body.
public struct EmptyView: View {
    public init() {}

    public typealias Body = Never
    public var body: Never { fatalError("EmptyView has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .empty)
    }
}
