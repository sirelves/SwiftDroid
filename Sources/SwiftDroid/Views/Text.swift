/// Displays a run of read-only text — the canonical primitive (leaf) view.
///
/// `Body == Never`: `Text` composes no other views, so it overrides `_makeNode()`
/// to emit a `text` node directly. Styling modifiers (font, color, weight) and
/// layout-aware sizing arrive with the layout engine in Phase 3; Phase 2 carries
/// only the string content.
public struct Text: View {
    public let content: String

    public init(_ content: String) {
        self.content = content
    }

    public typealias Body = Never
    public var body: Never { fatalError("Text has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .text(content))
    }
}
