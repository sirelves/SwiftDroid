// Measured from SwiftUI with 1000 rows of 50x20, spacing 0.
let lazyWidthCases: [(proposedWidth: Double?, width: Double)] = [(nil, 50), (300, 300), (10, 10)]
let lazyTotalHeight: Double = 20_000
// Rows whose body runs inside a 300x200 ScrollView at offset 0.
let lazyBuiltRows: Set<Int> = Set(0..<10)
