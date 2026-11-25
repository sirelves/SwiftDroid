/// A scrolling, lazily built list: rows are grouped into sections (loose rows
/// form one) and wrapped in the style's chrome — insets, minimum height,
/// separators, header and footer spacing (`ListMetrics`).
public struct List<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public typealias Body = Never
    public var body: Never { fatalError("List has no body") }

    public func _makeNode() -> NodeElement {
        let metrics = ListStyleContext.current ?? .insetGrouped
        return ViewIdentity.with(.type(ObjectIdentifier(Self.self))) {
            let rows = ListLayout(metrics: metrics).rows(for: content._lazyRows())
            return ScrollView { _ListRows(rows: rows) }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                ._makeNode()
        }
    }
}

extension List {
    public init<Data: RandomAccessCollection, ID: Hashable, RowContent: View>(
        _ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, ID, RowContent> {
        self.init { ForEach(data, id: id, content: rowContent) }
    }

    public init<Data: RandomAccessCollection, RowContent: View>(
        _ data: Data, @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Data.Element: Identifiable, Content == ForEach<Data, Data.Element.ID, RowContent> {
        self.init { ForEach(data, content: rowContent) }
    }

    public init<RowContent: View>(
        _ data: Range<Int>, @ViewBuilder rowContent: @escaping (Int) -> RowContent
    ) where Content == ForEach<Range<Int>, Int, RowContent> {
        self.init { ForEach(data, content: rowContent) }
    }
}

struct _ListRows: View {
    let rows: [LazyRow]
    typealias Body = Never
    var body: Never { fatalError("_ListRows has no body") }
    func _makeNode() -> NodeElement {
        NodeElement(kind: .lazyVStack(spacing: 0, alignment: .leading), lazyRows: rows)
    }
}

struct ListLayout {
    let metrics: ListMetrics

    private struct Group {
        var headers: [LazyRow] = []
        var rows: [LazyRow] = []
        var footers: [LazyRow] = []
    }

    func rows(for input: [LazyRow]) -> [LazyRow] {
        var out: [LazyRow] = []
        var previousHadFooter: Bool?
        for (i, group) in groups(input).enumerated() {
            let gap = i == 0 ? nil : previousHadFooter
            for (j, header) in group.headers.enumerated() {
                let top = j > 0 ? 0 : (gap == nil ? metrics.firstHeaderTop
                                      : gap! ? metrics.headerTopAfterFooter : metrics.headerTopAfterRows)
                let bottom = j == group.headers.count - 1 ? metrics.headerToRows : 0
                out.append(header.mapped { inset(leading($0), top: top, bottom: bottom) })
            }
            for (j, row) in group.rows.enumerated() {
                let top = j == 0 && group.headers.isEmpty ? metrics.rowsTopWithoutHeader : 0
                let separated = j < group.rows.count - 1
                out.append(row.mapped { cell($0, top: top, separator: separated) })
            }
            for footer in group.footers {
                out.append(footer.mapped { node in
                    metrics.footerIsCell ? cell(node, top: 0, separator: false)
                        : inset(leading(styled(node, font: .footnote)), top: metrics.footerTop, bottom: 0)
                })
            }
            previousHadFooter = !group.footers.isEmpty
        }
        return out
    }

    // Consecutive rows of the same Section form a group; loose rows form one too.
    private func groups(_ rows: [LazyRow]) -> [Group] {
        var result: [Group] = []
        var current: (IdentityPath?, Group)?
        for row in rows {
            if current == nil || current!.0 != row.section {
                if let c = current { result.append(c.1) }
                current = (row.section, Group())
            }
            switch row.role {
            case .header: current!.1.headers.append(row)
            case .row: current!.1.rows.append(row)
            case .footer: current!.1.footers.append(row)
            }
        }
        if let c = current { result.append(c.1) }
        return result
    }

    private func cell(_ node: NodeElement, top: Double, separator: Bool) -> NodeElement {
        var content = leading(node)
        content = NodeElement(kind: .padding(EdgeInsets(.vertical, metrics.rowVerticalPadding)), children: [content])
        content = NodeElement(kind: .flexFrame(FlexFrame(minHeight: metrics.rowMinHeight, alignment: .leading)), children: [content])
        content = NodeElement(kind: .padding(EdgeInsets(.horizontal, metrics.contentInset)), children: [content])
        if separator {
            let rule = NodeElement(kind: .padding(EdgeInsets(leading: metrics.separatorInsets.leading,
                                                             trailing: metrics.separatorInsets.trailing)),
                                   children: [NodeElement(kind: .divider)])
            content = NodeElement(kind: .zstack(alignment: .bottom), children: [content, rule])
        }
        return top == 0 ? content : NodeElement(kind: .padding(EdgeInsets(top: top)), children: [content])
    }

    private func inset(_ node: NodeElement, top: Double, bottom: Double) -> NodeElement {
        NodeElement(kind: .padding(EdgeInsets(top: top, leading: metrics.contentInset, bottom: bottom, trailing: metrics.contentInset)),
                    children: [node])
    }

    private func leading(_ node: NodeElement) -> NodeElement {
        NodeElement(kind: .flexFrame(FlexFrame(maxWidth: .infinity, alignment: .leading)), children: [node])
    }

    private func styled(_ node: NodeElement, font: Font) -> NodeElement {
        NodeElement(kind: .textStyle(TextStyle(font: font)), children: [node])
    }
}
