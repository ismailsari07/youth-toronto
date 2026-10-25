#!/usr/bin/env bash
# App Store screenshots, 6.9" iPhone (1320×2868), English and Turkish.
# Runs on macOS after:
#   flutter build ios --simulator --debug -t screenshots/main.dart
# Writes screenshots/out/{en,tr}/NN_<shot>.png. See screenshots/main.dart.
set -euo pipefail

cd "$(dirname "$0")/.."
APP=build/ios/iphonesimulator/Runner.app
BUNDLE=ca.papemosque.app
OUT=screenshots/out
SHOTS=(prayer_light prayer_dark community event mosque reminders)
LANGS=(en tr)
DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max

[ -d "$APP" ] || { echo "No $APP: build it first"; exit 1; }

# The newest iOS runtime Xcode has.
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
rs = [r for r in json.load(sys.stdin)["runtimes"]
      if r["platform"] == "iOS" and r["isAvailable"]]
rs.sort(key=lambda r: [int(x) for x in r["version"].split(".")])
print(rs[-1]["identifier"])')
echo "Runtime: $RUNTIME"

UDID=$(xcrun simctl create "Screenshots 16 Pro Max" "$DEVICE_TYPE" "$RUNTIME")
cleanup() { xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true; xcrun simctl delete "$UDID" >/dev/null 2>&1 || true; }
trap cleanup EXIT

xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --operatorName "" \
  --batteryState charged --batteryLevel 100
xcrun simctl install "$UDID" "$APP"
# Launch once so the data container exists, then let it settle.
xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
sleep 10
xcrun simctl terminate "$UDID" "$BUNDLE" || true
CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
mkdir -p "$CONTAINER/tmp"
REQUEST="$CONTAINER/tmp/shot_request"
READY="$CONTAINER/tmp/shot_ready"

for lang in "${LANGS[@]}"; do
  mkdir -p "$OUT/$lang"
  n=0
  for shot in "${SHOTS[@]}"; do
    n=$((n + 1))
    file=$(printf '%s/%s/%02d_%s.png' "$OUT" "$lang" "$n" "$shot")
    echo "== $lang $shot"
    # The status bar follows the theme; the simulator's appearance matches it.
    if [ "$shot" = prayer_dark ]; then appearance=dark; else appearance=light; fi
    xcrun simctl ui "$UDID" appearance "$appearance"
    rm -f "$READY"
    # The app reads its shot and language from this file (screenshots/main.dart).
    printf '%s %s\n' "$shot" "$lang" > "$REQUEST"
    xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
    for _ in $(seq 1 90); do
      [ -f "$READY" ] && break
      sleep 1
    done
    [ -f "$READY" ] || { echo "Timed out waiting for $lang $shot"; exit 1; }
    # A wrong screen must fail the build, never pass as a green run.
    got=$(cat "$READY")
    [ "$got" = "$shot $lang" ] || { echo "Asked for '$shot $lang', the app opened '$got'"; exit 1; }
    sleep 1
    xcrun simctl io "$UDID" screenshot --type=png "$file"
    xcrun simctl terminate "$UDID" "$BUNDLE" || true
    size=$(sips -g pixelWidth -g pixelHeight "$file" | awk '/pixel/ {print $2}' | paste -sd x -)
    [ "$size" = "1320x2868" ] || { echo "$file is $size, not 1320x2868"; exit 1; }
    echo "   $file ($size)"
  done
done
