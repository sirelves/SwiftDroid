# SwiftDroid

A SwiftUI-compatible runtime for Android, written in Swift.
Write one codebase in Swift/SwiftUI. Run it natively on iOS and Android.

---

## Problem Statement

iOS and Android developers share a UI programming model (declarative, reactive, composable) but not a language or framework. The existing cross-platform options either sacrifice Swift semantics (transpilers like Skip convert Swift to Kotlin), sacrifice native performance (JS-based bridges), or require developers to learn a new language (Kotlin Multiplatform). SwiftDroid solves this by implementing the SwiftUI programming model as a pure Swift library that compiles natively to Android via the official Swift SDK for Android, with no generated code and no JVM.

---

## Architecture

```
Developer writes this once:

    struct HomeView: View {
        @State var count = 0
        var body: some View {
            VStack {
                Text("Count: \(count)")
                Button("Increment") { count += 1 }
            }
        }
    }

                    ┌────────────────────────────┐
                    │     SwiftDroid Core         │
                    │  (platform-agnostic Swift)  │
                    │                             │
                    │  @State  @Binding  @ObObj   │
                    │  View  ViewBuilder  Layout  │
                    └────────────┬───────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                                     │
    ┌─────────▼──────────┐             ┌────────────▼──────────┐
    │   SwiftDroidiOS    │             │  SwiftDroidAndroid     │
    │                    │             │                        │
    │  typealias to      │             │  NodeElement tree      │
    │  SwiftUI native    │             │      ↓                 │
    │  (zero overhead)   │             │  Layout engine         │
    │                    │             │  (propose/respond)     │
    │                    │             │      ↓                 │
    │                    │             │  AndroidRenderer       │
    │                    │             │  (swift-java bridge)   │
    │                    │             │      ↓                 │
    │                    │             │  Jetpack Compose       │
    └─────────┬──────────┘             └────────────┬──────────┘
              │                                     │
    ┌─────────▼──────────┐             ┌────────────▼──────────┐
    │   iOS (SwiftUI)    │             │  Android (native ARM)  │
    └────────────────────┘             └───────────────────────┘
```

---

## Comparison

| | SwiftDroid | Skip | Compose Multiplatform | React Native |
|---|---|---|---|---|
| **Input language** | Swift | Swift | Kotlin | JS / TypeScript |
| **Android execution** | Native Swift | JVM (Kotlin) | JVM (Kotlin) | JS engine + bridge |
| **iOS execution** | SwiftUI native | SwiftUI native | Compose (non-native) | JS engine + bridge |
| **Approach** | Runtime library | Transpiler | Shared runtime | Runtime + bridge |
| **Generated code** | None | Kotlin files | None | JS bundle |
| **Swift semantics** | Exact | Approximated | N/A | N/A |
| **Layout model** | SwiftUI propose/respond | Compose constraints | Compose constraints | Flexbox (Yoga) |
| **Maturity** | Phase 0 — not ready | Production (2024) | Production (2023) | Production (2015) |

**Honest note:** Skip is production-ready today and the correct choice if you need to ship to Android now. SwiftDroid is Phase 0. The architecture is better; the implementation takes longer. Read `docs/internals/skip-analysis.md` for the full trade-off analysis.

---

## Roadmap

| Phase | Scope | Target | Status |
|---|---|---|---|
| **0 — Foundation** | SPM skeleton, research docs, public README | Weeks 1–3 | Complete |
| **1 — Reactivity** | @State, @Binding, @ObservedObject, DependencyGraph | Weeks 4–10 | Complete |
| **2 — View Protocol** | View, ViewBuilder, TupleView, NodeElement tree | Weeks 11–18 | Complete |
| **3 — Layout Engine** | Propose/respond model, VStack/HStack/ZStack/Text | Weeks 19–32 | Complete |
| **4 — Android Renderer** | swift-java bridge, Compose mapping, CounterApp demo | Weeks 33–44 | In progress — **done & tested:** Button, render layer (`DrawCommand`/`CommandRenderer`), reactive `ViewHost`, the `NodeElement`→Compose mapping (`ComposeRenderer`), and a headless CounterApp demo (`swift run CounterAppDemo`). **✅ Native build verified:** with open-source Swift 6.2.3 + Android SDK 6.2.3 + NDK r27c, the **entire stack (core + Compose mapping + adapter + CounterApp) compiles AND links to a native Android ARM64 binary** — `file` reports `ELF 64-bit aarch64, interpreter /system/bin/linker64`, no JVM, no transpilation. Reproducible via `scripts/setup-android-sdk.sh` + `build-android.sh arm64`. **Remaining:** run on an emulator/device, and the swift-java → Compose `emit()` + Gradle/JNI host for the live UI (see `docs/internals/android-renderer.md`) |
| **5 — iOS Adapter** | SwiftUI typealias layer, parity test suite | Weeks 45–52 | Not started |

---

## Getting Started

### Requirements

- Swift 6.0+ (main-snapshot toolchain recommended)
- Xcode 16+ (for iOS builds)
- Swift SDK for Android (see below for Android builds)

### Build on macOS

```bash
swift build
swift test
```

### Build for Android

1. Install the Swift SDK for Android following the [official guide](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html).

2. Verify the SDK is installed:
   ```bash
   swift sdk list
   ```

3. Build:
   ```bash
   # Physical device (arm64)
   ./build-android.sh arm64

   # Emulator (x86_64)
   ./build-android.sh x86_64

   # Both
   ./build-android.sh all
   ```

---

## Contributing

Phase 0 contributions are most useful as:
- **Documentation** — corrections or additions to `docs/internals/`
- **Issues** — implementation questions, architecture feedback, use-case reports

Phase 1+ contributions: read `docs/internals/swiftui-internals.md` first. Every pull request must include unit tests. Platform-specific code must not appear in `Sources/SwiftDroid/`.

See the rules in `task.md` for session discipline.

---

## License

Apache 2.0. See [LICENSE](LICENSE).
