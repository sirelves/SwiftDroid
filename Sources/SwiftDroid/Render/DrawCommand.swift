/// A single absolute-positioned drawing instruction — the flattened, renderer-
/// agnostic output of walking a `LayoutResult` tree.
///
/// Containers (group/stack/zstack) and empties/spacers draw nothing themselves;
/// they only offset their children. So a `DrawCommand` list contains only the
/// visible/interactive leaves (`text`, `button`) with absolute `frame`s — exactly
/// what a flat renderer or a tap hit-test needs. The Android renderer maps the
/// same `LayoutResult` to nested Compose nodes instead; this flat form is the
/// reference the mapping is validated against.
public struct DrawCommand: Equatable {
    public enum Kind: Equatable {
        case text(String)
        /// The button's tap surface; its label is emitted as a following `text`.
        case button
        /// A scroll viewport: `frame` is the viewport, `content` the scrollable size.
        case scroll(axes: Axis.Set, offset: Point, content: Size)
        /// A filled hairline (`Divider`, list separators).
        case rule
    }

    public let kind: Kind
    public let frame: Rect
    /// Present for `.button`; the tap handler to invoke when `frame` is hit.
    public let action: (() -> Void)?
    public let style: TextStyle
    /// Visible area when inside a scroll viewport; `nil` = unclipped.
    public let clip: Rect?
    public let onScroll: ((Point) -> Void)?

    public init(kind: Kind, frame: Rect, action: (() -> Void)? = nil, style: TextStyle = TextStyle(),
                clip: Rect? = nil, onScroll: ((Point) -> Void)? = nil) {
        self.kind = kind
        self.frame = frame
        self.action = action
        self.style = style
        self.clip = clip
        self.onScroll = onScroll
    }

    func isHit(by point: Point) -> Bool {
        frame.contains(point) && (clip?.contains(point) ?? true)
    }

    /// Structural equality — ignores `action` (closures have no equality).
    public static func == (lhs: DrawCommand, rhs: DrawCommand) -> Bool {
        lhs.kind == rhs.kind && lhs.frame == rhs.frame && lhs.style == rhs.style && lhs.clip == rhs.clip
    }
}

extension Array where Element == DrawCommand {
    /// The topmost interactive command whose frame contains `point` — used to
    /// route a tap to the right button. Searches back-to-front (last drawn wins).
    public func hitTest(_ point: Point) -> DrawCommand? {
        last { $0.kind == .button && $0.isHit(by: point) }
    }
}
