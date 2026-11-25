public struct FlexFrame: Equatable {
    public var minWidth, idealWidth, maxWidth: Double?
    public var minHeight, idealHeight, maxHeight: Double?
    public var alignment: Alignment

    public init(minWidth: Double? = nil, idealWidth: Double? = nil, maxWidth: Double? = nil,
                minHeight: Double? = nil, idealHeight: Double? = nil, maxHeight: Double? = nil,
                alignment: Alignment = .center) {
        self.minWidth = minWidth; self.idealWidth = idealWidth; self.maxWidth = maxWidth
        self.minHeight = minHeight; self.idealHeight = idealHeight; self.maxHeight = maxHeight
        self.alignment = alignment
    }
}

// Per-axis rules, derived from measuring SwiftUI's flexible frame (see FlexFrameCases).
extension FlexFrame {
    static func childProposal(_ p: Double?, min: Double?, ideal: Double?, max: Double?) -> Double? {
        guard var p else { return ideal }
        if let min { p = Swift.max(min, p) }
        if let max { p = Swift.min(max, p) }
        return p
    }

    static func resolve(_ p: Double?, child c: Double, min: Double?, ideal: Double?, max: Double?) -> Double {
        if p == nil, var r = ideal {
            if let min { r = Swift.max(min, r) }
            if let max { r = Swift.min(max, r) }
            return r
        }
        let p = p ?? c
        var r = c
        if let min { r = Swift.max(min, Swift.min(r, p)) }
        if let max { r = Swift.min(max, Swift.max(r, p)) }
        return r
    }
}
