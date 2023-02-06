#!/usr/bin/env bash
set -euo pipefail
swift build -v \
    -Xswiftc "-sdk" \
    -Xswiftc "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
    -Xswiftc "-target" \
    -Xswiftc "arm64-apple-ios13.0-simulator" \
    -Xswiftc "-Xfrontend" \
    -Xswiftc "-debug-time-function-bodies" \
    -Xswiftc "-Xfrontend" \
    -Xswiftc "-debug-time-expression-type-checking" | xcpretty
