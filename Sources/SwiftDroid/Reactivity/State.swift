/// A property wrapper that stores a value on the heap so that view structs
/// (value types) can mutate shared state without losing it on copy.
///
/// Reading `wrappedValue` registers the current observation context as a
/// subscriber; writing notifies all current subscribers via `InvalidationQueue`.
///
/// The `Equatable`-constrained initialiser (declared in the extension below)
/// adds a short-circuit: writes that do not change the value fire no notifications.
@propertyWrapper
public struct State<Value> {
    let storage: StateStorage<Value>

    public init(wrappedValue: Value) {
        self.storage = StateStorage(wrappedValue)
    }

    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set { storage.value = newValue }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.storage.value },
            set: { self.storage.value = $0 }
        )
    }
}

extension State where Value: Equatable {
    /// Initialiser that wires up the equality short-circuit: notifications are
    /// suppressed when the new value equals the current value.
    public init(wrappedValue: Value) {
        self.storage = StateStorage(wrappedValue, isEqual: ==)
    }
}
