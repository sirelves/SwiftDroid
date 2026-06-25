/// A flexible gap that expands to fill available space along its container's
/// main axis (vertical in a `VStack`, horizontal in an `HStack`).
///
/// `minLength` is the smallest size the spacer will report; when a stack has
/// space to distribute, each spacer receives `minLength` plus an equal share of
/// the remainder. Outside a stack, or on the cross axis, a spacer contributes
/// nothing. A primitive (leaf) view.
public struct Spacer: View {
    public let minLength: Double

    public init(minLength: Double = 0) {
        self.minLength = minLength
    }

    public typealias Body = Never
    public var body: Never { fatalError("Spacer has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .spacer(minLength: minLength))
    }
}
