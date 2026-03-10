# SwiftUI Internals

Technical reference for SwiftDroid Phases 1–3.
Understanding these mechanisms is required before implementing any framework code.

---

## 1. View Protocol at the Type System Level

### The Protocol Definition

```swift
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}
```

The associated type `Body` makes `View` a generic protocol — you cannot use `View` as a plain existential without `any`. Every concrete view type must declare what its `body` produces at compile time.

### Opaque Return Types (`some View`)

`some View` in a function signature is an *opaque type*: the compiler knows the concrete type but the caller does not. This is different from `any View` (existential), which erases the type completely. `some View` is zero-cost because no boxing or vtable dispatch occurs — the compiler inlines the concrete type.

```swift
// The compiler resolves Body = VStack<TupleView<(Text, Button<Text>)>> at compile time
var body: some View {
    VStack {
        Text("hello")
        Button("tap") { }
    }
}
```

### `Never` as the Leaf Base Case

Primitive views (Text, Color, Shape) that do not themselves compose other views declare `Body = Never`. `Never` satisfies the `View` protocol with a body that is `fatalError()` — it is the bottom type, unreachable by construction.

```swift
extension Never: View {
    public var body: Never { fatalError() }
}
```

This terminates the recursive type tree. The compiler uses this to know when to stop resolving `body`.

### Type Identity = Positional Identity

SwiftUI identifies views by their *structural position* in the view tree, not by an explicit id. Given:

```swift
VStack {
    Text("a")   // position [0]
    Text("b")   // position [1]
}
```

If a conditional makes `Text("a")` disappear, SwiftUI does not consider `Text("b")` to have moved to position [0] — it uses a structural key derived from the path through `ViewBuilder` overloads. This is why `ForEach` requires explicit `id:` — without positional stability, Swift cannot key state correctly.

---

## 2. ViewBuilder / Result Builder Transform

### What the Compiler Does

A function annotated `@ViewBuilder` triggers the Swift result builder transform. The compiler rewrites the block's statements into a series of static `buildBlock()` calls. No runtime is involved — this is entirely a compile-time rewrite.

```swift
// Source code
@ViewBuilder var body: some View {
    Text("A")
    Text("B")
    Text("C")
}

// Compiler rewrites to
var body: some View {
    ViewBuilder.buildBlock(Text("A"), Text("B"), Text("C"))
}
// which returns TupleView<(Text, Text, Text)>
```

### `buildBlock` Overloads

ViewBuilder declares overloads for 1 through 10 children:

```swift
static func buildBlock<C: View>(_ c: C) -> C
static func buildBlock<C0: View, C1: View>(_ c0: C0, _ c1: C1) -> TupleView<(C0, C1)>
static func buildBlock<C0: View, C1: View, C2: View>(_ c0: C0, _ c1: C1, _ c2: C2) -> TupleView<(C0, C1, C2)>
// ... up to 10
```

More than 10 children require a `Group {}` wrapper, which provides a fresh 10-slot block.

### `TupleView`

`TupleView<(C0, C1, ...)>` is a heterogeneous tuple view that the layout system knows how to iterate. It holds children as a value-type tuple, preserving type information without heap allocation.

### Conditional Views

```swift
// Source
if condition {
    Text("yes")
} else {
    Text("no")
}

// Rewrites to
ViewBuilder.buildEither(
    first: Text("yes")   // or second: Text("no")
)
// Returns ConditionalView<Text, Text>
```

`buildEither(first:)` and `buildEither(second:)` each return `ConditionalContent<TrueContent, FalseContent>`. The concrete branch is selected at compile time per call site; at runtime the enum switches between cases.

### `buildIf` for Optional Views

```swift
// Source
if condition {
    Text("maybe")
}

// Rewrites to
ViewBuilder.buildIf(condition ? Text("maybe") : nil)
// Returns Text?
```

Optional views render nothing when `nil`, but their *position* in the tree is preserved — critical for stable state.

### `buildArray` for Loops

```swift
// Source: ForEach(items) { Text($0) }
// ForEach itself calls ViewBuilder.buildArray([Text, Text, Text])
```

`buildArray` accepts `[any View]` and returns an array-backed view. ForEach is the primary consumer.

---

## 3. Attribute Graph (`_makeView` / `_ViewOutputs`)

### The DAG Structure

SwiftUI maintains an *attribute graph* — a directed acyclic graph of view computations. Each node in the graph is a view type; each edge represents a dependency (child produces output consumed by parent).

The graph is built once during app startup and mutated incrementally on state change. This is far faster than rebuilding the entire tree.

### `_makeView` and `_ViewOutputs`

These are internal APIs (prefixed `_`) that form the attribute graph interface:

```swift
// Simplified conceptual interface
static func _makeView(
    view: _GraphValue<Self>,
    inputs: _ViewInputs
) -> _ViewOutputs
```

`_GraphValue<V>` is a lazily-evaluated graph node. `_ViewInputs` carries environment values and proposed sizes flowing *down* the tree. `_ViewOutputs` carries resolved sizes and rendering commands flowing *up*.

### Dirty-Flag Invalidation

Each graph node has a dirty bit. When a dependency changes:
1. The changed node marks itself dirty.
2. Dirty propagates upward through the graph to ancestors that depend on it.
3. On the next render pass, SwiftUI re-evaluates only dirty nodes.
4. Clean subtrees are reused verbatim — zero re-evaluation cost.

This is the mechanism that makes SwiftUI efficient even with complex view trees. A button press that changes one `@State` variable only re-evaluates the nodes that read that state.

---

## 4. `@State` Dependency Tracking

### Storage: Heap Box, Not Struct Field

`@State` does not store its value in the view struct. Views are copied on mutation (value semantics), so struct storage would lose state on every re-evaluation of `body`. Instead:

```
struct MyView {
    @State var count = 0
    // Compiler synthesizes:
    var _count: State<Int> = State(wrappedValue: 0)
}
```

`State<Int>` is a property wrapper whose *actual* storage is a `StateStorage<Int>` allocated on the heap and keyed by the view's structural identity in the attribute graph. The struct holds only a reference to this box.

### Thread-Local "Current Evaluator" Stack

During `body` evaluation, SwiftUI pushes the current view node onto a thread-local evaluator stack. Any `@State` `get` access during this window:
1. Reads the value from the heap box.
2. Records the currently-evaluating view as a *subscriber* of this state.

When `body` finishes, the view is popped from the stack. This is the exact mechanism used by MobX (JS), Vue 3, and other reactive frameworks — SwiftUI just implements it in Swift.

### `InvalidationQueue` Batching

When `@State` is written:
1. All subscribers are collected.
2. Subscribers are added to `InvalidationQueue` (not immediately re-evaluated).
3. `InvalidationQueue` coalesces changes within the same run loop tick.
4. At the end of the tick, a single re-render pass re-evaluates all dirty nodes.

Result: N state changes in one event handler = 1 re-render pass.

### Equatable Short-Circuit

If `Value` conforms to `Equatable` and the new value equals the old value, the write is a no-op — no subscribers are notified. This prevents spurious re-renders when the same value is "set" without changing.

---

## 5. Layout: Propose/Respond Model

### Core Contract

SwiftUI layout is a two-pass protocol between parent and child:

```
Parent proposes a size   →   child returns the size it wants
Parent then places child at a specific origin
```

```swift
// Conceptual interface
protocol LayoutNode {
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize
    func placeChildren(in bounds: CGSize) -> [PlacedChild]
}
```

`ProposedViewSize` has optional dimensions: `nil` means "take whatever you want"; `.infinity` means "fill all available space".

### VStack Algorithm (6 Steps)

1. **Collect children** — gather all child LayoutNodes.
2. **Identify inflexible children** — those that do not grow (Text, Image, fixed-size views).
3. **Propose `unspecified` height** to each inflexible child; collect their natural sizes.
4. **Sum inflexible heights + spacing** to find consumed height.
5. **Distribute remaining height** among flexible children (Spacer, views with `.frame(maxHeight: .infinity)`). Split equally by default; layout priority breaks ties.
6. **Place children** top-to-bottom, inserting `spacing` between each.

Total VStack height = sum of all child heights + (n-1) × spacing.
Total VStack width = max child width.

### HStack

Mirror image of VStack: axis is horizontal. Width distributes among flexible children; height = max child height.

### ZStack

1. Propose `unspecified` to all children.
2. ZStack size = bounding box (max width × max height across all children).
3. Place all children at the alignment point computed within the bounding box.

### Spacer Flex

`Spacer` reports `0` to `sizeThatFits` when proposed `unspecified`. When inside a VStack/HStack that has remaining space after inflexible children, Spacer receives an explicit proposed size equal to the remainder. `sizeThatFits` then returns that exact size. Multiple Spacers split the remainder equally.

### Text Wrapping

`Text.sizeThatFits(ProposedViewSize(width: 200, height: nil))`:
- If the text fits on one line within 200pt: returns `(text_width, line_height)`.
- If it does not fit: wraps and returns `(≤200, n × line_height)`.
- If `width: nil`: returns the natural single-line size.

Layout priority (`layoutPriority(_:)`) determines which child gets space first when the container cannot satisfy all children simultaneously. Higher priority children are measured before lower priority ones.
