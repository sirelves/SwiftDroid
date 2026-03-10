// Platform-agnostic core. No platform-specific imports.

public let swiftDroidVersion = "0.0.1"

public func swiftDroidHello() -> String {
#if canImport(Android)
    return "SwiftDroid \(swiftDroidVersion) running on Android"
#elseif canImport(UIKit)
    return "SwiftDroid \(swiftDroidVersion) running on iOS"
#elseif os(macOS)
    return "SwiftDroid \(swiftDroidVersion) running on macOS"
#else
    return "SwiftDroid \(swiftDroidVersion) running on Linux"
#endif
}
