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
    private var retained: Set<IdentityPath> = []

    public init() {}

    var count: Int { boxes.count }

    /// Keeps state under `prefix` alive this render (rows of a lazy stack that
    /// exist but weren't built).
    func retain(prefix: IdentityPath) {
        retained.insert(prefix)
    }

    private func isRetained(_ path: [Component]) -> Bool {
        guard !retained.isEmpty else { return false }
        return (0...path.count).contains { retained.contains(IdentityPath(Array(path.prefix($0)))) }
    }

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
        retained.removeAll(keepingCapacity: true)
        let outer = (ViewIdentity.store, ViewIdentity.path)
        ViewIdentity.store = self
        ViewIdentity.path = []
        defer {
            (ViewIdentity.store, ViewIdentity.path) = outer
            boxes = boxes.filter { reached.contains($0.key) || isRetained($0.key.path) }
        }
        return body()
    }
}

/// The identity path of the view being evaluated. Evaluation is single-threaded.
enum ViewIdentity {
    static var store: StateStore?
    static var path: [StateStore.Component] = []

    /// Runs `body` with an identity path captured earlier (lazy rows).
    static func at<T>(_ captured: [StateStore.Component], _ body: () -> T) -> T {
        guard store != nil else { return body() }
        let outer = path
        path = captured
        defer { path = outer }
        return body()
    }

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

/// An identity path with its hash computed once — lazy stacks look rows up
/// several times per frame, and hashing `AnyHashable` ids dominated.
struct IdentityPath: Hashable {
    let components: [StateStore.Component]
    private let hash: Int

    init(_ components: [StateStore.Component]) {
        self.components = components
        var hasher = Hasher()
        hasher.combine(components)
        hash = hasher.finalize()
    }

    func hash(into hasher: inout Hasher) { hasher.combine(hash) }

    static func == (a: IdentityPath, b: IdentityPath) -> Bool {
        a.hash == b.hash && a.components == b.components
    }
}

protocol _StateProperty {
    func _bind(to store: StateStore, key: StateStore.Key)
}
