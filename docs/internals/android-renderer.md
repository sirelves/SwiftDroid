# Android Renderer (Phase 4)

How a SwiftDroid view becomes a native Android (Jetpack Compose) UI, and how to
build it.

## Pipeline

```
View  ──_makeNode()──▶  NodeElement  ──ComposeRenderer──▶  ComposeNode  ──emit()──▶  Jetpack Compose
        (Phase 2)         (IR)          (Phase 4, core)      (Compose IR)   (swift-java)
```

Unlike the headless/iOS path, the Android renderer does **not** run the
propose/respond `LayoutEngine` — layout is Compose's job. Instead it maps the
`NodeElement` tree onto native Compose containers and lets Compose lay them out:

| SwiftDroid | Jetpack Compose |
|---|---|
| `VStack(spacing:alignment:)` | `Column(verticalArrangement = spacedBy, horizontalAlignment)` |
| `HStack(spacing:alignment:)` | `Row(horizontalArrangement = spacedBy, verticalAlignment)` |
| `ZStack(alignment:)` | `Box(contentAlignment)` |
| `Text` | `Text` |
| `Button { }` | `Button(onClick =) { }` |
| `Spacer` | `Spacer` |
| `Group` / `EmptyView` | flattened away (no Compose equivalent) |

The mapping (`Sources/SwiftDroid/Render/ComposeRenderer.swift`) is platform-agnostic
and fully unit-tested (`ComposeRendererTests`). The `#if canImport(Android)` executor
in `Sources/SwiftDroidAndroid/AndroidRenderer.swift` walks the `ComposeNode` plan and
emits the `@Composable` calls.

## Toolchain & SDK

Cross-compiling Swift to Android needs an **open-source** toolchain (the Apple/Xcode
toolchain cannot use Swift SDKs) whose version matches the Android SDK bundle exactly.

```bash
# 1. Open-source toolchain (matches the Android SDK version)
brew install swiftly
swiftly init --assume-yes --skip-install
swiftly install 6.2.3            # installs to ~/Library/Developer/Toolchains

# 2. Swift 6.2.3 Android SDK bundle (no official swift.org build for 6.2.3 yet;
#    the matching bundle is published by skiptools)
swift sdk install \
  https://github.com/skiptools/swift-android-toolchain/releases/download/6.2.3/swift-6.2.3-RELEASE_android.artifactbundle.tar.gz \
  --checksum e2dc075abe4555c88c2291aea88b349c7e4b3cb848ce4a99b1591217303e81e6

swift sdk list                   # verify aarch64-unknown-linux-android28 is present
```

Also requires **Android NDK r27c** for linking.

## Cross-compile the core

```bash
./build-android.sh arm64         # aarch64-unknown-linux-android28, physical devices
./build-android.sh x86_64        # emulator
```

This builds the platform-agnostic `SwiftDroid` core (and `SwiftDroidAndroid`) as a
native `.so` for Android — no JVM, no transpilation.

## Remaining work to run on a device

The `.so` is consumed by an Android app:

1. **swift-java Compose bindings** — generate Swift bindings for the AndroidX
   Compose APIs so `AndroidRenderer.emit(_:)` can call `Column`/`Text`/`Button`/…
   directly. This is the one TODO in `AndroidRenderer.swift`.
2. **Gradle/Compose host** — an Android app with a `ComposeView`/Activity that loads
   the Swift `.so` over JNI and invokes `AndroidRenderer.setContent(CounterApp())`.
3. **Recomposition bridge** — wire `ViewHost.onRender` to a Compose `mutableStateOf`
   so a `@State` change triggers recomposition.

Until then, the full pipeline is verified headlessly: `swift run CounterAppDemo`
runs reactivity → layout → render off-device, and `ComposeRendererTests` proves the
Compose mapping.
