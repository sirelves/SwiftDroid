public struct LazyVStack<Content: View>: View {
    public let alignment: HorizontalAlignment
    public let spacing: Double
    public let content: Content

    public init(alignment: HorizontalAlignment = .center, spacing: Double = 8, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public typealias Body = Never
    public var body: Never { fatalError("LazyVStack has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .lazyVStack(spacing: spacing, alignment: alignment), lazyRows: content._lazyRows())
    }
}
