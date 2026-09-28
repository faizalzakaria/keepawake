# AGENTS.md

Guidance for agents developing KeepAwake.

## Commands

- `./build.sh` - builds a universal (arm64 + x86_64) `KeepAwake.app`, generates `AppIcon.icns` from `scripts/make-icon.swift`, stamps the version from `version.txt` into `Info.plist`, and ad-hoc signs it. Any other `SIGN_IDENTITY` signs with hardened runtime + timestamp: release CI uses Developer ID; an Apple Development identity locally keeps the Accessibility grant across rebuilds.
- `open KeepAwake.app` - run it; the app is menu-bar only (`LSUIElement`), no Dock icon.
- `pmset -g assertions | grep KeepAwake` - confirms the power assertion is held.

## Architecture

- Everything is in `main.swift`: an `NSStatusItem` menu driving an IOKit power assertion (`IOPMAssertionCreateWithName`), an optional auto-off timer, and an optional mouse "jiggle" via `CGEvent` that needs Accessibility trust.
- Preferences persist in `UserDefaults` under the bundle id `com.faizalzakaria.keepawake`.
- Not sandboxed and not Mac App Store compatible: posting synthetic input is blocked by the App Sandbox. Distribution is Developer ID + notarization via GitHub Releases and the Homebrew cask.

## Conventions

- Keep the app a single dependency-free Swift file (`main.swift`) built by `swiftc`; do not introduce an Xcode project or SwiftPM without a reason.
- The app icon is drawn in Core Graphics by `scripts/make-icon.swift` at build time; do not commit generated `.icns`/PNGs, and do not use SF Symbols in the icon (their license forbids app-icon use).
- Conventional commits; never hand-edit `CHANGELOG.md`, `version.txt`, or `.release-please-manifest.json`.
- Release flow and required secrets are documented in `CONTRIBUTING.md#releases`; do not publish artifacts or edit the tap by hand.
- Never install a locally built bundle into `/Applications`; it would shadow the released app for LaunchServices.
- Never auto-add agent co-author lines to commit messages.
