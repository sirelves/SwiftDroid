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
/// Not modelled yet: `layoutPriority`, system-adaptive default spacing.
public struct LayoutEngine {
    /// Measures a string's size for a given proposal. `proposal` dimensions may
    /// be `nil` (natural size) or finite (constrained, e.g. for wrapping).
    public typealias TextMeasurer = (_ text: String, _ proposal: ProposedSize) -> Size
    public typealias StyledTextMeasurer = (_ text: String, _ font: Font, _ proposal: ProposedSize) -> Size

    public let measureText: StyledTextMeasurer

    public init(measureText: @escaping StyledTextMeasurer) {
        self.measureText = measureText
    }

    /// Font-agnostic measurer (tests, previews).
    public init(measureText: @escaping TextMeasurer) {
        self.measureText = { text, _, proposal in measureText(text, proposal) }
    }

    /// Lay out `node` given a `proposal`, returning the resolved tree.
    public func layout(_ node: NodeElement, proposal: ProposedSize) -> LayoutResult {
        layout(node, proposal: proposal, at: [], style: TextStyle(), in: LayoutPass())
    }

    // Stacks measure each child several times (at 0, ∞ and its share), so a
    // subtree is memoised per (position in the tree, proposal) for one pass.
    private func layout(_ node: NodeElement, proposal: ProposedSize, at path: [Int], style: TextStyle, in pass: LayoutPass) -> LayoutResult {
        let key = LayoutPass.Key(path: path, width: proposal.width, height: proposal.height)
        if let hit = pass.cache[key] { return hit }
        let result = compute(node, proposal: proposal, at: path, style: style, in: pass)
        pass.cache[key] = result
        return result
    }

    private func compute(_ node: NodeElement, proposal: ProposedSize, at path: [Int], style: TextStyle, in pass: LayoutPass) -> LayoutResult {
        switch node.kind {
        case .empty:
            return LayoutResult(kind: .empty, size: .zero)

        case .text(let content):
            return LayoutResult(kind: node.kind, size: measureText(content, style.resolvedFont, proposal), textStyle: style)

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
            return layoutStack(node, axis: .vertical, spacing: 0, align: .center, proposal: proposal, at: path, style: style, in: pass)

        case .vstack(let spacing, let alignment):
            return layoutStack(node, axis: .vertical, spacing: spacing,
                               align: crossAlign(alignment), proposal: proposal, at: path, style: style, in: pass)

        case .hstack(let spacing, let alignment):
            return layoutStack(node, axis: .horizontal, spacing: spacing,
                               align: crossAlign(alignment), proposal: proposal, at: path, style: style, in: pass)

        case .zstack(let alignment):
            return layoutZStack(node, alignment: alignment, proposal: proposal, at: path, style: style, in: pass)

        case .button:
            // A button sizes to its label (its single child), placed at origin.
            // Padding/min hit-target sizing is a later refinement.
            let labelNode = node.children.first ?? NodeElement(kind: .empty)
            let label = layout(labelNode, proposal: proposal, at: path + [0], style: style, in: pass)
            return LayoutResult(kind: node.kind, size: label.size, children: [label], action: node.action)

        case .padding(let insets):
            return layoutPadding(node, insets: insets, proposal: proposal, at: path, style: style, in: pass)

        case .frame(let width, let height, let alignment):
            return layoutFrame(node, width: width, height: height, alignment: alignment, proposal: proposal, at: path, style: style, in: pass)

        case .textStyle(let inner):
            return layout(node.children.first ?? NodeElement(kind: .empty), proposal: proposal,
                          at: path + [0], style: inner.inheriting(from: style), in: pass)

        case .flexFrame(let f):
            return layoutFlexFrame(node, f, proposal: proposal, at: path, style: style, in: pass)
        }
    }

    private func layoutFlexFrame(_ node: NodeElement, _ f: FlexFrame, proposal: ProposedSize, at path: [Int], style: TextStyle, in pass: LayoutPass) -> LayoutResult {
        let childProposal = ProposedSize(
            width: FlexFrame.childProposal(proposal.width, min: f.minWidth, ideal: f.idealWidth, max: f.maxWidth),
            height: FlexFrame.childProposal(proposal.height, min: f.minHeight, ideal: f.idealHeight, max: f.maxHeight))
        let child = layout(node.children.first ?? NodeElement(kind: .empty), proposal: childProposal, at: path + [0], style: style, in: pass)
        let size = Size(
            width: FlexFrame.resolve(proposal.width, child: child.size.width, min: f.minWidth, ideal: f.idealWidth, max: f.maxWidth),
            height: FlexFrame.resolve(proposal.height, child: child.size.height, min: f.minHeight, ideal: f.idealHeight, max: f.maxHeight))
        let placed = child.moved(to: Point(x: offset(child: child.size.width, within: size.width, align: f.alignment.horizontal),
                                                y: offset(child: child.size.height, within: size.height, align: f.alignment.vertical)))
        return LayoutResult(kind: node.kind, size: size, children: [placed])
    }

    private func layoutFrame(_ node: NodeElement, width: Double?, height: Double?,
                             alignment: Alignment, proposal: ProposedSize, at path: [Int], style: TextStyle, in pass: LayoutPass) -> LayoutResult {
        let child = layout(node.children.first ?? NodeElement(kind: .empty),
                           proposal: ProposedSize(width: width ?? proposal.width, height: height ?? proposal.height),
                           at: path + [0], style: style, in: pass)
        let size = Size(width: width ?? child.size.width, height: height ?? child.size.height)
        let placed = child.moved(to: Point(x: offset(child: child.size.width, within: size.width, align: alignment.horizontal),
                                                y: offset(child: child.size.height, within: size.height, align: alignment.vertical)))
        return LayoutResult(kind: node.kind, size: size, children: [placed])
    }

    private func layoutPadding(_ node: NodeElement, insets: EdgeInsets, proposal: ProposedSize, at path: [Int], style: TextStyle, in pass: LayoutPass) -> LayoutResult {
        let inner = ProposedSize(width: proposal.width.map { max(0, $0 - insets.horizontal) },
                                 height: proposal.height.map { max(0, $0 - insets.vertical) })
        let child = layout(node.children.first ?? NodeElement(kind: .empty), proposal: inner, at: path + [0], style: style, in: pass)
        let placed = child.moved(to: Point(x: insets.leading, y: insets.top))
        return LayoutResult(kind: node.kind,
                            size: Size(width: child.size.width + insets.horizontal,
                                       height: child.size.height + insets.vertical),
                            children: [placed])
    }

    // MARK: - Stack layout (VStack / HStack share this, parameterised by axis)

    private enum Axis { case vertical, horizontal }
    private enum CrossAlign { case start, center, end }

    /// SwiftUI's stack algorithm (verified by probing SwiftUI): children are
    /// visited from least to most flexible (size at ∞ minus size at 0, ties in
    /// source order); each is offered an equal share of what is left and keeps
    /// what it takes. An unspecified main proposal asks every child for its ideal.
    private func layoutStack(
        _ node: NodeElement, axis: Axis, spacing: Double,
        align: CrossAlign, proposal: ProposedSize, at path: [Int], style: TextStyle, in pass: LayoutPass
    ) -> LayoutResult {
        let children = flattenedChildren(of: node)
        let crossProp = crossOf(proposal, axis)
        let spacingTotal = children.isEmpty ? 0 : spacing * Double(children.count - 1)

        func measure(_ i: Int, main: Double?) -> LayoutResult {
            let child = children[i]
            if case .spacer(let minLength) = child.kind {
                let length = main.map { max(minLength, $0) } ?? minLength
                return LayoutResult(kind: child.kind, size: makeSize(main: length, cross: 0, axis: axis))
            }
            return layout(child, proposal: makeProposal(main: main, cross: crossProp, axis: axis), at: path + [i], style: style, in: pass)
        }

        var resolved = [LayoutResult?](repeating: nil, count: children.count)
        if let available = mainOf(proposal, axis) {
            let flexibility: [Double] = children.indices.map { i in
                let f = mainOf(measure(i, main: .infinity).size, axis) - mainOf(measure(i, main: 0).size, axis)
                return f.isNaN ? .infinity : f
            }
            let order: [Int] = children.indices.sorted { a, b in
                flexibility[a] != flexibility[b] ? flexibility[a] < flexibility[b] : a < b
            }
            var remaining = max(0, available - spacingTotal)
            for (n, i) in order.enumerated() {
                let r = measure(i, main: remaining / Double(order.count - n))
                resolved[i] = r
                remaining = max(0, remaining - mainOf(r.size, axis))
            }
        } else {
            for i in children.indices { resolved[i] = measure(i, main: nil) }
        }

        let results = resolved.compactMap { $0 }
        let stackCross = results.map { crossOf($0.size, axis) }.max() ?? 0
        let stackMain = results.reduce(0.0) { $0 + mainOf($1.size, axis) } + spacingTotal

        var placed: [LayoutResult] = []
        placed.reserveCapacity(results.count)
        var cursor = 0.0
        for r in results {
            let crossPos = crossOffset(child: crossOf(r.size, axis), within: stackCross, align: align)
            let origin = makePoint(main: cursor, cross: crossPos, axis: axis)
            placed.append(r.moved(to: origin))
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
        _ node: NodeElement, alignment: Alignment, proposal: ProposedSize, at path: [Int], style: TextStyle, in pass: LayoutPass
    ) -> LayoutResult {
        let children = flattenedChildren(of: node)
        let measured = children.enumerated().map { layout($1, proposal: proposal, at: path + [$0], style: style, in: pass) }

        let width = measured.map { $0.size.width }.max() ?? 0
        let height = measured.map { $0.size.height }.max() ?? 0

        let placed = measured.map { r -> LayoutResult in
            let x = offset(child: r.size.width, within: width, align: alignment.horizontal)
            let y = offset(child: r.size.height, within: height, align: alignment.vertical)
            return r.moved(to: Point(x: x, y: y))
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

final class LayoutPass {
    struct Key: Hashable {
        let path: [Int]
        let width: Double?
        let height: Double?
    }
    var cache: [Key: LayoutResult] = [:]
}

extension LayoutEngine {
    /// A deterministic single-line text measurer for tests and previews: every
    /// character is `charWidth` wide and non-empty text is one `lineHeight`-tall
    /// line, scaled by font size relative to `.body`. No wrapping — proposals are ignored. Real platforms inject a
    /// measurer backed by actual font metrics instead.
    public static func monospace(charWidth: Double = 10, lineHeight: Double = 20) -> LayoutEngine {
        LayoutEngine { text, font, _ in
            let scale = font.size / Font.body.size
            return Size(width: Double(text.count) * charWidth * scale,
                        height: text.isEmpty ? 0 : lineHeight * scale)
        }
    }
}
