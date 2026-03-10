import Foundation

/// Heap-allocated storage box for `@State` values.
///
/// Lives outside the view struct so state survives re-evaluation of `body`
/// (view structs are value types and would lose stored state on copy).
/// Identified by object identity; the attribute graph uses structural position
/// to associate the correct storage box with each `@State` declaration.
final class StateStorage<Value> {
    private var _value: Value
    private var observers: Set<AnyObservation> = []
    private let lock = NSLock()

    /// Optional equality check; when provided, writes that do not change the
    /// value are silently dropped (no observers notified).
    let isEqual: ((Value, Value) -> Bool)?

    init(_ value: Value, isEqual: ((Value, Value) -> Bool)? = nil) {
        self._value = value
        self.isEqual = isEqual
    }

    var value: Value {
        get {
            lock.lock()
            let v = _value
            lock.unlock()
            // Register the current observer *after* reading (outside lock to
            // avoid deadlock if the observation callback itself reads state).
            if let obs = DependencyTracker.shared.current {
                lock.lock()
                observers.insert(obs)
                lock.unlock()
            }
            return v
        }
        set {
            lock.lock()
            if let check = isEqual, check(_value, newValue) {
                lock.unlock()
                return
            }
            _value = newValue
            let snapshot = Array(observers)
            lock.unlock()
            // Observers are NOT removed — they persist until the next body
            // evaluation replaces them. This allows batching to work: multiple
            // writes within a transaction all reach the same observers.
            for obs in snapshot {
                InvalidationQueue.shared.enqueue(obs)
            }
        }
    }

    /// Manually add an observer without going through DependencyTracker.
    /// Used in tests and by the @ObservedObject bridge.
    func addObserver(_ obs: AnyObservation) {
        lock.lock()
        observers.insert(obs)
        lock.unlock()
    }

    /// Remove a previously registered observer.
    func removeObserver(_ obs: AnyObservation) {
        lock.lock()
        observers.remove(obs)
        lock.unlock()
    }
}
