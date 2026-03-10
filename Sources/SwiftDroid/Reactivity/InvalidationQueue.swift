import Foundation

/// Batches invalidation callbacks so that N state changes inside a single
/// transaction produce exactly one notification pass rather than N.
///
/// Outside a transaction every enqueued observation fires immediately.
/// Inside a transaction observations accumulate in a Set (deduplicating
/// repeated enqueues of the same observer) and fire once when the outermost
/// transaction exits.
final class InvalidationQueue {
    static let shared = InvalidationQueue()

    private var pending: Set<AnyObservation> = []
    private var depth = 0
    private let lock = NSLock()

    private init() {}

    /// Execute `body` inside a transaction. Defers all invalidation callbacks
    /// until the outermost transaction completes.
    func transaction(_ body: () -> Void) {
        lock.lock()
        depth += 1
        lock.unlock()

        body()

        lock.lock()
        depth -= 1
        let shouldFlush = (depth == 0)
        let toFlush = shouldFlush ? pending : []
        if shouldFlush { pending.removeAll() }
        lock.unlock()

        for obs in toFlush { obs.invalidate() }
    }

    /// Enqueue an observation for invalidation.
    /// Fires immediately outside a transaction; deferred and deduplicated inside.
    func enqueue(_ observation: AnyObservation) {
        lock.lock()
        if depth > 0 {
            pending.insert(observation)
            lock.unlock()
        } else {
            lock.unlock()
            observation.invalidate()
        }
    }
}
