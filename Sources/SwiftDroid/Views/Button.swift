/// A tappable control with a view label and an action run on tap.
///
/// Mirrors SwiftUI: `Button(action:label:)` takes any `Label` view, and the
/// `Button("text", action:)` convenience builds a `Text` label. The label's node
/// becomes the button node's single child; the action is carried on the
/// `NodeElement` so the renderer can wire the platform tap gesture to it.
public struct Button<Label: View>: View {
    public let action: () -> Void
    public let label: Label

    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    public typealias Body = Never
    public var body: Never { fatalError("Button has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .button, children: [label._makeNode()], action: action)
    }
}

extension Button where Label == Text {
    /// Convenience for the common text-titled button: `Button("Increment") { … }`.
    public init(_ title: String, action: @escaping () -> Void) {
        self.action = action
        self.label = Text(title)
    }
}
