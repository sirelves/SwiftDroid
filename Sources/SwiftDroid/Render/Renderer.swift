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
        walk(layout, parentOrigin: .zero, into: &out)
        return out
    }

    private func walk(_ node: LayoutResult, parentOrigin: Point, into out: inout [DrawCommand]) {
        let frame = Rect(
            origin: Point(x: parentOrigin.x + node.origin.x, y: parentOrigin.y + node.origin.y),
            size: node.size
        )

        switch node.kind {
        case .text(let content):
            out.append(DrawCommand(kind: .text(content), frame: frame))

        case .button:
            out.append(DrawCommand(kind: .button, frame: frame, action: node.action))
            for child in node.children { walk(child, parentOrigin: frame.origin, into: &out) }

        case .empty, .spacer:
            break // nothing to draw

        case .group, .vstack, .hstack, .zstack:
            for child in node.children { walk(child, parentOrigin: frame.origin, into: &out) }
        }
    }
}
