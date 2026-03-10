/// A property wrapper that holds a reference to a value owned elsewhere.
///
/// `Binding` carries `get` and `set` closures rather than storage; reads go
/// through to the source (typically a `@State`) and writes propagate back.
/// Because the closures capture the source, dependency tracking and observer
/// notification happen automatically through the source's `StateStorage`.
@propertyWrapper
public struct Binding<Value> {
    let _get: () -> Value
    let _set: (Value) -> Void

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self._get = get
        self._set = set
    }

    public var wrappedValue: Value {
        get { _get() }
        nonmutating set { _set(newValue) }
    }

    /// `$binding` returns the binding itself so it can be forwarded to child views.
    public var projectedValue: Binding<Value> { self }

    /// A binding whose setter is a no-op. Useful for previews and tests.
    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}
