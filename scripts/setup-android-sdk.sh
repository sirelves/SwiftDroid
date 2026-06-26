#!/usr/bin/env bash
set -euo pipefail

# Provisions an installed Swift Android SDK bundle so it can link native Android
# binaries against a local Android NDK. The skiptools 6.2.3 bundle ships with
# dangling symlinks (built on the skiptools CI host) for the NDK sysroot and the
# clang runtime; this wires them to *your* NDK and exposes the Swift runtime where
# the linker expects it.
#
# Usage:
#   ./scripts/setup-android-sdk.sh /path/to/android-ndk-r27c
#
# Prereqs (see docs/internals/android-renderer.md):
#   - open-source Swift 6.2.3 toolchain (swiftly install 6.2.3)
#   - swift sdk install <skiptools 6.2.3 android bundle>
#   - Android NDK r27c
#
# After running this, `./build-android.sh arm64` produces a native aarch64 ELF.

NDK="${1:?usage: setup-android-sdk.sh <android-ndk-dir>}"
ARCH="${2:-aarch64}"            # aarch64 | x86_64 | armv7
TRIPLE="${3:-aarch64-unknown-linux-android28}"

case "$(uname -s)" in
    Darwin) HOST_TAG="darwin-x86_64" ;;
    Linux)  HOST_TAG="linux-x86_64" ;;
    *) echo "Unsupported host OS"; exit 1 ;;
esac

PREBUILT="$NDK/toolchains/llvm/prebuilt/$HOST_TAG"
NDK_SYSROOT="$PREBUILT/sysroot"
NDK_CLANG="$(ls -d "$PREBUILT"/lib/clang/* 2>/dev/null | sort -V | tail -1)"
[ -d "$NDK_SYSROOT" ] || { echo "NDK sysroot not found at $NDK_SYSROOT"; exit 1; }
[ -d "$NDK_CLANG" ]   || { echo "NDK clang dir not found under $PREBUILT/lib/clang"; exit 1; }

BUNDLE="$(ls -d "$HOME"/Library/org.swift.swiftpm/swift-sdks/swift-*android*.artifactbundle 2>/dev/null | head -1)"
[ -z "$BUNDLE" ] && BUNDLE="$(ls -d "$HOME"/.swiftpm/swift-sdks/swift-*android*.artifactbundle 2>/dev/null | head -1)"
[ -n "$BUNDLE" ] || { echo "Installed Android SDK bundle not found; run 'swift sdk install ...' first"; exit 1; }
RES="$BUNDLE/swift-android/swift-resources/usr/lib"

echo "NDK:    $NDK"
echo "bundle: $BUNDLE"

# 1. NDK sysroot (the bundle's sdkRootPath) — provides the C library headers/libs.
ln -sfn "$NDK_SYSROOT" "$BUNDLE/swift-android/ndk-sysroot"

# 2. clang runtime (compiler-rt builtins, libunwind) — repoint the bundle's
#    dangling clang symlink and expose the per-triple names the linker requests.
ln -sfn "$NDK_CLANG" "$RES/swift/clang"
mkdir -p "$NDK_CLANG/lib/$TRIPLE"
ln -sf "../linux/libclang_rt.builtins-${ARCH}-android.a" "$NDK_CLANG/lib/$TRIPLE/libclang_rt.builtins.a"
ln -sf "../linux/$ARCH/libunwind.a"                      "$NDK_CLANG/lib/$TRIPLE/libunwind.a"

# 3. Swift runtime objects (swiftrt.o, libswiftCore.so, …) under the sysroot,
#    where the driver looks for them — for both dynamic and static stdlib.
mkdir -p "$NDK_SYSROOT/usr/lib/swift" "$NDK_SYSROOT/usr/lib/swift_static"
ln -sfn "$RES/swift-${ARCH}/android"        "$NDK_SYSROOT/usr/lib/swift/android"
ln -sfn "$RES/swift_static-${ARCH}/android" "$NDK_SYSROOT/usr/lib/swift_static/android"

echo "✅ provisioned. Now: ./build-android.sh arm64"
