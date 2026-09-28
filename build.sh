#!/bin/sh
# Builds a universal (arm64 + x86_64) KeepAwake.app next to this script.
# SIGN_IDENTITY selects the codesign identity; default "-" ad-hoc signs for local use.
# Any other identity signs with hardened runtime and a secure timestamp, as notarization requires.
set -eu
cd "$(dirname "$0")"
APP=KeepAwake.app
VERSION=$(cat version.txt)
SIGN_IDENTITY=${SIGN_IDENTITY:--}
OBJ=$(mktemp -d)
trap 'rm -rf "$OBJ"' EXIT

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
for arch in arm64 x86_64; do
  swiftc -O -target "$arch-apple-macos12" main.swift -o "$OBJ/$arch"
done
lipo -create "$OBJ/arm64" "$OBJ/x86_64" -output "$APP/Contents/MacOS/KeepAwake"

swiftc -O scripts/make-icon.swift -o "$OBJ/make-icon"
"$OBJ/make-icon" "$OBJ/AppIcon.iconset"
iconutil -c icns "$OBJ/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

cp Info.plist "$APP/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP/Contents/Info.plist"

if [ "$SIGN_IDENTITY" = "-" ]; then
  codesign --force --sign - "$APP"
else
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
fi
echo "Built $APP $VERSION - run: open $APP"
