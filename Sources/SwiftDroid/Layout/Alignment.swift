/// Cross-axis alignment for a `VStack` — controls horizontal placement of
/// children within the stack's width.
public enum HorizontalAlignment: Equatable {
    case leading, center, trailing
}

/// Cross-axis alignment for an `HStack` — controls vertical placement of
/// children within the stack's height.
public enum VerticalAlignment: Equatable {
    case top, center, bottom
}

/// Two-axis alignment for a `ZStack` — controls where overlapping children sit
/// within the stack's bounding box.
public struct Alignment: Equatable {
    public var horizontal: HorizontalAlignment
    public var vertical: VerticalAlignment

    public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public static let center = Alignment(horizontal: .center, vertical: .center)
    public static let topLeading = Alignment(horizontal: .leading, vertical: .top)
    public static let top = Alignment(horizontal: .center, vertical: .top)
    public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)
    public static let leading = Alignment(horizontal: .leading, vertical: .center)
    public static let trailing = Alignment(horizontal: .trailing, vertical: .center)
    public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)
    public static let bottom = Alignment(horizontal: .center, vertical: .bottom)
    public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)
}
