#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

probe_directory="$(mktemp -d "${TMPDIR:-/tmp}/pesty-panel.XXXXXX")"
trap 'rm -rf "$probe_directory"' EXIT
probe_app="$probe_directory/PestyPanelBehaviorProbe.app"
mkdir -p "$probe_app/Contents/MacOS"
cat > "$probe_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>org.pesty.panel-behavior-probe</string>
<key>CFBundleExecutable</key><string>PestyPanelBehaviorProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST

probe_sources=()
while IFS= read -r -d '' source; do
  probe_sources+=("$source")
done < <(find Sources/Pesty -type f -name '*.swift' ! -path 'Sources/Pesty/Main.swift' -print0)

xcrun swiftc -parse-as-library -swift-version 5 \
  -module-cache-path "$probe_directory/module-cache" \
  "${probe_sources[@]}" Tests/InteractionProbe/PanelBehaviorProbe.swift \
  -o "$probe_app/Contents/MacOS/PestyPanelBehaviorProbe"

codesign --force --sign - "$probe_app" >/dev/null
# No retries: every fresh launch must pass. Use separate history/preferences
# for each run so prior fixture pinboards cannot influence section order.
for attempt in 1 2 3; do
  probe_home="$probe_directory/home-$attempt"
  mkdir "$probe_home"
  touch "$probe_home/.pesty-fixture"
  echo "Fresh launch $attempt of 3"
  CFFIXED_USER_HOME="$probe_home" "$probe_app/Contents/MacOS/PestyPanelBehaviorProbe"
done
