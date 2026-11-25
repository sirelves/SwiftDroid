public struct Section<Parent: View, Content: View, Footer: View>: View {
    public let header: Parent
    public let content: Content
    public let footer: Footer

    public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Parent, @ViewBuilder footer: () -> Footer) {
        self.header = header()
        self.content = content()
        self.footer = footer()
    }

    public typealias Body = Never
    public var body: Never { fatalError("Section has no body") }

    // Outside a List a section is just its parts, stacked by the parent.
    public func _makeNode() -> NodeElement {
        NodeElement(kind: .group, children: [
            ViewIdentity.with(.index(0)) { header._makeNode() },
            ViewIdentity.with(.index(1)) { content._makeNode() },
            ViewIdentity.with(.index(2)) { footer._makeNode() },
        ])
    }

    public func _lazyRows() -> [LazyRow] {
        let section = IdentityPath(ViewIdentity.path + [.type(ObjectIdentifier(Self.self))])
        func tagged(_ index: Int, _ view: some View, _ role: LazyRow.Role) -> [LazyRow] {
            ViewIdentity.with(.index(index)) { view._lazyRows() }.map { row in
                var row = row
                row.role = role
                row.section = section
                return row
            }
        }
        return tagged(0, header, .header) + tagged(1, content, .row) + tagged(2, footer, .footer)
    }
}

extension Section where Footer == EmptyView {
    public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Parent) {
        self.init(content: content, header: header, footer: { EmptyView() })
    }
}

extension Section where Parent == EmptyView {
    public init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.init(content: content, header: { EmptyView() }, footer: footer)
    }
}

extension Section where Parent == EmptyView, Footer == EmptyView {
    public init(@ViewBuilder content: () -> Content) {
        self.init(content: content, header: { EmptyView() }, footer: { EmptyView() })
    }
}

extension Section where Parent == Text, Footer == EmptyView {
    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(content: content, header: { Text(title) }, footer: { EmptyView() })
    }
}
