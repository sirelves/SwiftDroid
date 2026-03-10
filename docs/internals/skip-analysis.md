# Skip Analysis

Actionable architectural analysis of the Skip project.
Written as decision input for SwiftDroid Phases 1–4.

---

## 1. What Skip Is

Skip is a **transpiler** that converts Swift source code into Kotlin source code, then compiles the Kotlin with Gradle into Android bytecode.

Pipeline:

```
Swift source
    ↓  Swift compiler plugin (SwiftSyntax)
    ↓  AST transformation
Kotlin source
    ↓  Gradle / kotlinc
Android bytecode (.dex)
    ↓  Dalvik / ART runtime
Running on Android JVM
```

The key artifact is the Swift compiler plugin (`SkipPlugin`). It runs at build time, reads the Swift AST, and emits `.kt` files. Those `.kt` files are then handed to Gradle as if a Kotlin developer had written them.

The skip-ui repository contains the Kotlin-side implementations of SwiftUI components (`Text`, `VStack`, etc.) written as Jetpack Compose `@Composable` functions that the generated code calls into.

---

## 2. Transpiler vs Runtime: Consequence Table

| Property | Skip (transpiler) | SwiftDroid (runtime) |
|---|---|---|
| Execution semantics | JVM / Kotlin semantics | Native Swift semantics |
| Value types | Converted to Kotlin data classes (copy semantics approximated) | True Swift value types on every platform |
| async/await | Mapped to Kotlin coroutines (behavior differences possible) | Swift concurrency throughout |
| Actors | Partially supported; edge cases exist | Full Swift actor model |
| Memory model | JVM GC | Swift ARC |
| Binary size | Kotlin stdlib + Compose + generated code | Swift stdlib only |
| Debugging | Kotlin stack traces in production | Swift stack traces |
| Compile target | JVM bytecode | Native ARM/x86 via Swift Android SDK |
| Generated code | Yes — Kotlin files you can read | No — no generated files |
| Dependency chain | Swift → Kotlin → Gradle → dex | Swift → LLVM → .so |

The most important consequence: Skip apps run on the JVM, not on bare metal. SwiftDroid apps run as native binaries. This affects performance characteristics, startup time, memory layout, and interoperability with existing Kotlin/Java codebases.

---

## 3. What Skip Supports

Skip's support list as of 2024:

- **Views:** Text, VStack, HStack, ZStack, ScrollView, List, ForEach, Group, LazyVStack, LazyHStack, LazyVGrid, LazyHGrid
- **Controls:** Button, Toggle, Slider, Stepper, TextField, SecureField, Picker, Menu, Link
- **Navigation:** NavigationStack, NavigationSplitView, TabView, NavigationLink, sheet, fullScreenCover, alert, confirmationDialog
- **Property wrappers:** @State, @Binding, @ObservedObject, @StateObject, @EnvironmentObject, @Environment, @AppStorage
- **Modifiers:** Most common view modifiers (padding, frame, background, foregroundColor, font, overlay, etc.)
- **Layout:** Most common modifiers, fixedSize, layoutPriority
- **Combine:** ObservableObject with @Published

### How @State Maps to Compose

Skip transpiles `@State var count = 0` to:
```kotlin
var count by mutableStateOf(0)
```
`mutableStateOf` is Compose's observable state primitive. Reading it inside a `@Composable` function registers the composable as a subscriber. Writing it triggers recomposition. The semantics are similar but not identical — Kotlin's state is reference-typed, Swift's is value-typed.

### ViewBuilder → @Composable Lambda

Skip transpiles `@ViewBuilder` closures to `@Composable` lambdas. The result builder transform is not replicated in Kotlin; instead, Skip's transpiler maps each DSL construct directly to the corresponding Compose call.

---

## 4. Skip's Known Gaps

These are documented limitations or observed issues:

| Gap | Reason |
|---|---|
| **Canvas / drawRect** | No direct Compose equivalent for arbitrary 2D drawing at the composable level; requires custom Android View |
| **Custom Layout protocol** | SwiftUI's `Layout` protocol has no Compose analog; Compose uses a modifier-based constraint system |
| **UIViewRepresentable / NSViewRepresentable** | Platform wrapper types; not relevant on Android JVM |
| **GeometryReader** | Supported but with known sizing bugs in scroll contexts (reported on skip GitHub) |
| **NavigationStack path restoration** | State restoration across process restarts incomplete |
| **Concurrency** | Swift structured concurrency (task trees, task-local values) partially mapped; actors are approximated |
| **@Observable macro** | Added in Swift 5.9; Skip support was added later and may have edge cases |
| **Custom property wrappers** | Generic support is limited; complex wrapper chains may not transpile correctly |
| **Binary frameworks (XCFramework)** | Cannot transpile pre-compiled Swift into Kotlin |

The Canvas and custom Layout gaps are significant for any app that needs custom drawing (charts, custom gestures, games).

---

## 5. What SwiftDroid Learns from Skip

### API Surface Design First

Skip's public API is designed to match SwiftUI's API *exactly* — same type names, same parameter labels, same modifier chains. This is the right approach. Developers should not need to learn a new API; the entire value proposition is "the same code works on Android."

SwiftDroid should follow the same discipline: `SwiftDroid.VStack` must have the same initializer signature as `SwiftUI.VStack`. Any deviation is a bug.

### Edge Case Coverage for Property Wrappers

Reading skip-ui's Kotlin source reveals the full matrix of `@State` and `@Binding` edge cases that production apps hit: chained bindings, optional bindings, bindings derived from computed properties, `Binding.constant`, `@Binding` in ForEach cells. SwiftDroid's Phase 1 implementation must cover all of these.

### Compose Parameter Mapping

skip-ui's Kotlin source is the best available reference for how SwiftUI modifier parameters map to Compose modifier parameters. Examples:
- `VStack(alignment: .leading)` → `Column(horizontalAlignment = Alignment.Start)`
- `HStack(spacing: 8)` → `Row(horizontalArrangement = Arrangement.spacedBy(8.dp))`
- `.padding(.horizontal, 16)` → `.padding(horizontal = 16.dp)`

SwiftDroid's Android renderer (Phase 4) should use this mapping directly.

---

## 6. What SwiftDroid Does Differently

### No Generated Code

Skip generates `.kt` files. SwiftDroid generates nothing. The Swift code compiles directly to native ARM binaries via the official Swift Android SDK. There is no intermediate representation visible to the developer.

Consequence: SwiftDroid apps have no Gradle build step, no Kotlin compiler, no JVM startup overhead. The developer's toolchain is purely Swift.

### Exact Swift Semantics

Because SwiftDroid runs as native Swift code (not transpiled Kotlin), every Swift language feature works correctly:
- Value types with true copy semantics
- Swift actors with Swift memory model
- Swift async/await with Swift task trees
- Swift closures with Swift capture semantics

There is no "what if the transpiler gets this wrong" category of bug.

### Owned Layout Engine (Propose/Respond, Not Compose Constraints)

Jetpack Compose uses a *constraint-based* layout: each child receives min/max width and height constraints, and must report a size within those constraints. SwiftUI uses a *propose/respond* model: the proposal is advisory, the child can ignore it.

These models produce different behavior in edge cases (e.g., a view that wants to be larger than its parent's constraint). SwiftDroid implements SwiftUI's propose/respond model natively in Swift, so layout results on Android match iOS exactly, including edge cases.

### No Gradle for App Developers

A developer using Skip still needs Gradle to build. A developer using SwiftDroid uses only `swift build`. The entire build system is SPM.

---

## 7. Competitive Positioning Table

| | Skip | SwiftDroid | Compose Multiplatform | React Native |
|---|---|---|---|---|
| **Input language** | Swift | Swift | Kotlin | JavaScript/TypeScript |
| **Android execution** | JVM (Kotlin) | Native Swift | JVM (Kotlin) | JS engine + native bridge |
| **iOS execution** | SwiftUI native | SwiftUI native | Compose (non-native) | JS engine + native bridge |
| **Approach** | Transpiler | Runtime library | Shared runtime | Runtime + bridge |
| **Generated code** | Yes (Kotlin) | No | No | Yes (JS bundle) |
| **Layout engine** | Compose constraints | Propose/respond (SwiftUI model) | Compose constraints | Yoga (Flexbox) |
| **Swift semantics** | Approximated | Exact | N/A | N/A |
| **Maturity** | Production (2024) | Phase 0 (2026) | Production (2023) | Production (2015) |
| **Binary size overhead** | Kotlin stdlib + Compose | Swift stdlib only | Kotlin stdlib + Compose | JS runtime + React Native |
| **Existing Kotlin interop** | Via JVM | Via swift-java (Phase 4) | Native | Via native modules |
| **Target developer** | Swift/iOS developers | Swift/iOS developers | Kotlin/Android developers | Web developers |

### Summary

Skip is the right choice today for a team that wants to ship now. It is production-ready, commercially supported, and covers 90% of common SwiftUI patterns.

SwiftDroid is the right architecture for the long term:
- Exact Swift semantics, not approximated
- Native performance, not JVM
- No transpiler means no transpiler bugs
- SwiftUI's propose/respond layout model runs on Android, not Compose's constraint model

The gap between SwiftDroid and Skip is purely maturity. The architecture is better; the implementation takes longer.
