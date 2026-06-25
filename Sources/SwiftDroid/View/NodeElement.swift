/// The platform-agnostic intermediate representation of a rendered view tree.
///
/// A `View` graph is generic and exists only at the type level — it cannot be
/// iterated or handed to a renderer directly. `_makeNode()` collapses that graph
/// into a tree of `NodeElement` values, which *is* concrete, inspectable, and
/// `Equatable`. The Android renderer (Phase 4) walks this tree to emit Compose
/// nodes; the layout engine (Phase 3) annotates it with sizes.
///
/// `NodeElement` is deliberately small in Phase 2: it carries only the node kinds
/// the View protocol machinery can produce. Container kinds (VStack/HStack/ZStack)
/// and interactive kinds (Button) arrive with their phases.
public struct NodeElement: Equatable {
    /// The concrete kind of a single node in the rendered tree.
    public enum Kind: Equatable {
        /// Renders nothing but occupies a stable position in the tree.
        case empty
        /// A run of text. The associated value is the string content.
        case text(String)
        /// A transparent grouping of children (TupleView, Group).
        /// Carries no layout semantics of its own — the layout engine flattens it.
        case group
        /// A flexible gap that expands along its container's main axis.
        /// `minLength` is the smallest size it will ever report.
        case spacer(minLength: Double)
        /// Vertical stack. `spacing` separates adjacent children; `alignment`
        /// positions them horizontally within the stack's width.
        case vstack(spacing: Double, alignment: HorizontalAlignment)
        /// Horizontal stack. `spacing` separates adjacent children; `alignment`
        /// positions them vertically within the stack's height.
        case hstack(spacing: Double, alignment: VerticalAlignment)
        /// Depth stack — children overlap, positioned by `alignment` within the
        /// stack's bounding box.
        case zstack(alignment: Alignment)
    }

    public let kind: Kind
    public let children: [NodeElement]

    public init(kind: Kind, children: [NodeElement] = []) {
        self.kind = kind
        self.children = children
    }
}
