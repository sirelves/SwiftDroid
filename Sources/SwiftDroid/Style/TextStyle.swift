/// Inherited text attributes; `nil` means "inherit" (platform default at the root).
public struct TextStyle: Equatable {
    public var font: Font?
    public var weight: Font.Weight?
    public var color: Color?

    public init(font: Font? = nil, weight: Font.Weight? = nil, color: Color? = nil) {
        self.font = font
        self.weight = weight
        self.color = color
    }

    /// `self` is the inner (closer to the text) style, so it wins.
    func inheriting(from outer: TextStyle) -> TextStyle {
        TextStyle(font: font ?? outer.font, weight: weight ?? outer.weight, color: color ?? outer.color)
    }

    public var resolvedFont: Font {
        let base = font ?? .body
        return weight.map(base.weight) ?? base
    }
}
