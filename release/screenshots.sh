#!/bin/sh
# Captures App Store screenshots (6.9" iPhone, 1320×2868) from isolated demo data.
# Usage: release/screenshots.sh ["iPhone 17 Pro Max"]
set -eu
cd "$(dirname "$0")/.."
DEVICE="${1:-iPhone 17 Pro Max}"
OUT="$PWD/release/screenshots/6.9"
rm -rf "$OUT" && mkdir -p "$OUT"
# Resolve the name to one UDID (newest runtime wins) so xcodebuild never sees an ambiguous name.
UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
name = sys.argv[1]
devices = json.load(sys.stdin)['devices']
for runtime in sorted(devices, reverse=True):
    for d in devices[runtime]:
        if name in (d['name'], d['udid']): print(d['udid']); sys.exit()
sys.exit('No available simulator named ' + name)" "$DEVICE")
DEVICE=$UDID
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl status_bar "$DEVICE" override --time 9:41 --dataNetwork wifi --wifiBars 3 --cellularBars 4 --batteryState charged --batteryLevel 100
TEST_RUNNER_SCREENSHOT_DIR="$OUT" xcodebuild test -project ios/FRI.xcodeproj -scheme FRI \
  -destination "platform=iOS Simulator,id=$DEVICE" \
  -only-testing:FRIUITests/AppStoreScreenshots -quiet
xcrun simctl status_bar "$DEVICE" clear
for f in "$OUT"/*.png; do sips -g pixelWidth -g pixelHeight "$f" | tail -2 | tr '\n' ' '; echo "$(basename "$f")"; done
