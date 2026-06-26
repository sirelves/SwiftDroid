/// Platform-agnostic geometry primitives.
///
/// SwiftUI uses `CGSize`/`CGFloat` from CoreGraphics, which is Apple-only and
/// would not compile on Android or Linux. The layout engine must run inside the
/// platform-agnostic core, so SwiftDroid defines its own value types backed by
/// `Double` (a stdlib type — no Foundation/CoreGraphics import needed).

/// A width × height pair. All dimensions are non-negative in practice but the
/// type does not enforce it (a child may report an over-large natural size which
/// the parent then constrains).
public struct Size: Equatable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public static let zero = Size(width: 0, height: 0)
}

/// A point in a parent's coordinate space. `LayoutResult.origin` values are
/// always expressed relative to the immediate parent, SwiftUI-style.
public struct Point: Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = Point(x: 0, y: 0)
}

/// A size *proposed* by a parent to a child during the first layout pass.
///
/// Each dimension is optional with three meaningful forms:
/// - a finite value — "you have exactly this much space";
/// - `nil` (unspecified) — "report your natural/ideal size";
/// - `.infinity` — "fill all available space".
///
/// The child answers with a concrete `Size` via the engine's sizing pass.
public struct ProposedSize: Equatable {
    public var width: Double?
    public var height: Double?

    public init(width: Double?, height: Double?) {
        self.width = width
        self.height = height
    }

    /// Both dimensions unspecified — ask every child for its natural size.
    public static let unspecified = ProposedSize(width: nil, height: nil)

    /// Both dimensions zero.
    public static let zero = ProposedSize(width: 0, height: 0)

    /// Both dimensions infinite — fill all available space.
    public static let infinity = ProposedSize(width: .infinity, height: .infinity)
}

/// An absolute frame: an `origin` paired with a `size`. Produced by the renderer
/// when it accumulates parent-relative layout origins into absolute positions.
public struct Rect: Equatable {
    public var origin: Point
    public var size: Size

    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }

    public var x: Double { origin.x }
    public var y: Double { origin.y }
    public var width: Double { size.width }
    public var height: Double { size.height }

    /// Whether `point` falls inside this frame (used for hit-testing taps).
    public func contains(_ point: Point) -> Bool {
        point.x >= origin.x && point.x <= origin.x + size.width &&
        point.y >= origin.y && point.y <= origin.y + size.height
    }
}
