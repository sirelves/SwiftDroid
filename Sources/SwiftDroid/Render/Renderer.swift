/// Turns a laid-out tree into some platform output.
///
/// The platform adapters conform with their own `Output` — the Android renderer
/// emits Jetpack Compose nodes (`#if canImport(Android)`), iOS maps to SwiftUI.
/// `CommandRenderer` below is the platform-agnostic reference implementation used
/// in tests and on the host loop.
public protocol Renderer {
    associatedtype Output
    func render(_ layout: LayoutResult) -> Output
}

/// Reference renderer: flattens a `LayoutResult` into absolute-framed
/// `DrawCommand`s. Container nodes contribute only their origin offset; leaves
/// (`text`, `button`) become commands. A button emits its tap surface followed by
/// its label's commands, so taps hit the button and the label still draws on top.
public struct CommandRenderer: Renderer {
    public init() {}

    public func render(_ layout: LayoutResult) -> [DrawCommand] {
        var out: [DrawCommand] = []
        walk(layout, parentOrigin: .zero, clip: nil, into: &out)
        return out
    }

    // Leaves outside the current clip are culled; containers are always walked
    // because children may overflow their parent's frame.
    private func walk(_ node: LayoutResult, parentOrigin: Point, clip: Rect?, into out: inout [DrawCommand]) {
        let frame = Rect(
            origin: Point(x: parentOrigin.x + node.origin.x, y: parentOrigin.y + node.origin.y),
            size: node.size
        )
        let visible = clip.map { frame.intersection($0) != nil } ?? true

        switch node.kind {
        case .text(let content):
            if visible { out.append(DrawCommand(kind: .text(content), frame: frame, style: node.textStyle, clip: clip)) }

        case .button:
            if visible { out.append(DrawCommand(kind: .button, frame: frame, action: node.action, clip: clip)) }
            for child in node.children { walk(child, parentOrigin: frame.origin, clip: clip, into: &out) }

        case .scroll(let axes, let offset):
            guard visible else { return }
            let content = node.children.first?.size ?? .zero
            out.append(DrawCommand(kind: .scroll(axes: axes, offset: offset, content: content), frame: frame,
                                   clip: clip, onScroll: node.onScroll))
            let viewport = clip.flatMap { frame.intersection($0) } ?? frame
            for child in node.children { walk(child, parentOrigin: frame.origin, clip: viewport, into: &out) }

        case .empty, .spacer:
            break

        case .group, .vstack, .hstack, .zstack, .padding, .frame, .flexFrame, .textStyle:
            for child in node.children { walk(child, parentOrigin: frame.origin, clip: clip, into: &out) }
        }
    }
}
