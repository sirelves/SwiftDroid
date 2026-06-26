/// Resolves a `NodeElement` tree into a `LayoutResult` tree using SwiftUI's
/// propose/respond model: a parent proposes a size to each child, the child
/// answers with the size it wants, then the parent places the children.
///
/// Text measurement is platform-specific (it needs font metrics), so the engine
/// takes a `TextMeasurer` rather than measuring text itself. The real renderers
/// inject platform metrics; tests inject a deterministic stub (see
/// `LayoutEngine.monospace`). This keeps the engine inside the platform-agnostic
/// core and makes layout a pure, snapshot-testable function.
///
/// Phase 3 scope and simplifications (documented deliberately):
/// - Only `Spacer` is flexible along a stack's main axis. Other views are
///   measured at their natural size. Frame/flexibility modifiers arrive later.
/// - `.infinity` proposals are treated as "no bounded space to distribute" — a
///   stack with an infinite main proposal sizes to its content. Full infinity
///   propagation is future work.
public struct LayoutEngine {
    /// Measures a string's size for a given proposal. `proposal` dimensions may
    /// be `nil` (natural size) or finite (constrained, e.g. for wrapping).
    public typealias TextMeasurer = (_ text: String, _ proposal: ProposedSize) -> Size

    public let measureText: TextMeasurer

    public init(measureText: @escaping TextMeasurer) {
        self.measureText = measureText
    }

    /// Lay out `node` given a `proposal`, returning the resolved tree.
    public func layout(_ node: NodeElement, proposal: ProposedSize) -> LayoutResult {
        switch node.kind {
        case .empty:
            return LayoutResult(kind: .empty, size: .zero)

        case .text(let content):
            return LayoutResult(kind: node.kind, size: measureText(content, proposal))

        case .spacer:
            // A spacer is only meaningful inside a stack, where the stack resolves
            // its flexible size. Laid out standalone it takes any finite proposed
            // space and otherwise collapses to zero.
            let w = finite(proposal.width) ?? 0
            let h = finite(proposal.height) ?? 0
            return LayoutResult(kind: node.kind, size: Size(width: w, height: h))

        case .group:
            // A bare group has no container semantics of its own. Treat it as a
            // zero-spacing vertical stack so it can still be laid out at the root;
            // inside real containers it is flattened before reaching here.
            return layoutStack(node, axis: .vertical, spacing: 0, align: .center, proposal: proposal)

        case .vstack(let spacing, let alignment):
            return layoutStack(node, axis: .vertical, spacing: spacing,
                               align: crossAlign(alignment), proposal: proposal)

        case .hstack(let spacing, let alignment):
            return layoutStack(node, axis: .horizontal, spacing: spacing,
                               align: crossAlign(alignment), proposal: proposal)

        case .zstack(let alignment):
            return layoutZStack(node, alignment: alignment, proposal: proposal)

        case .button:
            // A button sizes to its label (its single child), placed at origin.
            // Padding/min hit-target sizing is a later refinement.
            let labelNode = node.children.first ?? NodeElement(kind: .empty)
            let label = layout(labelNode, proposal: proposal)
            return LayoutResult(kind: node.kind, size: label.size, children: [label], action: node.action)
        }
    }

    // MARK: - Stack layout (VStack / HStack share this, parameterised by axis)

    private enum Axis { case vertical, horizontal }
    private enum CrossAlign { case start, center, end }

    /// The 6-step stack algorithm, generalised over the main axis:
    /// 1. collect children (groups flattened, empties dropped);
    /// 2. classify spacers as flexible, everything else as inflexible;
    /// 3. measure inflexible children at their natural main size;
    /// 4. compute remaining main space and split it among spacers;
    /// 5. resolve every child's size;
    /// 6. place children along the main axis, aligned on the cross axis.
    private func layoutStack(
        _ node: NodeElement, axis: Axis, spacing: Double,
        align: CrossAlign, proposal: ProposedSize
    ) -> LayoutResult {
        let children = flattenedChildren(of: node)
        let crossProp = crossOf(proposal, axis)

        // (3) Measure inflexible children; remember spacer slots and their minima.
        var resolved: [LayoutResult?] = Array(repeating: nil, count: children.count)
        var spacerSlots: [Int] = []
        var spacerMinima: [Int: Double] = [:]
        var inflexibleMain = 0.0

        for (i, child) in children.enumerated() {
            if case .spacer(let minLength) = child.kind {
                spacerSlots.append(i)
                spacerMinima[i] = minLength
            } else {
                let childProposal = makeProposal(main: nil, cross: crossProp, axis: axis)
                let r = layout(child, proposal: childProposal)
                resolved[i] = r
                inflexibleMain += mainOf(r.size, axis)
            }
        }

        let spacingTotal = children.isEmpty ? 0 : spacing * Double(children.count - 1)
        let spacerMinTotal = spacerSlots.reduce(0.0) { $0 + (spacerMinima[$1] ?? 0) }

        // (4) Distribute remaining main space among spacers (only if bounded).
        var remaining = 0.0
        if let mainAvail = finite(mainOf(proposal, axis)) {
            remaining = max(0, mainAvail - inflexibleMain - spacingTotal - spacerMinTotal)
        }
        let share = spacerSlots.isEmpty ? 0 : remaining / Double(spacerSlots.count)

        // (5) Resolve spacer sizes: min + fair share along main, zero on cross.
        for i in spacerSlots {
            let mainSize = (spacerMinima[i] ?? 0) + share
            resolved[i] = LayoutResult(
                kind: children[i].kind,
                size: makeSize(main: mainSize, cross: 0, axis: axis)
            )
        }

        let results = resolved.compactMap { $0 }
        let stackCross = results.map { crossOf($0.size, axis) }.max() ?? 0
        let stackMain = results.reduce(0.0) { $0 + mainOf($1.size, axis) } + spacingTotal

        // (6) Place along main; align on cross.
        var placed: [LayoutResult] = []
        placed.reserveCapacity(results.count)
        var cursor = 0.0
        for r in results {
            let crossPos = crossOffset(child: crossOf(r.size, axis), within: stackCross, align: align)
            let origin = makePoint(main: cursor, cross: crossPos, axis: axis)
            placed.append(LayoutResult(kind: r.kind, size: r.size, origin: origin, children: r.children, action: r.action))
            cursor += mainOf(r.size, axis) + spacing
        }

        return LayoutResult(
            kind: node.kind,
            size: makeSize(main: stackMain, cross: stackCross, axis: axis),
            children: placed
        )
    }

    // MARK: - ZStack layout

    private func layoutZStack(
        _ node: NodeElement, alignment: Alignment, proposal: ProposedSize
    ) -> LayoutResult {
        let children = flattenedChildren(of: node)
        let measured = children.map { layout($0, proposal: proposal) }

        let width = measured.map { $0.size.width }.max() ?? 0
        let height = measured.map { $0.size.height }.max() ?? 0

        let placed = measured.map { r -> LayoutResult in
            let x = offset(child: r.size.width, within: width, align: alignment.horizontal)
            let y = offset(child: r.size.height, within: height, align: alignment.vertical)
            return LayoutResult(kind: r.kind, size: r.size, origin: Point(x: x, y: y), children: r.children, action: r.action)
        }

        return LayoutResult(kind: node.kind, size: Size(width: width, height: height), children: placed)
    }

    // MARK: - Child collection

    /// Flatten a node's children for layout: transparent `group` nodes are
    /// spliced in, `empty` nodes contribute nothing (no size, no spacing slot),
    /// everything else passes through in order.
    private func flattenedChildren(of node: NodeElement) -> [NodeElement] {
        node.children.flatMap { child -> [NodeElement] in
            switch child.kind {
            case .group: return flattenedChildren(of: child)
            case .empty: return []
            default: return [child]
            }
        }
    }

    // MARK: - Axis helpers (map main/cross ↔ width/height for the active axis)

    private func mainOf(_ s: Size, _ axis: Axis) -> Double {
        axis == .vertical ? s.height : s.width
    }
    private func crossOf(_ s: Size, _ axis: Axis) -> Double {
        axis == .vertical ? s.width : s.height
    }
    private func mainOf(_ p: ProposedSize, _ axis: Axis) -> Double? {
        axis == .vertical ? p.height : p.width
    }
    private func crossOf(_ p: ProposedSize, _ axis: Axis) -> Double? {
        axis == .vertical ? p.width : p.height
    }
    private func makeSize(main: Double, cross: Double, axis: Axis) -> Size {
        axis == .vertical ? Size(width: cross, height: main) : Size(width: main, height: cross)
    }
    private func makeProposal(main: Double?, cross: Double?, axis: Axis) -> ProposedSize {
        axis == .vertical ? ProposedSize(width: cross, height: main) : ProposedSize(width: main, height: cross)
    }
    private func makePoint(main: Double, cross: Double, axis: Axis) -> Point {
        axis == .vertical ? Point(x: cross, y: main) : Point(x: main, y: cross)
    }

    // MARK: - Alignment helpers

    private func crossAlign(_ a: HorizontalAlignment) -> CrossAlign {
        switch a {
        case .leading: return .start
        case .center: return .center
        case .trailing: return .end
        }
    }
    private func crossAlign(_ a: VerticalAlignment) -> CrossAlign {
        switch a {
        case .top: return .start
        case .center: return .center
        case .bottom: return .end
        }
    }
    private func crossOffset(child: Double, within total: Double, align: CrossAlign) -> Double {
        switch align {
        case .start: return 0
        case .center: return (total - child) / 2
        case .end: return total - child
        }
    }
    private func offset(child: Double, within total: Double, align: HorizontalAlignment) -> Double {
        switch align {
        case .leading: return 0
        case .center: return (total - child) / 2
        case .trailing: return total - child
        }
    }
    private func offset(child: Double, within total: Double, align: VerticalAlignment) -> Double {
        switch align {
        case .top: return 0
        case .center: return (total - child) / 2
        case .bottom: return total - child
        }
    }

    // MARK: - Misc

    /// Returns the value if it is finite, else nil (treats `nil` and `.infinity`
    /// alike as "no concrete bound").
    private func finite(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return value
    }
}

extension LayoutEngine {
    /// A deterministic single-line text measurer for tests and previews: every
    /// character is `charWidth` wide and non-empty text is one `lineHeight`-tall
    /// line. No wrapping — proposals are ignored. Real platforms inject a
    /// measurer backed by actual font metrics instead.
    public static func monospace(charWidth: Double = 10, lineHeight: Double = 20) -> LayoutEngine {
        LayoutEngine { text, _ in
            Size(
                width: Double(text.count) * charWidth,
                height: text.isEmpty ? 0 : lineHeight
            )
        }
    }
}
