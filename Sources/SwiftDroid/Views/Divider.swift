public struct Divider: View {
    public init() {}

    public typealias Body = Never
    public var body: Never { fatalError("Divider has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .divider)
    }
}
