# Contributing

Thanks for wanting to contribute.

## Workflow

1. Fork the repo and create a branch.
2. Make your change in `main.swift` (the whole app lives there).
3. Run `./build.sh && open KeepAwake.app` and exercise the menu items you touched.
4. Open a pull request against `main`. CI builds the universal app on macOS.

## Repo Conventions

- Keep it dependency-free: one Swift file, built with `swiftc` via `build.sh`, no Xcode project.
- The minimum supported macOS is 12 (`LSMinimumSystemVersion` in `Info.plist` and `-target` in `build.sh`); keep them in sync.
- Use [conventional commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`). release-please uses them to pick the version bump and write release notes. Mark breaking changes with `!` or a `BREAKING CHANGE:` footer.
- Do not hand-edit release-please metadata: `CHANGELOG.md`, `version.txt`, `.release-please-manifest.json`.
- Do not commit build output (`KeepAwake.app`, DMGs) or signing material.

## Releases

Releases are fully automated by `.github/workflows/release-please.yml`:

1. Conventional commits land on `main`; release-please opens or updates a release PR bumping `version.txt` and `CHANGELOG.md`.
2. Merging that PR creates the `vX.Y.Z` tag and a **draft** GitHub Release.
3. The macOS job checks out the tag, builds the universal app, signs it with `Developer ID Application: FAIZAL FIKHRI ZAKARIA (8M427X769R)` using hardened runtime, notarizes and staples the app, packages, signs, notarizes, and staples `KeepAwake-X.Y.Z.dmg`, then verifies identity, team, hardened runtime, timestamp, architectures, version, and Gatekeeper (`source=Notarized Developer ID`) on the mounted DMG.
4. Only after verification passes does it upload the DMG, publish the release, and update `Casks/keepawake.rb` in [`faizalzakaria/homebrew-tap`](https://github.com/faizalzakaria/homebrew-tap).

Any signing, notarization, or verification failure leaves the release as a draft. Fix forward with a new commit and release; do not upload a DMG or edit the cask by hand.

Maintainers must keep these repository secrets provisioned:

- `MAC_DEVELOPER_ID_CERT_P12` - base64 of the password-protected `.p12` export of the Developer ID Application certificate and its private key for Team `8M427X769R`.
- `MAC_DEVELOPER_ID_CERT_PASSWORD` - the `.p12` export password.
- `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY` - App Store Connect API key used by `notarytool`; the API key is the base64-encoded `.p8` content.
- `HOMEBREW_TAP_TOKEN` - a token with contents write access to `faizalzakaria/homebrew-tap`.

Never commit or print credential contents.

To check a published artifact locally:

```sh
VERSION=x.y.z
gh release download "v$VERSION" -R faizalzakaria/keepawake --pattern "KeepAwake-$VERSION.dmg"
hdiutil attach "KeepAwake-$VERSION.dmg" -readonly -nobrowse -mountpoint ./mnt
spctl --assess --type execute --verbose=4 ./mnt/KeepAwake.app   # expect: accepted, source=Notarized Developer ID
xcrun stapler validate ./mnt/KeepAwake.app
hdiutil detach ./mnt
```

## Questions

Open an issue if something is unclear.
