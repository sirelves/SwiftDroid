/// A row of a lazy container: its identity path, and how to build it there.
public struct LazyRow {
    let path: [StateStore.Component]
    let key: IdentityPath
    let build: () -> NodeElement

    init(path: [StateStore.Component], build: @escaping () -> NodeElement) {
        self.path = path
        self.key = IdentityPath(path)
        self.build = build
    }

    func makeNode() -> NodeElement {
        ViewIdentity.at(path, build)
    }
}

extension TupleView {
    public func _lazyRows() -> [LazyRow] {
        Mirror(reflecting: value).children.enumerated().flatMap { index, child -> [LazyRow] in
            guard let view = child.value as? any View else { return [] }
            return ViewIdentity.with(.index(index)) { view._lazyRows() }
        }
    }
}

extension ForEach {
    public func _lazyRows() -> [LazyRow] {
        data.flatMap { element in
            ViewIdentity.with(.id(AnyHashable(id(element)))) { content(element)._lazyRows() }
        }
    }
}

extension Group {
    public func _lazyRows() -> [LazyRow] { content._lazyRows() }
}

extension _ConditionalContent {
    public func _lazyRows() -> [LazyRow] {
        switch storage {
        case .first(let content): return ViewIdentity.with(.branch(true)) { content._lazyRows() }
        case .second(let content): return ViewIdentity.with(.branch(false)) { content._lazyRows() }
        }
    }
}

extension Optional where Wrapped: View {
    public func _lazyRows() -> [LazyRow] {
        switch self {
        case .some(let wrapped): return ViewIdentity.with(.branch(true)) { wrapped._lazyRows() }
        case .none: return []
        }
    }
}

extension EmptyView {
    public func _lazyRows() -> [LazyRow] { [] }
}
