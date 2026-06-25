/// Conformance that lets an `Optional` be a view, so a bare `if` (no `else`)
/// inside a `@ViewBuilder` type-checks.
///
/// `ViewBuilder.buildOptional(_:)` returns `Wrapped?`. When present the wrapped
/// view renders normally; when `nil` it renders an `empty` node — nothing is
/// drawn, but the position in the tree is preserved so sibling state stays keyed
/// correctly.
extension Optional: View where Wrapped: View {
    public typealias Body = Never
    public var body: Never { fatalError("Optional has no body") }

    public func _makeNode() -> NodeElement {
        switch self {
        case .some(let wrapped): return wrapped._makeNode()
        case .none: return NodeElement(kind: .empty)
        }
    }
}
