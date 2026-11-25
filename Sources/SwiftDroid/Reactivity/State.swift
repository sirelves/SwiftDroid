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
    // A reference, so the host can repoint every copy of this view at the
    // persisted storage before its body runs (see StateStore).
    let location: StateLocation<Value>

    var storage: StateStorage<Value> { location.storage }

    public init(wrappedValue: Value) {
        self.location = StateLocation(StateStorage(wrappedValue))
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
        self.location = StateLocation(StateStorage(wrappedValue, isEqual: ==))
    }
}

final class StateLocation<Value> {
    var storage: StateStorage<Value>
    init(_ storage: StateStorage<Value>) { self.storage = storage }
}

extension State: _StateProperty {
    func _bind(to store: StateStore, key: StateStore.Key) {
        let initial = location.storage
        location.storage = store.box(for: key) { initial } as! StateStorage<Value>
    }
}
