public struct ScrollView<Content: View>: View {
    public let axes: Axis.Set
    public let showsIndicators: Bool
    public let content: Content
    @State var offset = Point.zero

    public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    public typealias Body = Never
    public var body: Never { fatalError("ScrollView has no body") }

    // A primitive with its own state: the scroll position survives re-renders
    // through the same identity binding composite views get.
    public func _makeNode() -> NodeElement {
        ViewIdentity.with(.type(ObjectIdentifier(Self.self))) {
            ViewIdentity.bindState(of: self)
            let offset = $offset
            return NodeElement(kind: .scroll(axes: axes, offset: self.offset),
                               children: [content._makeNode()],
                               onScroll: { offset.wrappedValue = $0 })
        }
    }
}
