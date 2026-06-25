/// The view produced when a `@ViewBuilder` block contains more than one child.
///
/// `ViewBuilder.buildBlock(Text("a"), Text("b"))` returns `TupleView<(Text, Text)>`,
/// exactly as SwiftUI does — the concrete tuple type is preserved so authors get
/// the same `body` types they would on Apple platforms. The children live in a
/// value-type tuple with no heap allocation and full type information.
///
/// Iterating a heterogeneous tuple at runtime requires reflection: `_makeNode()`
/// mirrors the tuple, erases each element to `any View`, and recurses. (This is
/// the same technique Tokamak uses for the same problem.) Calling `_makeNode()`
/// through the `any View` existential dispatches dynamically because it is a
/// protocol requirement — see `View`.
public struct TupleView<T>: View {
    public let value: T

    public init(_ value: T) {
        self.value = value
    }

    public typealias Body = Never
    public var body: Never { fatalError("TupleView has no body") }

    public func _makeNode() -> NodeElement {
        let mirror = Mirror(reflecting: value)
        let children = mirror.children.compactMap { child -> NodeElement? in
            (child.value as? any View)?._makeNode()
        }
        return NodeElement(kind: .group, children: children)
    }
}
