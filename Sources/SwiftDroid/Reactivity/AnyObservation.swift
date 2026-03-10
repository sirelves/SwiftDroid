/// A token representing a single subscriber that wants to be notified when state changes.
/// Identified by object identity so it can be stored in a Set without duplicates.
final class AnyObservation: Hashable {
    private let callback: () -> Void

    init(_ callback: @escaping () -> Void) {
        self.callback = callback
    }

    func invalidate() {
        callback()
    }

    static func == (lhs: AnyObservation, rhs: AnyObservation) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
