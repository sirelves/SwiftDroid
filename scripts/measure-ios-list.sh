#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/measure-ios-list.sh
# Measures List geometry on the iOS Simulator (Tools/ListProbe) — the source
# of ListMetrics and of the expectations in Tests/SwiftDroidTests/ListTests.swift.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/.build/list-probe"
APP="$OUT/ListProbe.app"
BUNDLE_ID="dev.swiftdroid.ListProbe"
MODES=(plainDefault sections hdrFirst tall rowKinds styledPlain plainSections bare)

rm -rf "$OUT" && mkdir -p "$APP"
xcrun --sdk iphonesimulator swiftc -parse-as-library -O \
    -target "$(uname -m)-apple-ios17.0-simulator" -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
    "$ROOT/Tools/ListProbe/ListProbe.swift" -o "$APP/ListProbe"
sed 's/CounterApp/ListProbe/g; s/dev.swiftdroid.ListProbe/'"$BUNDLE_ID"'/' "$ROOT/Examples/CounterAppiOS/Info.plist" > "$APP/Info.plist"
codesign --force --sign - "$APP" 2>/dev/null

UDID="$(xcrun simctl list devices available | grep -m1 -E 'iPhone' | grep -oE '[0-9A-F-]{36}')"
[ -n "$UDID" ] || { echo "ERROR: no iPhone simulator (run scripts/run-ios-sim.sh once to create one)"; exit 1; }
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" "$APP"

for mode in "${MODES[@]}"; do
    SIMCTL_CHILD_MODE="$mode" xcrun simctl launch --console-pty --terminate-running-process "$UDID" "$BUNDLE_ID" 2>&1 | grep PROBE || true
done
