/// A horizontal container that stacks its children leading to trailing.
///
/// The mirror of `VStack`: the main axis is horizontal, so `alignment` controls
/// vertical placement of children within the stack's height.
public struct HStack<Content: View>: View {
    public let alignment: VerticalAlignment
    public let spacing: Double
    public let content: Content

    public init(
        alignment: VerticalAlignment = .center,
        spacing: Double = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public typealias Body = Never
    public var body: Never { fatalError("HStack has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .hstack(spacing: spacing, alignment: alignment),
                    children: [content._makeNode()])
    }
}
