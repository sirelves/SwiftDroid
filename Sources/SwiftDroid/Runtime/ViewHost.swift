/// Drives the full runtime loop for a root view: evaluate → layout → render, and
/// re-render automatically when the view's `@State` changes.
///
/// The host holds the root view once (so its `@State` heap boxes persist across
/// re-evaluations) and evaluates `_makeNode()` inside a `DependencyTracker`
/// observation. Every `@State` read during evaluation subscribes that observation;
/// a later write enqueues it on the `InvalidationQueue`, whose callback re-runs
/// `render()`. A tap routed through `tap(at:)` fires a button's action, which
/// mutates state and thus triggers exactly this loop — the same mechanism that
/// powers the CounterApp demo.
///
/// `commands` always holds the latest frame; platform adapters subscribe via
/// `onRender` to push it to Compose (Android) or SwiftUI (iOS).
public final class ViewHost<Root: View> {
    private let root: Root
    private let engine: LayoutEngine
    private let renderer = CommandRenderer()
    private var proposal: ProposedSize
    private let stateStore = StateStore()

    /// The most recently rendered frame.
    public private(set) var commands: [DrawCommand] = []

    /// Called after each render with the new command list. Set by the platform
    /// adapter to push the frame onto the screen.
    public var onRender: (([DrawCommand]) -> Void)?

    private var observation: AnyObservation!

    public init(_ root: Root, engine: LayoutEngine, proposal: ProposedSize) {
        self.root = root
        self.engine = engine
        self.proposal = proposal
        self.observation = AnyObservation { [weak self] in self?.render() }
        render()
    }

    /// Re-evaluate, lay out, and render the root view. Called once at init and
    /// again on every state invalidation.
    public func render() {
        var node = NodeElement(kind: .empty)
        DependencyTracker.shared.withObservation(observation) {
            node = stateStore.render { root._makeNode() }
        }
        let layout = engine.layout(node, proposal: proposal)
        commands = renderer.render(layout)
        onRender?(commands)
    }

    /// Update the available size and re-render (e.g. on a window/surface resize).
    public func resize(to proposal: ProposedSize) {
        self.proposal = proposal
        render()
    }

    /// Route a tap at `point` to the topmost button under it, firing its action.
    /// The resulting state change re-renders synchronously, so `commands` is
    /// up to date when this returns.
    public func tap(at point: Point) {
        commands.hitTest(point)?.action?()
    }

    /// Scroll the innermost viewport under `point` that scrolls on each axis;
    /// what it can't absorb goes to the enclosing one (nested scrolling).
    public func scroll(at point: Point, by delta: Point) {
        var remaining = delta
        InvalidationQueue.shared.transaction {
            for command in commands.reversed() where command.isHit(by: point) {
                guard case .scroll(let axes, let offset, let content) = command.kind else { continue }
                let maxX = axes.contains(.horizontal) ? max(0, content.width - command.frame.width) : 0
                let maxY = axes.contains(.vertical) ? max(0, content.height - command.frame.height) : 0
                let next = Point(x: min(max(0, offset.x + remaining.x), maxX),
                                 y: min(max(0, offset.y + remaining.y), maxY))
                remaining = Point(x: remaining.x - (next.x - offset.x), y: remaining.y - (next.y - offset.y))
                if next != offset { command.onScroll?(next) }
                if remaining == .zero { break }
            }
        }
    }
}
