/// Marks a reference type as an observable source of truth.
///
/// Conforming types expose an `objectWillChange` subject that fires before
/// any `@Published` property changes. `@ObservedObject` subscribes to this
/// subject and triggers view invalidation when it fires.
public protocol ObservableObject: AnyObject {
    var objectWillChange: PassthroughSubject<Void> { get }
}

// MARK: - @Published

/// A property wrapper for properties on `ObservableObject` classes that should
/// trigger `objectWillChange` when mutated.
///
/// Uses the `_enclosingInstance` subscript so that the enclosing object's
/// `objectWillChange` publisher is called automatically — no Combine required.
@propertyWrapper
public final class Published<Value> {
    var _value: Value

    public init(wrappedValue: Value) {
        self._value = wrappedValue
    }

    /// Called by the compiler when `@Published` is accessed on an `ObservableObject`.
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Published<Value>>
    ) -> Value {
        get {
            instance[keyPath: storageKeyPath]._value
        }
        set {
            instance.objectWillChange.send(())
            instance[keyPath: storageKeyPath]._value = newValue
        }
    }

    /// Fallback used when `@Published` is accessed outside an `ObservableObject`
    /// (e.g., direct unit test instantiation).
    public var wrappedValue: Value {
        get { _value }
        set { _value = newValue }
    }

    public var projectedValue: Published<Value> { self }
}
