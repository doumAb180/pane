#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

version="${VERSION:-0.3.1}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'VERSION must have the form 1.2.3' >&2
  exit 1
fi
app="$PWD/dist/Pane.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

if [[ "${1:-}" == "--universal" ]]; then
  for arch in arm64 x86_64; do
    swift build -c release --arch "$arch" --scratch-path ".build/$arch"
  done
  arm_bin="$(swift build -c release --arch arm64 --scratch-path .build/arm64 --show-bin-path)/Pane"
  intel_bin="$(swift build -c release --arch x86_64 --scratch-path .build/x86_64 --show-bin-path)/Pane"
  lipo -create "$arm_bin" "$intel_bin" -output "$app/Contents/MacOS/Pane"
  label="universal"
else
  swift build -c release
  cp "$(swift build -c release --show-bin-path)/Pane" "$app/Contents/MacOS/Pane"
  label="$(uname -m)"
fi

cp Resources/Info.plist "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$app/Contents/Info.plist"
swift scripts/make-icon.swift .build/AppIcon.iconset
iconutil -c icns .build/AppIcon.iconset -o "$app/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
archive="$PWD/dist/Pane-$version-$label.zip"
ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
(cd dist && shasum -a 256 "$(basename "$archive")" > "$(basename "$archive").sha256")
echo "Built: $app"
echo "Archive: $archive"
bash scripts/package-dmg.sh "$app"
