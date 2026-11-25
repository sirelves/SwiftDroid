/// Named colors use iOS's light-mode system values.
public struct Color: Equatable {
    public var red, green, blue, opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red; self.green = green; self.blue = blue; self.opacity = opacity
    }

    public init(white: Double, opacity: Double = 1) {
        self.init(red: white, green: white, blue: white, opacity: opacity)
    }

    public static let black = Color(white: 0)
    public static let white = Color(white: 1)
    public static let clear = Color(white: 0, opacity: 0)
    public static let primary = Color.black
    public static let secondary = Color(red: 0.235, green: 0.235, blue: 0.263, opacity: 0.6)
    public static let gray = Color(red: 0.557, green: 0.557, blue: 0.576)
    public static let red = Color(red: 1, green: 0.231, blue: 0.188)
    public static let orange = Color(red: 1, green: 0.584, blue: 0)
    public static let yellow = Color(red: 1, green: 0.8, blue: 0)
    public static let green = Color(red: 0.204, green: 0.78, blue: 0.349)
    public static let blue = Color(red: 0, green: 0.478, blue: 1)
    public static let purple = Color(red: 0.686, green: 0.322, blue: 0.871)
    public static let pink = Color(red: 1, green: 0.176, blue: 0.333)

    public func opacity(_ opacity: Double) -> Color {
        Color(red: red, green: green, blue: blue, opacity: self.opacity * opacity)
    }
}
