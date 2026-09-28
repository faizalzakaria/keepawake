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
mkdir -p "$APP/Contents/MacOS"
for arch in arm64 x86_64; do
  swiftc -O -target "$arch-apple-macos12" main.swift -o "$OBJ/$arch"
done
lipo -create "$OBJ/arm64" "$OBJ/x86_64" -output "$APP/Contents/MacOS/KeepAwake"

cp Info.plist "$APP/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP/Contents/Info.plist"

if [ "$SIGN_IDENTITY" = "-" ]; then
  codesign --force --sign - "$APP"
else
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
fi
echo "Built $APP $VERSION - run: open $APP"
