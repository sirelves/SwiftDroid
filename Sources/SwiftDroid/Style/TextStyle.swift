/// Inherited text attributes; `nil` means "inherit" (platform default at the root).
/// `bold` and `weight` are separate, as in SwiftUI.
public struct TextStyle: Equatable {
    public var font: Font?
    public var weight: Font.Weight?
    public var bold: Bool?
    public var color: Color?

    public init(font: Font? = nil, weight: Font.Weight? = nil, bold: Bool? = nil, color: Color? = nil) {
        self.font = font
        self.weight = weight
        self.bold = bold
        self.color = color
    }

    /// `self` is the inner (closer to the text) style, so it wins.
    func inheriting(from outer: TextStyle) -> TextStyle {
        TextStyle(font: font ?? outer.font, weight: weight ?? outer.weight,
                  bold: bold ?? outer.bold, color: color ?? outer.color)
    }

    /// Measured in SwiftUI: an explicit weight beats bold, and bold beats the font's own weight.
    public var resolvedFont: Font {
        let base = font ?? .body
        if let weight { return base.weight(weight) }
        return bold == true ? base.bold() : base
    }
}
