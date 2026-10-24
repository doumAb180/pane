#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

app="${1:-$PWD/dist/Pane.app}"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'App version must have the form 1.2.3' >&2
  exit 1
fi
codesign --verify --deep --strict "$app"
architectures="$(lipo -archs "$app/Contents/MacOS/Pane")"
if [[ "$architectures" == *arm64* && "$architectures" == *x86_64* ]]; then
  label=universal
elif [[ "$architectures" == *arm64* ]]; then
  label=arm64
else
  label=x86_64
fi

mkdir -p dist
staging="$(mktemp -d "${TMPDIR:-/tmp}/pane-dmg.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
ditto "$app" "$staging/Pane.app"
ln -s /Applications "$staging/Applications"
image="$PWD/dist/Pane-$version-$label.dmg"
hdiutil create -volname "Pane $version" -srcfolder "$staging" -fs HFS+ -format UDZO -ov "$image"
hdiutil verify "$image"
(cd dist && shasum -a 256 "$(basename "$image")" > "$(basename "$image").sha256")
echo "DMG: $image"
