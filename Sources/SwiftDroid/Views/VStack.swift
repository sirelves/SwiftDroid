/// A vertical container that stacks its children top to bottom.
///
/// Holds its content as a generic `Content` so the `@ViewBuilder` closure keeps
/// full type information (SwiftUI parity). `_makeNode()` wraps the content's node
/// under a `vstack` node carrying the spacing and alignment the layout engine
/// needs; the content's own grouping (a `TupleView` → `group` node) is flattened
/// by the engine.
public struct VStack<Content: View>: View {
    public let alignment: HorizontalAlignment
    public let spacing: Double
    public let content: Content

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: Double = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public typealias Body = Never
    public var body: Never { fatalError("VStack has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .vstack(spacing: spacing, alignment: alignment),
                    children: [content._makeNode()])
    }
}
