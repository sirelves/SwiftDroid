/// Sizes are iOS's default Dynamic Type values for each text style.
public struct Font: Equatable {
    public enum Weight: Equatable {
        case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
    }

    public var size: Double
    public var weight: Weight

    public static func system(size: Double, weight: Weight = .regular) -> Font {
        Font(size: size, weight: weight)
    }

    public static let largeTitle = Font(size: 34, weight: .regular)
    public static let title = Font(size: 28, weight: .regular)
    public static let title2 = Font(size: 22, weight: .regular)
    public static let title3 = Font(size: 20, weight: .regular)
    public static let headline = Font(size: 17, weight: .semibold)
    public static let body = Font(size: 17, weight: .regular)
    public static let callout = Font(size: 16, weight: .regular)
    public static let subheadline = Font(size: 15, weight: .regular)
    public static let footnote = Font(size: 13, weight: .regular)
    public static let caption = Font(size: 12, weight: .regular)
    public static let caption2 = Font(size: 11, weight: .regular)

    public func weight(_ weight: Weight) -> Font { Font(size: size, weight: weight) }
    public func bold() -> Font { weight(.bold) }
}
