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

public struct _FlexFrameView<Content: View>: View {
    let content: Content
    let frame: FlexFrame

    public typealias Body = Never
    public var body: Never { fatalError("_FlexFrameView has no body") }

    public func _makeNode() -> NodeElement {
        let child = content._makeNode()
        if child.kind == .empty { return child }
        return NodeElement(kind: .flexFrame(frame), children: [child])
    }
}

public struct _TextStyleView<Content: View>: View {
    let content: Content
    let style: TextStyle

    public typealias Body = Never
    public var body: Never { fatalError("_TextStyleView has no body") }

    // Distributed over a group's children so the stack still flattens them.
    public func _makeNode() -> NodeElement {
        wrap(content._makeNode())
    }

    private func wrap(_ node: NodeElement) -> NodeElement {
        switch node.kind {
        case .empty: return node
        case .group: return NodeElement(kind: .group, children: node.children.map(wrap))
        default: return NodeElement(kind: .textStyle(style), children: [node])
        }
    }
}

extension View {
    public func font(_ font: Font?) -> _TextStyleView<Self> {
        _TextStyleView(content: self, style: TextStyle(font: font))
    }

    public func fontWeight(_ weight: Font.Weight?) -> _TextStyleView<Self> {
        _TextStyleView(content: self, style: TextStyle(weight: weight))
    }

    public func bold(_ isActive: Bool = true) -> _TextStyleView<Self> {
        fontWeight(isActive ? .bold : nil)
    }

    public func foregroundColor(_ color: Color?) -> _TextStyleView<Self> {
        _TextStyleView(content: self, style: TextStyle(color: color))
    }

    public func frame(minWidth: Double? = nil, idealWidth: Double? = nil, maxWidth: Double? = nil,
                      minHeight: Double? = nil, idealHeight: Double? = nil, maxHeight: Double? = nil,
                      alignment: Alignment = .center) -> _FlexFrameView<Self> {
        _FlexFrameView(content: self, frame: FlexFrame(
            minWidth: minWidth, idealWidth: idealWidth, maxWidth: maxWidth,
            minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight, alignment: alignment))
    }

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
