/// Persists `@State` across body re-evaluations, keyed by structural identity
/// (SwiftUI's model): view type, tuple position, `if` branch, `ForEach` id.
/// Storage not reached during a render is dropped, like SwiftUI does when a
/// view leaves the hierarchy.
public final class StateStore {
    enum Component: Hashable {
        case type(ObjectIdentifier)
        case index(Int)
        case branch(Bool)
        case id(AnyHashable)
    }

    struct Key: Hashable {
        let path: [Component]
        let label: String
    }

    private var boxes: [Key: AnyObject] = [:]
    private var reached: Set<Key> = []

    public init() {}

    var count: Int { boxes.count }

    func box(for key: Key, default make: () -> AnyObject) -> AnyObject {
        reached.insert(key)
        if let existing = boxes[key] { return existing }
        let box = make()
        boxes[key] = box
        return box
    }

    /// Evaluates `body` with this store as the current one, then drops unreached state.
    func render<T>(_ body: () -> T) -> T {
        reached.removeAll(keepingCapacity: true)
        let outer = (ViewIdentity.store, ViewIdentity.path)
        ViewIdentity.store = self
        ViewIdentity.path = []
        defer {
            (ViewIdentity.store, ViewIdentity.path) = outer
            boxes = boxes.filter { reached.contains($0.key) }
        }
        return body()
    }
}

/// The identity path of the view being evaluated. Evaluation is single-threaded.
enum ViewIdentity {
    static var store: StateStore?
    static var path: [StateStore.Component] = []

    static func with<T>(_ component: StateStore.Component, _ body: () -> T) -> T {
        guard store != nil else { return body() }
        path.append(component)
        defer { path.removeLast() }
        return body()
    }

    /// Points every `@State` in `view` at its persisted storage.
    static func bindState<V>(of view: V) {
        guard let store else { return }
        for child in Mirror(reflecting: view).children {
            guard let label = child.label, let property = child.value as? _StateProperty else { continue }
            property._bind(to: store, key: StateStore.Key(path: path, label: label))
        }
    }
}

protocol _StateProperty {
    func _bind(to store: StateStore, key: StateStore.Key)
}
