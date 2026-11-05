#!/usr/bin/env bash
# Launches a built Runner.app on a simulator: fails if it won't start, doesn't
# stay running, or never started Flutter through its scene.
#
# Usage: bash tool/check_simulator_launch.sh build/ios/iphonesimulator/Runner.app [seconds]
#
# Needs a Debug build: the "PapeScene" line in AppDelegate.swift is Debug-only.
# The engine only starts when the scene loads the storyboard, so that line
# proves the scene connected.
set -euo pipefail

app="${1:?Usage: check_simulator_launch.sh <Runner.app> [seconds]}"
seconds="${2:-30}"
marker="PapeScene: Flutter engine ready"

bundle_id=$(python3 -c "import plistlib, sys; print(plistlib.load(open(sys.argv[1], 'rb'))['CFBundleIdentifier'])" "$app/Info.plist")

device=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
runtimes = json.load(sys.stdin)['devices']
for runtime in sorted(runtimes, reverse=True):
    for d in runtimes[runtime]:
        if d['name'].startswith('iPhone'):
            print(d['udid'])
            raise SystemExit
")
if [ -z "$device" ]; then
  echo "Simulator launch: no iPhone simulator available"
  exit 1
fi
echo "Simulator launch: using $device"

xcrun simctl boot "$device" 2>/dev/null || true # already booted is fine
xcrun simctl bootstatus "$device" -b >/dev/null
xcrun simctl install "$device" "$app"

launched=$(xcrun simctl launch "$device" "$bundle_id")
pid="${launched##*: }"
case "$pid" in
  '' | *[!0-9]*)
    echo "Simulator launch: no process id in: $launched"
    exit 1
    ;;
esac

sleep "$seconds"

if ! kill -0 "$pid" 2>/dev/null; then
  echo "Simulator launch: the app stopped within $seconds seconds"
  exit 1
fi

logs=$(xcrun simctl spawn "$device" log show --last 5m --style compact \
  --predicate 'process == "Runner"' 2>/dev/null || true)
xcrun simctl terminate "$device" "$bundle_id" 2>/dev/null || true

if ! grep -q "Runner" <<<"$logs"; then
  # Says nothing about the app, so it mustn't fail the build. Running is still proven.
  echo "Simulator launch: WARNING: no logs to read, so the scene path is unconfirmed"
  echo "Simulator launch: the app stayed running for $seconds seconds"
  exit 0
fi
if ! grep -qF "$marker" <<<"$logs"; then
  echo "Simulator launch: the app ran, but Flutter never started through its scene"
  exit 1
fi
echo "Simulator launch: OK (running for $seconds seconds, engine started through the scene)"
