#!/bin/sh
# App Store preflight: fails on anything that would block upload or review.
# Usage: release/preflight.sh            (checks + unsigned Release archive)
set -u
cd "$(dirname "$0")/.."
fail=0
ok() { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; fail=1; }

echo "Configuration"
team=$(awk '/DEVELOPMENT_TEAM:/ {gsub(/"/,"",$2); print $2; exit}' ios/project.yml)
[ -n "$team" ] && ok "DEVELOPMENT_TEAM=$team" || bad "DEVELOPMENT_TEAM is empty in ios/project.yml"
grep -q 'TARGETED_DEVICE_FAMILY: "1"' ios/project.yml && ok "iPhone-only device family" || bad "device family not pinned to iPhone"
for f in ios/App/PrivacyInfo.xcprivacy ios/Widgets/PrivacyInfo.xcprivacy; do
  plutil -lint -s "$f" && ok "$f" || bad "$f is invalid"
done
if grep -rqE "UserDefaults|AppStorage" ios/App ios/Shared && ! grep -q CA92.1 ios/App/PrivacyInfo.xcprivacy; then
  bad "UserDefaults used without CA92.1 in the privacy manifest"
fi

echo "Assets"
icon=ios/App/Assets.xcassets/AppIcon.appiconset/icon.png
[ "$(sips -g pixelWidth "$icon" | awk '/pixelWidth/ {print $2}')" = 1024 ] && ok "icon 1024 px" || bad "icon must be 1024×1024"
sips -g hasAlpha "$icon" | grep -q "hasAlpha: no" && ok "icon has no alpha" || bad "icon must not have an alpha channel"
shots=$(ls release/screenshots/6.9/*.png 2>/dev/null | wc -l | tr -d ' ')
[ "$shots" -ge 3 ] && ok "$shots screenshots (6.9\")" || bad "need 3+ 6.9\" screenshots: run release/screenshots.sh"
for f in release/screenshots/6.9/*.png; do
  [ -f "$f" ] || continue
  size=$(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/ {printf "%s ", $2}')
  [ "$size" = "1320 2868 " ] || bad "$(basename "$f") is $size, expected 1320 2868"
done

echo "Public pages (host site/ and enter the URLs in App Store Connect)"
if grep -lq "{{" site/*.html; then bad "site/*.html still contains {{DEVELOPER_NAME}}/{{SUPPORT_EMAIL}} placeholders"; else ok "site/ pages filled in"; fi

echo "Build"
out=$(mktemp -d)
if xcodebuild -project ios/FRI.xcodeproj -scheme FRI -configuration Release -destination 'generic/platform=iOS' \
     -archivePath "$out/FRI.xcarchive" archive CODE_SIGNING_ALLOWED=NO -quiet > "$out/archive.log" 2>&1; then
  ok "unsigned Release archive"
  grep -q "warning:" "$out/archive.log" && { grep "warning:" "$out/archive.log" | sort -u; bad "archive has warnings"; }
  if strings "$out/FRI.xcarchive/Products/Applications/FRI.app/FRI" | grep -qE -- "-ui-testing|-demo|-fast-timer"; then
    bad "debug launch arguments compiled into Release"
  else ok "no debug launch arguments in Release"; fi
else
  tail -20 "$out/archive.log"; bad "archive failed"
fi
rm -rf "$out"

[ $fail = 0 ] && echo "Preflight passed." || echo "Preflight found blockers."
exit $fail
