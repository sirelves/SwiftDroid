// Measured from SwiftUI HStacks: final main-axis size of each child.
enum StackChild {
    case rigid10
    case flex(min: Double?, max: Double?)
    case spacer(min: Double?)
}

struct StackCase {
    let name: String
    let length: Double
    let spacing: Double
    let children: [StackChild]
    let expected: [Double]
}

let stackCases: [StackCase] = [
    .init(name: "r10 maxInf maxInf", length: 200, spacing: 0, children: [.rigid10, .flex(min: nil, max: .infinity), .flex(min: nil, max: .infinity)], expected: [10, 95, 95]),
    .init(name: "max30 maxInf", length: 200, spacing: 0, children: [.flex(min: nil, max: 30), .flex(min: nil, max: .infinity)], expected: [30, 170]),
    .init(name: "maxInf max30", length: 200, spacing: 0, children: [.flex(min: nil, max: .infinity), .flex(min: nil, max: 30)], expected: [170, 30]),
    .init(name: "min50maxInf maxInf", length: 200, spacing: 0, children: [.flex(min: 50, max: .infinity), .flex(min: nil, max: .infinity)], expected: [100, 100]),
    .init(name: "min150maxInf maxInf", length: 200, spacing: 0, children: [.flex(min: 150, max: .infinity), .flex(min: nil, max: .infinity)], expected: [150, 50]),
    .init(name: "min0max60 x2 maxInf", length: 200, spacing: 0, children: [.flex(min: 0, max: 60), .flex(min: 0, max: 60), .flex(min: 0, max: .infinity)], expected: [60, 60, 80]),
    .init(name: "min0max60 x2 maxInf narrow", length: 90, spacing: 0, children: [.flex(min: 0, max: 60), .flex(min: 0, max: 60), .flex(min: 0, max: .infinity)], expected: [30, 30, 30]),
    .init(name: "min20maxInf x2 overflow", length: 30, spacing: 0, children: [.flex(min: 20, max: .infinity), .flex(min: 20, max: .infinity)], expected: [20, 20]),
    .init(name: "r10 spacer maxInf", length: 200, spacing: 0, children: [.rigid10, .spacer(min: nil), .flex(min: nil, max: .infinity)], expected: [10, 95, 95]),
    .init(name: "r10 spacer0 maxInf", length: 200, spacing: 0, children: [.rigid10, .spacer(min: 0), .flex(min: nil, max: .infinity)], expected: [10, 95, 95]),
    .init(name: "r10 spacer r10", length: 200, spacing: 0, children: [.rigid10, .spacer(min: nil), .rigid10], expected: [10, 180, 10]),
    .init(name: "r10 spacer r10 squeezed", length: 20, spacing: 0, children: [.rigid10, .spacer(min: nil), .rigid10], expected: [10, 8, 10]),
    .init(name: "r10 spacer0 r10 squeezed", length: 20, spacing: 0, children: [.rigid10, .spacer(min: 0), .rigid10], expected: [10, 0, 10]),
    .init(name: "r10 spacer spacer0 r10", length: 200, spacing: 0, children: [.rigid10, .spacer(min: nil), .spacer(min: 0), .rigid10], expected: [10, 90, 90, 10]),
    .init(name: "r10 r10 too narrow", length: 15, spacing: 0, children: [.rigid10, .rigid10], expected: [10, 10]),
    .init(name: "max30 max30 maxInf spacing5", length: 100, spacing: 5, children: [.flex(min: nil, max: 30), .flex(min: nil, max: 30), .flex(min: nil, max: .infinity)], expected: [30, 30, 30]),
]
