#!/usr/bin/env bash
# Fails if a built Runner.app doesn't carry com.apple.developer.siri. Without
# it, INPreferences.siriLanguageCode() throws an exception Swift can't catch
# and every shortcut crashes (TestFlight 1.4.0 build 26).
#
# Usage: bash tool/check_siri_entitlement.sh <Runner.app>
#
# A simulator build keeps its entitlements in the signature or, on recent
# Xcodes, in the binary's __entitlements section; either counts.
set -euo pipefail

app="${1:?Usage: check_siri_entitlement.sh <Runner.app>}"
key="com.apple.developer.siri"

signed=$(codesign -d --entitlements - --xml "$app" 2>/dev/null || true)
if grep -qF "$key" <<<"$signed" || LC_ALL=C grep -aqF "$key" "$app/Runner"; then
  echo "Siri entitlement: OK ($app)"
  exit 0
fi
echo "Siri entitlement: MISSING in $app"
echo "Every shortcut would crash in INPreferences.siriLanguageCode()."
exit 1
