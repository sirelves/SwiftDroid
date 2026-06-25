/// A depth container that overlays its children, back to front.
///
/// All children are proposed the ZStack's own size; the stack sizes to the
/// bounding box of its children and positions each one by `alignment`.
public struct ZStack<Content: View>: View {
    public let alignment: Alignment
    public let content: Content

    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }

    public typealias Body = Never
    public var body: Never { fatalError("ZStack has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .zstack(alignment: alignment),
                    children: [content._makeNode()])
    }
}
