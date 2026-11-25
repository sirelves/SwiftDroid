/// Each element's view is identified by its id, so per-row `@State` follows the
/// element when the collection is reordered, inserted into or filtered.
public struct ForEach<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    public let data: Data
    public let content: (Data.Element) -> Content
    let id: (Data.Element) -> ID

    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = { $0[keyPath: id] }
        self.content = content
    }

    public typealias Body = Never
    public var body: Never { fatalError("ForEach has no body") }

    public func _makeNode() -> NodeElement {
        NodeElement(kind: .group, children: data.map { element in
            ViewIdentity.with(.id(AnyHashable(id(element)))) { content(element)._makeNode() }
        })
    }
}

extension ForEach where Data.Element: Identifiable, ID == Data.Element.ID {
    public init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.init(data, id: \.id, content: content)
    }
}

extension ForEach where Data == Range<Int>, ID == Int {
    public init(_ data: Range<Int>, @ViewBuilder content: @escaping (Int) -> Content) {
        self.init(data, id: \.self, content: content)
    }
}
