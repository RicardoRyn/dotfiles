#!/bin/bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
staging=$(mktemp -d)
trap 'rm -rf -- "$staging"' EXIT
app="$staging/GlassLauncher.app"
mkdir -p "$app/Contents/MacOS"
cp native/Info.plist "$app/Contents/Info.plist"
xcrun swiftc -module-cache-path "$staging/module-cache" -target "$(uname -m)-apple-macosx26.0" -parse-as-library -O native/GlassLauncher.swift -o "$app/Contents/MacOS/GlassLauncher"
xcrun swiftc -module-cache-path "$staging/module-cache" -target "$(uname -m)-apple-macosx26.0" -O native/launcher-define.swift -o "$staging/launcher-define"
codesign --force --sign - "$app"
mkdir -p assets
ditto "$app" assets/GlassLauncher.app
install -m 755 "$staging/launcher-define" assets/launcher-define
