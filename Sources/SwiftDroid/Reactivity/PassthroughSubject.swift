import Foundation

/// A minimal Combine-free publisher that broadcasts values to zero or more subscribers.
public final class PassthroughSubject<Output> {
    private var handlers: [UUID: (Output) -> Void] = [:]
    private let lock = NSLock()

    public init() {}

    /// Broadcast `value` to all current subscribers.
    public func send(_ value: Output) {
        lock.lock()
        let hs = Array(handlers.values)
        lock.unlock()
        hs.forEach { $0(value) }
    }

    /// Register a handler and return a cancellable that removes it on dealloc or `cancel()`.
    public func sink(_ handler: @escaping (Output) -> Void) -> AnyCancellable {
        let id = UUID()
        lock.lock()
        handlers[id] = handler
        lock.unlock()
        return AnyCancellable { [weak self] in
            self?.lock.lock()
            self?.handlers.removeValue(forKey: id)
            self?.lock.unlock()
        }
    }
}

/// Wraps a cancellation closure. Cancels automatically on dealloc.
public final class AnyCancellable: Hashable {
    private let _cancel: () -> Void

    init(_ cancel: @escaping () -> Void) {
        self._cancel = cancel
    }

    public func cancel() { _cancel() }

    deinit { _cancel() }

    public func store(in set: inout Set<AnyCancellable>) {
        set.insert(self)
    }

    public static func == (lhs: AnyCancellable, rhs: AnyCancellable) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
