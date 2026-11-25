#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/run-ios-sim.sh [screenshot.png]
# Builds Examples/CounterApp for the iOS Simulator with plain swiftc (no
# .xcodeproj), installs it on a "SwiftDroid iPhone" simulator and launches it.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/.build/ios-sim"
APP="$OUT/CounterApp.app"
DEVICE_NAME="SwiftDroid iPhone"
BUNDLE_ID="dev.swiftdroid.CounterApp"
SHOT="${1:-}"

SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="$ARCH-apple-ios16.0-simulator"
SWIFTC=(xcrun --sdk iphonesimulator swiftc -target "$TARGET" -sdk "$SDK" -O)

rm -rf "$OUT" && mkdir -p "$APP"

"${SWIFTC[@]}" -parse-as-library -module-name SwiftDroidiOS \
    -emit-library -static -emit-module -emit-module-path "$OUT/SwiftDroidiOS.swiftmodule" \
    -o "$OUT/libSwiftDroidiOS.a" "$ROOT/Sources/SwiftDroidiOS/SwiftDroidiOS.swift"

"${SWIFTC[@]}" -parse-as-library -module-name CounterApp -D SWIFTDROID_SWIFTUI \
    -I "$OUT" -L "$OUT" -lSwiftDroidiOS \
    -o "$APP/CounterApp" \
    "$ROOT/Examples/CounterApp/CounterView.swift" \
    "$ROOT/Examples/CounterAppiOS/CounterAppiOS.swift"

cp "$ROOT/Examples/CounterAppiOS/Info.plist" "$APP/Info.plist"
codesign --force --sign - "$APP" 2>/dev/null

read -r RUNTIME TYPE < <(xcrun simctl list runtimes -j | python3 -c '
import json, sys
rs = [r for r in json.load(sys.stdin)["runtimes"] if r["platform"] == "iOS" and r["isAvailable"]]
if rs:
    phones = [t["identifier"] for t in rs[-1]["supportedDeviceTypes"] if t["productFamily"] == "iPhone"]
    print(rs[-1]["identifier"], phones[-1])
') || true
[ -n "${RUNTIME:-}" ] || { echo "ERROR: no iOS Simulator runtime installed (Xcode → Settings → Components)"; exit 1; }

UDID="$(xcrun simctl list devices -j | python3 -c "import json,sys; d=[x for xs in json.load(sys.stdin)['devices'].values() for x in xs if x['name']=='$DEVICE_NAME' and x['isAvailable']]; print(d[0]['udid'] if d else '')")"
if [ -z "$UDID" ]; then
    UDID="$(xcrun simctl create "$DEVICE_NAME" "$TYPE" "$RUNTIME")"
fi

xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID"

if [ -n "$SHOT" ]; then
    sleep 2
    xcrun simctl io "$UDID" screenshot "$SHOT" >/dev/null
    echo "Screenshot: $SHOT"
fi
