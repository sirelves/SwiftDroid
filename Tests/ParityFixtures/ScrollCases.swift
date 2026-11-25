// Measured from SwiftUI: size of a ScrollView around rigid 100x300 content.
struct ScrollCase {
    let width: Double?, height: Double?
    let vertical: (Double, Double)
    let horizontal: (Double, Double)
}

let scrollCases: [ScrollCase] = [
    .init(width: nil, height: nil, vertical: (100, 300), horizontal: (100, 300)),
    .init(width: 200, height: 200, vertical: (100, 200), horizontal: (200, 300)),
    .init(width: 200, height: nil, vertical: (100, 300), horizontal: (200, 300)),
    .init(width: nil, height: 200, vertical: (100, 200), horizontal: (100, 300)),
    .init(width: 50, height: 500, vertical: (100, 500), horizontal: (50, 300)),
    .init(width: .infinity, height: .infinity, vertical: (100, .infinity), horizontal: (.infinity, 300)),
    .init(width: 0, height: 0, vertical: (100, 0), horizontal: (0, 300)),
]
