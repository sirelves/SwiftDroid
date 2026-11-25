# iOS adapter (Phase 5)

On Apple platforms SwiftDroid renders nothing: SwiftUI is already the native
runtime. `SwiftDroidiOS` is a list of `typealias`es onto SwiftUI/Combine, one per
public name the core implements. App code compiles straight against SwiftUI —
no wrapper types, no runtime cost.

```swift
#if canImport(SwiftUI)
import SwiftDroidiOS   // SwiftUI underneath
#else
import SwiftDroid      // Android: core + layout + Compose mapping
#endif
```

## Running on the simulator

`scripts/run-ios-sim.sh` compiles `SwiftDroidiOS` and
`Examples/CounterApp/CounterView.swift` (with `-D SWIFTDROID_SWIFTUI`) plus the
thin `Examples/CounterAppiOS` host (`App`/`WindowGroup`) using plain `swiftc`,
assembles the `.app`, and installs it on a "SwiftDroid iPhone" simulator. The
same `CounterView.swift` is what `swift run CounterAppDemo` runs on the core.

## Why curated aliases, not `@_exported import SwiftUI`

Only the aliased names are in scope, so a view the core doesn't have
(`List`, `NavigationStack`, …) fails to compile on iOS too, not just later on
the Android build.

**Limit:** members of aliased types still resolve (Swift member-import
leakage), so a modifier the core lacks (e.g. `.foregroundColor`) compiles via
`SwiftDroidiOS`. The parity suite is the real guard.

Modifiers in the core: `.padding` (all four overloads),
`.frame(width:height:alignment:)`, the flexible
`.frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)`,
and text style: `.font`, `.fontWeight`, `.bold`, `.foregroundColor`.

Text style is inherited like SwiftUI's environment (a `.textStyle` IR node;
innermost wins per attribute). The layout engine measures text with the
resolved font. `bold` and `fontWeight` are separate attributes, as measured in
SwiftUI: an explicit weight beats bold at any nesting, bold beats the font's
own weight, and an inner `bold(false)` undoes an outer `bold()`.

## Layout parity tables

Behavior that is easy to get subtly wrong is pinned by tables measured from
SwiftUI and kept as plain data in `Tests/ParityFixtures`:

| Table | What | SwiftUI side re-measures with |
|---|---|---|
| `FlexFrameCases` | 8 flexible frames × 8 proposals (incl. `nil`, `∞`), both axes | a probe `Layout` that proposes an exact size |
| `StackCases` | 16 stack scenarios (flexible frames, spacers, overflow, spacing) in `HStack` and `VStack` | a recording `Layout` around each child |

The core must produce the same numbers; the SwiftUI side re-checks the table
live, so an OS change in SwiftUI's behavior shows up as a failing test.

Stack distribution follows SwiftUI: children are visited from least to most
flexible (size at ∞ minus size at 0, ties in source order) and each takes from
an equal share of the space left. Because that measures every child three
times, layout results are memoised per (tree path, proposal) within a pass.

## Parity suite

`Tests/ParityFixtures/ParityFixtures.swift` is symlinked into two test targets:

| Target | Backend | Checks |
|---|---|---|
| `SwiftDroidParityTests` | SwiftDroid core | node/Compose trees + `ViewHost` behavior (taps, `@Binding`, `@ObservedObject`) |
| `SwiftUIParityTests` (`PARITY_SWIFTUI`) | `SwiftDroidiOS` → SwiftUI | each fixture renders via `ImageRenderer`; Combine-synthesised `objectWillChange` |

Any API divergence between the two backends is a build error in one of them.
New public API in the core = new alias here + a fixture using it.

Gaps the suite surfaced and the core now covers: `Group`, synthesised
`objectWillChange` (stored in the first `@Published` box, as Combine does),
`$model.property` → `Binding`, and `@ObservedObject` triggering re-render.

## State identity and ForEach

`ViewHost` owns a `StateStore`: `@State` is persisted per structural identity —
view type, position in a `TupleView`, `if` branch, and `ForEach` element id —
and each view's `@State` is bound to it (via `Mirror`) before its body runs.
State not reached during a render is dropped, so a view that leaves the
hierarchy comes back fresh. Before this, only the root view's state survived a
re-render.

`ForEach` supports `(data, id: \.keyPath)`, `Identifiable` data and
`Range<Int>`. Row state follows the id across reorders/insertions. Rendering is
linear (~15 µs per stateful row in release); there is no lazy container yet.

## ScrollView

`ScrollView(_ axes:showsIndicators:content:)`. Sizing is pinned by the measured
`ScrollCases` table: content is proposed `nil` on the scrolling axes; the view
takes the proposed length there (content's if unspecified) and the content's
size on the other axes. The scroll offset is the view's own `@State`, so it
survives re-renders and is dropped if the view leaves the hierarchy.

`CommandRenderer` emits a `.scroll` command and walks the content clipped to
the viewport: leaves outside are culled and clipped parts can't be tapped.
`ViewHost.scroll(at:by:)` routes each axis of a delta to the innermost viewport
that scrolls on it, passing the rest outward, in one render. On Android the
Compose mapping uses `verticalScroll`/`horizontalScroll` with Compose's own state.

## LazyVStack

Content is not evaluated up front: `_lazyRows()` returns row descriptors
(`ForEach` one per element; tuples, `Group`, `if` unfold), each capturing its
identity path. During layout, a `ScrollView` passes its visible window down
and the stack builds only rows intersecting it — exactly the rows SwiftUI
builds (pinned by `LazyCases`, re-measured live). Other rows take their last
measured height or the mean of measured ones; the stack takes the proposed
width. A lazy stack's position inside the scroll content is known only after
layout, so the scroll starts from last frame's position and re-lays out if it
moved. Offscreen rows keep their `@State` while their id exists.

Cost (release, macOS, stateful rows in a `ScrollView`, per scroll step):

| Rows | `VStack` | `LazyVStack` |
|---|---|---|
| 1 000 | 15 ms | 1 ms |
| 5 000 | 116 ms | 6 ms |
| 20 000 | 428 ms | 23 ms |

What remains linear is generating a descriptor per element (SwiftUI also
walks all ids).

## List and Section

`List` (content, `(data, id:)`, `Identifiable` data, `Range`) is a greedy
`ScrollView` over a `LazyVStack`, so rows are built lazily and keep state.
`Section` (title, `header:`, `footer:`) tags its rows; loose rows form one
section. Each row gets the style's chrome: content inset, minimum height with
centered content, separators between rows of a section, header/footer spacing.

The spacing rules are data (`ListMetrics`) for `.insetGrouped` (iOS's
`.automatic`) and `.plain`, measured on the iOS 26.3 simulator — the List
on macOS is a different control, so the macOS-side parity suite can't check
them. `scripts/measure-ios-list.sh` builds `Tools/ListProbe`, runs every case
on the simulator and prints the frames SwiftUI reports; `ListTests` asserts
those positions. Re-run it when a new iOS changes list metrics.

`Divider` is a 0.5pt hairline (measured on iOS), vertical inside an `HStack`.

## Known semantic differences

- Re-render is synchronous in the core (SwiftUI coalesces to the next frame).
  `@Published` writes run inside an `InvalidationQueue` transaction so the frame
  sees the new value; a manual `objectWillChange.send()` followed by a write to
  a plain property re-renders before the write.
- No momentum, bouncing, scroll indicators or `ScrollViewReader`. With a plain
  `VStack` the whole content is laid out (only drawing is culled); use
  `LazyVStack` for long content.
- `List`: no cell backgrounds or rounded section cards (the core has no fills
  yet), no selection, swipe actions, `onDelete`/`onMove`, sticky headers in
  `.plain`, or `.grouped`/`.sidebar` styles. Separator extents are not
  measured (only row geometry is).
- No `LazyHStack`, `pinnedViews`; estimated heights can make the
  content size shift as rows get measured (SwiftUI shows the same effect).
- Identity ignores container types: changing `VStack { Row() }` to
  `HStack { Row() }` keeps `Row`'s state (SwiftUI resets it).
- `ForEach($items) { $item in … }` (binding variant) is not supported; duplicate
  ids share state.
- `Group { … }.padding()` pads each child in SwiftUI; the core pads the group
  as one block.
- `Font` sizes are iOS's default Dynamic Type values (no Dynamic Type scaling);
  named `Color`s are iOS light-mode values (no dark mode). `Color` is not a
  `View` in the core yet, so `Color.red.frame(...)` compiles only on iOS.
- No `layoutPriority`; stacks' default `spacing` is a fixed 8 (SwiftUI adapts it
  per pair of views). `Spacer()` minimum is 8 in both.
- Compose has no "ideal size": `idealWidth`/`idealHeight` only affect the core's
  layout engine, not the Compose mapping.
- `spacing`/`minLength` are `Double` (non-optional) in the core vs `CGFloat?`
  in SwiftUI. Literals work on both; passing `nil` only works on SwiftUI.
