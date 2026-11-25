// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftDroid",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SwiftDroid", targets: ["SwiftDroid"]),
        .library(name: "SwiftDroidAndroid", targets: ["SwiftDroidAndroid"]),
        .library(name: "SwiftDroidiOS", targets: ["SwiftDroidiOS"]),
    ],
    targets: [
        // Platform-agnostic core — compiles on macOS, Linux, and Android
        .target(
            name: "SwiftDroid",
            dependencies: []
        ),
        // Android renderer — all Android code guarded by #if canImport(Android)
        .target(
            name: "SwiftDroidAndroid",
            dependencies: ["SwiftDroid"]
        ),
        // Apple adapter: typealiases onto SwiftUI, no dependency on the core
        .target(
            name: "SwiftDroidiOS",
            dependencies: []
        ),
        // Tests run on macOS + Linux CI; depend only on SwiftDroid core
        .testTarget(
            name: "SwiftDroidTests",
            dependencies: ["SwiftDroid"]
        ),
        // Parity: Tests/ParityFixtures symlinked into both, one per backend
        .testTarget(
            name: "SwiftDroidParityTests",
            dependencies: ["SwiftDroid"]
        ),
        .testTarget(
            name: "SwiftUIParityTests",
            dependencies: ["SwiftDroidiOS"],
            swiftSettings: [.define("PARITY_SWIFTUI")]
        ),
        // Headless CounterApp demo — `swift run CounterAppDemo`
        .executableTarget(
            name: "CounterAppDemo",
            dependencies: ["SwiftDroid"],
            path: "Examples/CounterApp"
        ),
    ]
)
