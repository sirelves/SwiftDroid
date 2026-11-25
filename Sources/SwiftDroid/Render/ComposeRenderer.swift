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
        map(node, TextStyle()) ?? ComposeNode(kind: .column(spacing: 0, alignment: .center))
    }

    private func map(_ node: NodeElement, _ style: TextStyle) -> ComposeNode? {
        switch node.kind {
        case .empty:
            return nil

        case .text(let content):
            return ComposeNode(kind: .text(content), textStyle: style)

        case .spacer(let minLength):
            return ComposeNode(kind: .spacer(minLength: minLength))

        case .button:
            return ComposeNode(kind: .button, children: mapChildren(node.children, style), action: node.action)

        case .group:
            // A bare group has no Compose equivalent; lay it out as a zero-spacing
            // Column, mirroring the layout engine's treatment of a root group.
            return ComposeNode(kind: .column(spacing: 0, alignment: .center), children: mapChildren(node.children, style))

        case .vstack(let spacing, let alignment):
            return ComposeNode(kind: .column(spacing: spacing, alignment: alignment), children: mapChildren(node.children, style))

        case .hstack(let spacing, let alignment):
            return ComposeNode(kind: .row(spacing: spacing, alignment: alignment), children: mapChildren(node.children, style))

        case .zstack(let alignment):
            return ComposeNode(kind: .box(alignment: alignment), children: mapChildren(node.children, style))

        case .padding(let insets):
            return node.children.first.flatMap({ map($0, style) })?.prepending(.padding(insets))

        case .frame(let width, let height, let alignment):
            guard let child = node.children.first.flatMap({ map($0, style) }) else { return nil }
            return ComposeNode(kind: .box(alignment: alignment), modifiers: [.size(width: width, height: height)], children: [child])

        case .textStyle(let inner):
            return node.children.first.flatMap { map($0, inner.inheriting(from: style)) }

        case .flexFrame(let f):
            guard let child = node.children.first.flatMap({ map($0, style) }) else { return nil }
            return ComposeNode(kind: .box(alignment: f.alignment), modifiers: flexModifiers(f), children: [child])
        }
    }

    // Compose has no "ideal" size; ideal only affects SwiftUI's unspecified proposals.
    private func flexModifiers(_ f: FlexFrame) -> [ComposeNode.Modifier] {
        var mods: [ComposeNode.Modifier] = []
        if f.maxWidth == .infinity { mods.append(.fillMaxWidth) }
        let maxW = f.maxWidth == .infinity ? nil : f.maxWidth
        if f.minWidth != nil || maxW != nil { mods.append(.widthIn(min: f.minWidth, max: maxW)) }
        if f.maxHeight == .infinity { mods.append(.fillMaxHeight) }
        let maxH = f.maxHeight == .infinity ? nil : f.maxHeight
        if f.minHeight != nil || maxH != nil { mods.append(.heightIn(min: f.minHeight, max: maxH)) }
        return mods
    }

    /// Flatten transparent `group` children in and drop `empty` ones, mapping the
    /// rest in order — so a `TupleView`'s `group` node disappears into its parent
    /// container, exactly as Compose expects.
    private func mapChildren(_ nodes: [NodeElement], _ style: TextStyle) -> [ComposeNode] {
        nodes.flatMap { child -> [ComposeNode] in
            switch child.kind {
            case .empty: return []
            case .group: return mapChildren(child.children, style)
            default: return map(child, style).map { [$0] } ?? []
            }
        }
    }
}
