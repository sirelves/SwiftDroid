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

    /// `$model.property` → `Binding`.
    @dynamicMemberLookup
    public struct Wrapper {
        let object: ObjectType

        public subscript<Subject>(
            dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>
        ) -> Binding<Subject> {
            Binding(get: { object[keyPath: keyPath] },
                    set: { object[keyPath: keyPath] = $0 })
        }
    }

    public var projectedValue: Wrapper {
        Wrapper(object: wrappedValue)
    }
}
