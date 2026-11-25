public struct EdgeInsets: Equatable {
    public var top: Double
    public var leading: Double
    public var bottom: Double
    public var trailing: Double

    public init(top: Double = 0, leading: Double = 0, bottom: Double = 0, trailing: Double = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public init(_ edges: Edge.Set, _ length: Double) {
        self.init(top: edges.contains(.top) ? length : 0,
                  leading: edges.contains(.leading) ? length : 0,
                  bottom: edges.contains(.bottom) ? length : 0,
                  trailing: edges.contains(.trailing) ? length : 0)
    }

    var horizontal: Double { leading + trailing }
    var vertical: Double { top + bottom }
}

public enum Edge: Equatable {
    case top, leading, bottom, trailing

    public struct Set: OptionSet, Equatable {
        public let rawValue: Int8
        public init(rawValue: Int8) { self.rawValue = rawValue }

        public static let top = Set(rawValue: 1 << 0)
        public static let leading = Set(rawValue: 1 << 1)
        public static let bottom = Set(rawValue: 1 << 2)
        public static let trailing = Set(rawValue: 1 << 3)
        public static let horizontal: Set = [.leading, .trailing]
        public static let vertical: Set = [.top, .bottom]
        public static let all: Set = [.top, .leading, .bottom, .trailing]
    }
}
