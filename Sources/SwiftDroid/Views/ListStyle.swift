/// Spacing rules of a list style, measured on the iOS 26.3 simulator with
/// `scripts/measure-ios-list.sh`. Re-measure when iOS changes them.
public struct ListMetrics: Equatable {
    public var contentInset: Double
    public var separatorInsets: (leading: Double, trailing: Double)
    public var rowMinHeight: Double
    public var rowVerticalPadding: Double
    public var firstHeaderTop: Double
    public var headerTopAfterRows: Double
    public var headerTopAfterFooter: Double
    public var rowsTopWithoutHeader: Double
    public var headerToRows: Double
    public var footerTop: Double
    /// Plain lists draw the footer as a row-sized cell in body font.
    public var footerIsCell: Bool

    public static func == (a: ListMetrics, b: ListMetrics) -> Bool {
        a.contentInset == b.contentInset && a.separatorInsets == b.separatorInsets
            && a.rowMinHeight == b.rowMinHeight && a.rowVerticalPadding == b.rowVerticalPadding
            && a.firstHeaderTop == b.firstHeaderTop && a.headerTopAfterRows == b.headerTopAfterRows
            && a.headerTopAfterFooter == b.headerTopAfterFooter && a.rowsTopWithoutHeader == b.rowsTopWithoutHeader
            && a.headerToRows == b.headerToRows && a.footerTop == b.footerTop && a.footerIsCell == b.footerIsCell
    }

    public static let insetGrouped = ListMetrics(
        contentInset: 40, separatorInsets: (40, 20), rowMinHeight: 52, rowVerticalPadding: 15,
        firstHeaderTop: 10, headerTopAfterRows: 27.5, headerTopAfterFooter: 16, rowsTopWithoutHeader: 35,
        headerToRows: 10, footerTop: 8, footerIsCell: false)

    public static let plain = ListMetrics(
        contentInset: 20, separatorInsets: (20, 0), rowMinHeight: 52, rowVerticalPadding: 15,
        firstHeaderTop: 32, headerTopAfterRows: 32, headerTopAfterFooter: 32, rowsTopWithoutHeader: 0,
        headerToRows: 10, footerTop: 0, footerIsCell: true)
}

public protocol ListStyle {
    var _metrics: ListMetrics { get }
}

public struct InsetGroupedListStyle: ListStyle {
    public init() {}
    public var _metrics: ListMetrics { .insetGrouped }
}

public struct PlainListStyle: ListStyle {
    public init() {}
    public var _metrics: ListMetrics { .plain }
}

/// iOS resolves `.automatic` to inset grouped.
public struct DefaultListStyle: ListStyle {
    public init() {}
    public var _metrics: ListMetrics { .insetGrouped }
}

extension ListStyle where Self == InsetGroupedListStyle {
    public static var insetGrouped: InsetGroupedListStyle { InsetGroupedListStyle() }
}

extension ListStyle where Self == PlainListStyle {
    public static var plain: PlainListStyle { PlainListStyle() }
}

extension ListStyle where Self == DefaultListStyle {
    public static var automatic: DefaultListStyle { DefaultListStyle() }
}

enum ListStyleContext {
    static var current: ListMetrics?
}

public struct _ListStyleView<Content: View>: View {
    let content: Content
    let metrics: ListMetrics

    public typealias Body = Never
    public var body: Never { fatalError("_ListStyleView has no body") }

    public func _makeNode() -> NodeElement {
        let outer = ListStyleContext.current
        ListStyleContext.current = metrics
        defer { ListStyleContext.current = outer }
        return content._makeNode()
    }
}

extension View {
    public func listStyle<S: ListStyle>(_ style: S) -> _ListStyleView<Self> {
        _ListStyleView(content: self, metrics: style._metrics)
    }
}
