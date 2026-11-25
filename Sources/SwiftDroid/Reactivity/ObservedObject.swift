/// Holds an `ObservableObject`; reading it during body evaluation subscribes the
/// view to `objectWillChange`.
@propertyWrapper
public struct ObservedObject<ObjectType: ObservableObject> {
    private let object: ObjectType

    public init(wrappedValue: ObjectType) {
        self.object = wrappedValue
    }

    public var wrappedValue: ObjectType {
        if let obs = DependencyTracker.shared.current {
            object.objectWillChange.track(obs)
        }
        return object
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
        Wrapper(object: object)
    }
}
