/// A property wrapper that holds a reference to an `ObservableObject` and
/// re-evaluates the enclosing view's body whenever `objectWillChange` fires.
///
/// Phase 1: stores the object and exposes a `Wrapper` for `$` projection.
/// The full invalidation hook-up (subscribing to `objectWillChange` and
/// pushing an observation onto `DependencyTracker`) is wired in Phase 2
/// when the view evaluation loop is in place.
@propertyWrapper
public struct ObservedObject<ObjectType: ObservableObject> {
    public var wrappedValue: ObjectType

    public init(wrappedValue: ObjectType) {
        self.wrappedValue = wrappedValue
    }

    /// Provides `$object` projected-value access for deriving `Binding`s from
    /// the object's properties.
    public struct Wrapper {
        let object: ObjectType
    }

    public var projectedValue: Wrapper {
        Wrapper(object: wrappedValue)
    }
}
