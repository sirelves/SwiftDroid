public enum Axis: Equatable {
    case horizontal, vertical

    public struct Set: OptionSet, Equatable {
        public let rawValue: Int8
        public init(rawValue: Int8) { self.rawValue = rawValue }

        public static let horizontal = Set(rawValue: 1 << 0)
        public static let vertical = Set(rawValue: 1 << 1)
    }
}
