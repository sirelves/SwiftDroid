/// Maps a SwiftDroid `NodeElement` tree onto a `ComposeNode` tree (the Compose
/// vocabulary). This is the platform-agnostic, fully testable half of the Android
/// renderer; the `SwiftDroidAndroid` executor turns the result into real
/// `@Composable` calls via swift-java.
///
/// Transparent nodes are resolved during mapping: `group` is spliced into its
/// parent and `empty` is dropped, so every emitted `ComposeNode` is a concrete
/// Compose element. Container layout is delegated to Compose, so no sizes are
/// computed here.
public struct ComposeRenderer {
    public init() {}

    /// Map a view's node tree to its Compose representation. A tree that maps to
    /// nothing (e.g. `EmptyView`) yields an empty `Column`.
    public func render(_ node: NodeElement) -> ComposeNode {
        map(node) ?? ComposeNode(kind: .column(spacing: 0, alignment: .center))
    }

    private func map(_ node: NodeElement) -> ComposeNode? {
        switch node.kind {
        case .empty:
            return nil

        case .text(let content):
            return ComposeNode(kind: .text(content))

        case .spacer(let minLength):
            return ComposeNode(kind: .spacer(minLength: minLength))

        case .button:
            return ComposeNode(kind: .button, children: mapChildren(node.children), action: node.action)

        case .group:
            // A bare group has no Compose equivalent; lay it out as a zero-spacing
            // Column, mirroring the layout engine's treatment of a root group.
            return ComposeNode(kind: .column(spacing: 0, alignment: .center), children: mapChildren(node.children))

        case .vstack(let spacing, let alignment):
            return ComposeNode(kind: .column(spacing: spacing, alignment: alignment), children: mapChildren(node.children))

        case .hstack(let spacing, let alignment):
            return ComposeNode(kind: .row(spacing: spacing, alignment: alignment), children: mapChildren(node.children))

        case .zstack(let alignment):
            return ComposeNode(kind: .box(alignment: alignment), children: mapChildren(node.children))
        }
    }

    /// Flatten transparent `group` children in and drop `empty` ones, mapping the
    /// rest in order — so a `TupleView`'s `group` node disappears into its parent
    /// container, exactly as Compose expects.
    private func mapChildren(_ nodes: [NodeElement]) -> [ComposeNode] {
        nodes.flatMap { child -> [ComposeNode] in
            switch child.kind {
            case .empty: return []
            case .group: return mapChildren(child.children)
            default: return map(child).map { [$0] } ?? []
            }
        }
    }
}
