<h1 align="center">KeepAwake</h1>
<p align="center">
  <a href="https://github.com/faizalzakaria/keepawake/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/faizalzakaria/keepawake/ci.yml?style=flat-square&label=ci" /></a>
  <a href="https://github.com/faizalzakaria/keepawake/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/faizalzakaria/keepawake?style=flat-square" /></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2012%2B-blue?style=flat-square" />
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-green?style=flat-square" /></a>
</p>

<h3 align="center">A tiny menu-bar coffee cup that keeps your Mac awake.</h3>

KeepAwake is a single-file Swift menu-bar app with no dependencies.
Click the cup in the menu bar to keep your Mac (and optionally its display) from sleeping, for as long as you choose.

- **Keep Awake** - holds a macOS power assertion, the same mechanism `caffeinate` uses. On by default at launch.
- **Also Keep Display On** - choose between preventing display sleep or only system sleep.
- **Turn Off After** - 30 minutes to 12 hours, or never.
- **Keep Teams Active** - nudges the mouse by one pixel every 3 minutes so chat apps like Teams and Slack don't mark you as Away. Requires Accessibility permission.

## Quick Start

Requires macOS 12 Monterey or newer (Apple silicon or Intel).

```sh
brew install --cask faizalzakaria/tap/keepawake
open -a KeepAwake
```

Or download `KeepAwake-<version>.dmg` from the [latest release](https://github.com/faizalzakaria/keepawake/releases/latest) and drag KeepAwake into Applications.
Releases are signed with a Developer ID and notarized by Apple.

Update with Homebrew:

```sh
brew update
brew upgrade --cask keepawake
```

## Permissions

"Keep Teams Active" posts synthetic mouse-move events, which macOS only allows for apps you trust.
The first time you enable it, macOS prompts you; grant it in **System Settings > Privacy & Security > Accessibility**.
Until then the menu item reads "Grant Accessibility!" and no events are posted.
Keep Awake and the display option need no permissions.

To confirm KeepAwake is holding the assertion:

```sh
pmset -g assertions | grep KeepAwake
```

## Build from Source

Requires the Xcode Command Line Tools (`xcode-select --install`).

```sh
./build.sh
open KeepAwake.app
```

`build.sh` produces a universal, ad-hoc signed `KeepAwake.app`.
Because ad-hoc signatures change on every build, macOS may ask you to re-grant Accessibility after rebuilding.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

KeepAwake is released under the MIT License.
See [LICENSE](LICENSE) for details.
