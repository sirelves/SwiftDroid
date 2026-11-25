public struct _PaddingView<Content: View>: View {
    let content: Content
    let insets: EdgeInsets

    public typealias Body = Never
    public var body: Never { fatalError("_PaddingView has no body") }

    public func _makeNode() -> NodeElement {
        let child = content._makeNode()
        // Matches SwiftUI: a padded EmptyView still takes no space.
        if child.kind == .empty { return child }
        return NodeElement(kind: .padding(insets), children: [child])
    }
}

public struct _FrameView<Content: View>: View {
    let content: Content
    let width: Double?
    let height: Double?
    let alignment: Alignment

    public typealias Body = Never
    public var body: Never { fatalError("_FrameView has no body") }

    public func _makeNode() -> NodeElement {
        let child = content._makeNode()
        if child.kind == .empty { return child }
        return NodeElement(kind: .frame(width: width, height: height, alignment: alignment), children: [child])
    }
}

extension View {
    public func frame(width: Double? = nil, height: Double? = nil, alignment: Alignment = .center) -> _FrameView<Self> {
        _FrameView(content: self, width: width, height: height, alignment: alignment)
    }

    /// SwiftUI's platform default is 16 on iOS; the core uses the same.
    public func padding(_ edges: Edge.Set = .all, _ length: Double? = nil) -> _PaddingView<Self> {
        _PaddingView(content: self, insets: EdgeInsets(edges, length ?? 16))
    }

    public func padding(_ length: Double) -> _PaddingView<Self> {
        padding(.all, length)
    }

    public func padding(_ insets: EdgeInsets) -> _PaddingView<Self> {
        _PaddingView(content: self, insets: insets)
    }
}
