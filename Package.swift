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
        // iOS adapter — all iOS code guarded by #if canImport(UIKit)
        .target(
            name: "SwiftDroidiOS",
            dependencies: ["SwiftDroid"]
        ),
        // Tests run on macOS + Linux CI; depend only on SwiftDroid core
        .testTarget(
            name: "SwiftDroidTests",
            dependencies: ["SwiftDroid"]
        ),
    ]
)
