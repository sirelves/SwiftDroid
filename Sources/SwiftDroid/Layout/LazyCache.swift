/// Survives across frames (owned by `ViewHost`): measured row heights, used to
/// estimate rows that aren't built, and each lazy stack's vertical position in
/// its scroll content, used to place the visible window.
public final class LazyCache {
    var heights: [IdentityPath: Double] = [:]
    var origins: [[Int]: Double] = [:]
    private var seen: Set<IdentityPath> = []

    public init() {}

    func touch(_ row: IdentityPath) { seen.insert(row) }

    /// Drops heights of rows that no longer exist.
    func endFrame() {
        heights = heights.filter { seen.contains($0.key) }
        seen.removeAll(keepingCapacity: true)
    }
}
