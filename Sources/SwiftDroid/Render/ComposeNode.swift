/// A renderer-agnostic description of a Jetpack Compose UI tree — the target the
/// Android adapter maps SwiftDroid views onto.
///
/// On Android, layout is Compose's job, so the adapter does **not** use the
/// propose/respond `LayoutEngine`; it maps the `NodeElement` tree onto native
/// Compose containers (`Column`/`Row`/`Box`) and lets Compose lay them out. That
/// mapping is the intellectual core of the Android renderer, so it lives here as
/// plain, `Equatable` data and is unit-tested off-device. The `#if canImport(Android)`
/// executor in `SwiftDroidAndroid` walks this tree and emits real `@Composable`
/// calls via swift-java.
///
/// Compose has no notion of SwiftDroid's transparent `group`/`empty` nodes, so the
/// mapper flattens them away — every `ComposeNode` corresponds to a real Compose
/// element.
public struct ComposeNode: Equatable {
    public enum Kind: Equatable {
        case text(String)
        /// A Compose `Button`; its tap handler is `ComposeNode.action`, its label
        /// is the (single) child.
        case button
        /// Maps from `VStack` → Compose `Column`.
        case column(spacing: Double, alignment: HorizontalAlignment)
        /// Maps from `HStack` → Compose `Row`.
        case row(spacing: Double, alignment: VerticalAlignment)
        /// Maps from `ZStack` → Compose `Box`.
        case box(alignment: Alignment)
        /// Maps from `Spacer` → Compose `Spacer`.
        case spacer(minLength: Double)
        /// `LazyColumn`; items are built on demand through `lazyItems`.
        case lazyColumn(spacing: Double, alignment: HorizontalAlignment)
        case divider
    }

    /// Compose `Modifier` chain, outermost first.
    public enum Modifier: Equatable {
        case padding(EdgeInsets)
        /// `Modifier.width/height`; `nil` leaves that axis unconstrained.
        case size(width: Double?, height: Double?)
        case widthIn(min: Double?, max: Double?)
        case heightIn(min: Double?, max: Double?)
        case fillMaxWidth
        case fillMaxHeight
        case verticalScroll
        case horizontalScroll
    }

    public let kind: Kind
    public let modifiers: [Modifier]
    public let children: [ComposeNode]
    /// Resolved style for `.text` (Compose `Text(fontSize, fontWeight, color)`).
    public let textStyle: TextStyle
    /// Item builders for `.lazyColumn` (Compose `items(count) { i -> … }`).
    public let lazyItems: [() -> ComposeNode?]
    /// Tap handler for `.button`; `nil` otherwise. Excluded from equality.
    public let action: (() -> Void)?

    public init(kind: Kind, modifiers: [Modifier] = [], children: [ComposeNode] = [],
                action: (() -> Void)? = nil, textStyle: TextStyle = TextStyle(),
                lazyItems: [() -> ComposeNode?] = []) {
        self.textStyle = textStyle
        self.lazyItems = lazyItems
        self.kind = kind
        self.modifiers = modifiers
        self.children = children
        self.action = action
    }

    func prepending(_ modifier: Modifier) -> ComposeNode {
        ComposeNode(kind: kind, modifiers: [modifier] + modifiers, children: children, action: action, textStyle: textStyle, lazyItems: lazyItems)
    }

    public static func == (lhs: ComposeNode, rhs: ComposeNode) -> Bool {
        lhs.kind == rhs.kind && lhs.modifiers == rhs.modifiers && lhs.children == rhs.children
            && lhs.textStyle == rhs.textStyle && lhs.lazyItems.count == rhs.lazyItems.count
    }
}
