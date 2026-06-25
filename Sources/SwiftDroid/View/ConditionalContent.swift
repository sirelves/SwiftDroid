/// The view produced by an `if`/`else` inside a `@ViewBuilder` block.
///
/// `ViewBuilder.buildEither(first:)` / `buildEither(second:)` both return
/// `_ConditionalContent<TrueContent, FalseContent>`, so both branches share one
/// static type at the call site while the runtime enum selects the live branch.
/// Each branch keeps its concrete type — there is no type erasure — which is what
/// lets per-branch `@State` keep stable identity across toggles.
///
/// The leading underscore matches SwiftUI: this type is produced by the builder,
/// never written by hand.
public struct _ConditionalContent<TrueContent: View, FalseContent: View>: View {
    enum Storage {
        case first(TrueContent)
        case second(FalseContent)
    }

    let storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    public typealias Body = Never
    public var body: Never { fatalError("_ConditionalContent has no body") }

    public func _makeNode() -> NodeElement {
        switch storage {
        case .first(let content): return content._makeNode()
        case .second(let content): return content._makeNode()
        }
    }
}
