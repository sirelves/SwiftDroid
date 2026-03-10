import Foundation

/// Tracks which observation context is currently evaluating so that
/// state reads can automatically register as dependencies.
///
/// Usage:
///   DependencyTracker.shared.withObservation(obs) {
///       _ = someState.value   // registers obs as a subscriber of someState
///   }
final class DependencyTracker {
    static let shared = DependencyTracker()

    private var stack: [AnyObservation] = []
    private let lock = NSLock()

    private init() {}

    /// The innermost currently-evaluating observation, if any.
    var current: AnyObservation? {
        lock.lock()
        defer { lock.unlock() }
        return stack.last
    }

    /// Evaluate `body` while `observation` is on the tracking stack.
    /// Any state reads inside `body` will register `observation` as a subscriber.
    func withObservation(_ observation: AnyObservation, body: () -> Void) {
        lock.lock()
        stack.append(observation)
        lock.unlock()

        body()

        lock.lock()
        _ = stack.popLast()
        lock.unlock()
    }
}
