/// Transparent container; lifts the ten-child `@ViewBuilder` limit.
public struct Group<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public typealias Body = Never
    public var body: Never { fatalError("Group has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .group, children: [content._makeNode()])
    }
}
