// Measured from SwiftUI: a rigid 10pt child inside .frame(min/ideal/max), per proposal.
struct FlexFrameCase {
    let name: String
    let min: Double?, ideal: Double?, max: Double?
    let expected: [Double]  // one per flexFrameProposals entry
}

let flexFrameProposals: [Double?] = [nil, 0, 5, 10, 25, 50, 200, .infinity]

let flexFrameCases: [FlexFrameCase] = [
    .init(name: "min30", min: 30, ideal: nil, max: nil, expected: [30, 30, 30, 30, 30, 30, 30, 30]),
    .init(name: "max30", min: nil, ideal: nil, max: 30, expected: [10, 10, 10, 10, 25, 30, 30, 30]),
    .init(name: "maxInf", min: nil, ideal: nil, max: .infinity, expected: [10, 10, 10, 10, 25, 50, 200, .infinity]),
    .init(name: "min0 maxInf", min: 0, ideal: nil, max: .infinity, expected: [10, 0, 5, 10, 25, 50, 200, .infinity]),
    .init(name: "min30 max60", min: 30, ideal: nil, max: 60, expected: [30, 30, 30, 30, 30, 50, 60, 60]),
    .init(name: "ideal40", min: nil, ideal: 40, max: nil, expected: [40, 10, 10, 10, 10, 10, 10, 10]),
    .init(name: "ideal40 maxInf", min: nil, ideal: 40, max: .infinity, expected: [40, 10, 10, 10, 25, 50, 200, .infinity]),
    .init(name: "min20 ideal40 max60", min: 20, ideal: 40, max: 60, expected: [40, 20, 20, 20, 25, 50, 60, 60]),
]
