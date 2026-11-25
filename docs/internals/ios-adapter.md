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
leakage), so `Text("x").padding()` compiles via `SwiftDroidiOS` even though the
core has no modifiers yet. The parity suite is the real guard.

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

## Known semantic differences

- Re-render is synchronous in the core (SwiftUI coalesces to the next frame).
  `@Published` writes run inside an `InvalidationQueue` transaction so the frame
  sees the new value; a manual `objectWillChange.send()` followed by a write to
  a plain property re-renders before the write.
- `spacing`/`minLength` are `Double` (non-optional) in the core vs `CGFloat?`
  in SwiftUI. Literals work on both; passing `nil` only works on SwiftUI.
