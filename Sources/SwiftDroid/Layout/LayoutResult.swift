/// The output of a layout pass: a tree mirroring the laid-out `NodeElement`
/// tree, with every node resolved to a concrete `size` and an `origin`.
///
/// `origin` is expressed relative to the node's immediate parent (SwiftUI-style),
/// so absolute positions are obtained by accumulating origins down the tree. The
/// root's `origin` is `.zero`. `kind` carries the source node's kind so a
/// renderer can map each laid-out node back to a drawing command.
///
/// `LayoutResult` is `Equatable` and free of closures, which makes layout an
/// easily snapshot-tested pure function of (node tree, proposal, text measurer).
public struct LayoutResult: Equatable {
    public let kind: NodeElement.Kind
    public let size: Size
    public let origin: Point
    public let children: [LayoutResult]

    public init(
        kind: NodeElement.Kind,
        size: Size,
        origin: Point = .zero,
        children: [LayoutResult] = []
    ) {
        self.kind = kind
        self.size = size
        self.origin = origin
        self.children = children
    }
}
