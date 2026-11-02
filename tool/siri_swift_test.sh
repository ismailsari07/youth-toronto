#!/usr/bin/env bash
# The Siri shortcuts' time rules, on Linux, without Xcode:
#   tool/siri_swift_test.sh
# Copies the Foundation-only sources into a throwaway Swift package inside a
# swift container. SwiftUI and AppIntents don't exist there: siri-check on
# Codemagic compiles those. If `docker pull` fails on a credential helper,
# run it with DOCKER_CONFIG pointing at a directory holding an empty config.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
docker run --rm -v "$root/ios:/src:ro" swift:5.10-noble bash -c '
  set -e
  mkdir -p /tmp/p/Sources/SiriCore /tmp/p/Tests/SiriCoreTests
  cp /src/Runner/Siri/SiriData.swift /src/Runner/Siri/SiriLogic.swift /src/Runner/Siri/SiriText.swift /tmp/p/Sources/SiriCore/
  cp /src/RunnerTests/SiriLogicTests.swift /tmp/p/Tests/SiriCoreTests/
  cat > /tmp/p/Package.swift <<PKG
// swift-tools-version:5.9
import PackageDescription
let package = Package(
  name: "SiriCore",
  targets: [
    .target(name: "SiriCore"),
    .testTarget(name: "SiriCoreTests", dependencies: ["SiriCore"]),
  ]
)
PKG
  cd /tmp/p && swift test 2>&1
'
