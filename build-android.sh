#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build-android.sh [arm64|x86_64|all]
#   arm64  — aarch64-unknown-linux-android28 (default, physical devices)
#   x86_64 — x86_64-unknown-linux-android28  (emulator)
#   all    — build both architectures

ARCH="${1:-arm64}"

SDK_ARM64="aarch64-unknown-linux-android28"
SDK_X86_64="x86_64-unknown-linux-android28"

check_sdk() {
    local sdk_id="$1"
    if ! swift sdk list 2>/dev/null | grep -q "$sdk_id"; then
        echo "ERROR: Swift SDK '$sdk_id' is not installed."
        echo ""
        echo "Install it by running:"
        echo "  swift sdk install <bundle-url>"
        echo ""
        echo "Find the latest bundle at:"
        echo "  https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html"
        echo ""
        echo "After installing, verify with: swift sdk list"
        exit 1
    fi
}

build_for() {
    local sdk_id="$1"
    local label="$2"
    echo "==> Building SwiftDroid for $label ($sdk_id) ..."

    # The open-source toolchain's clang builtin headers (stddef.h, …) must be on
    # the include path when building the Android C modules — otherwise the SDK's
    # bionic overlay fails with "'stddef.h' file not found". Derive them from the
    # active toolchain.
    local tc clang_inc=""
    tc="$(ls -d "$HOME"/Library/Developer/Toolchains/swift-*RELEASE.xctoolchain 2>/dev/null | head -1)"
    [ -n "$tc" ] && clang_inc="$(ls -d "$tc"/usr/lib/clang/*/include 2>/dev/null | head -1)"

    swift build \
        --swift-sdk "$sdk_id" \
        --static-swift-stdlib \
        ${clang_inc:+-Xcc -isystem -Xcc "$clang_inc"} \
        -c release
    echo "==> Build succeeded for $label"
}

case "$ARCH" in
    arm64)
        check_sdk "$SDK_ARM64"
        build_for "$SDK_ARM64" "arm64 (physical device)"
        ;;
    x86_64)
        check_sdk "$SDK_X86_64"
        build_for "$SDK_X86_64" "x86_64 (emulator)"
        ;;
    all)
        check_sdk "$SDK_ARM64"
        check_sdk "$SDK_X86_64"
        build_for "$SDK_ARM64"  "arm64 (physical device)"
        build_for "$SDK_X86_64" "x86_64 (emulator)"
        ;;
    *)
        echo "Usage: $0 [arm64|x86_64|all]"
        exit 1
        ;;
esac

echo ""
echo "==> Build complete. To run on an Android emulator:"
echo ""
echo "  1. Push the binary to the emulator:"
echo "     adb push .build/release/<binary> /data/local/tmp/"
echo ""
echo "  2. Make it executable and run:"
echo "     adb shell chmod +x /data/local/tmp/<binary>"
echo "     adb shell /data/local/tmp/<binary>"
echo ""
echo "  Expected output: SwiftDroid 0.0.1 running on Android"
