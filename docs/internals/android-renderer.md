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

The skiptools 6.2.3 bundle ships with dangling symlinks (the NDK sysroot and the
clang runtime point at the skiptools CI host). Wire them to your NDK once:

```bash
./scripts/setup-android-sdk.sh /path/to/android-ndk-r27c
```

Then build:

```bash
source ~/.swiftly/env.sh          # use the open-source toolchain
./build-android.sh arm64          # aarch64-unknown-linux-android28
./build-android.sh x86_64         # emulator
```

### Verified status (2026-06-25)

**The full stack — core + Compose mapping + `SwiftDroidAndroid` adapter + the
CounterApp demo — compiles AND links to a native Android ARM64 binary, no JVM and
no transpilation:**

```
$ file .build/aarch64-unknown-linux-android28/release/CounterAppDemo
ELF 64-bit LSB pie executable, ARM aarch64, interpreter /system/bin/linker64
```

What it took (all captured in `scripts/setup-android-sdk.sh` + `build-android.sh`):

- **`'stddef.h' file not found`** → `build-android.sh` adds the toolchain's clang
  builtin headers (`-Xcc -isystem -Xcc <toolchain>/usr/lib/clang/*/include`).
- **`ndk-sysroot`** → symlinked to the NDK r27c sysroot (the bundle's `sdkRootPath`).
- **`libclang_rt.builtins.a` / `libunwind.a`** → the bundle's `usr/lib/swift/clang`
  symlink repointed to the NDK's `lib/clang/<ver>`, with per-triple names exposed.
- **`swiftrt.o` / `libswiftCore.so`** → Swift runtime symlinked under the sysroot
  (`usr/lib/swift/android` and `usr/lib/swift_static/android`) for dynamic + static.

(skiptools' own `skip android sdk install` automates the same provisioning.)

## Remaining work to run on a device

The native binary still needs an emulator/device to run, and the Compose UI needs:

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
