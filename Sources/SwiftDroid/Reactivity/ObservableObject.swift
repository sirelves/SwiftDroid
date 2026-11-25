import Foundation

/// Marks a reference type as an observable source of truth.
///
/// Conforming types expose an `objectWillChange` subject that fires before
/// any `@Published` property changes. `@ObservedObject` subscribes to this
/// subject and triggers view invalidation when it fires.
public protocol ObservableObject: AnyObject {
    var objectWillChange: PassthroughSubject<Void> { get }
}

extension ObservableObject {
    /// Synthesised like Combine: the subject lives in the object's first
    /// `@Published` box. Without `@Published`, each access returns a new subject.
    public var objectWillChange: PassthroughSubject<Void> {
        var mirror: Mirror? = Mirror(reflecting: self)
        while let current = mirror {
            for child in current.children {
                if let box = child.value as? _PublishedBox {
                    return box._sharedObjectWillChange()
                }
            }
            mirror = current.superclassMirror
        }
        return PassthroughSubject<Void>()
    }
}

// MARK: - @Published

/// A property wrapper for properties on `ObservableObject` classes that should
/// trigger `objectWillChange` when mutated.
///
/// Uses the `_enclosingInstance` subscript so that the enclosing object's
/// `objectWillChange` publisher is called automatically — no Combine required.
@propertyWrapper
public final class Published<Value>: _PublishedBox {
    var _value: Value
    private var _objectWillChange: PassthroughSubject<Void>?

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

    func _sharedObjectWillChange() -> PassthroughSubject<Void> {
        _publishedLock.lock()
        defer { _publishedLock.unlock() }
        if let subject = _objectWillChange { return subject }
        let subject = PassthroughSubject<Void>()
        _objectWillChange = subject
        return subject
    }
}

protocol _PublishedBox: AnyObject {
    func _sharedObjectWillChange() -> PassthroughSubject<Void>
}

private let _publishedLock = NSLock()
