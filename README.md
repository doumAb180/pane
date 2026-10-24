# Pane

**English** | [한국어](README.ko.md)

**Every window in its place.** A lightweight window manager that lives in the macOS menu bar.

Arrange windows with visual layout tiles or global keyboard shortcuts. Built with SwiftUI and AppKit, with support for light and dark mode.

## Installation

**macOS 13 or later · Apple Silicon and Intel Macs**

Choose either installation method below.

### Install with a DMG

1. Open the [latest release](https://github.com/doumAb180/pane/releases/latest) and download `Pane-<version>-universal.dmg`.
2. Open the DMG and **drag Pane.app into Applications**.
3. Launch **Pane** from your Applications folder.
4. Once the Pane icon appears in your menu bar, follow **First launch** below.

### Install with Homebrew

If you have [Homebrew](https://brew.sh), run:

```sh
brew tap doumab180/pane https://github.com/doumAb180/pane
brew install --cask doumab180/pane/pane
open -a Pane
```

This repository serves as a custom Homebrew tap. After installation, follow **First launch** below.

### First launch

1. Click **Pane** in the menu bar and use the button that opens accessibility settings.
2. Enable **Pane** in **System Settings → Privacy & Security → Accessibility**. Depending on your macOS version, this section may be labeled **Device Control & Data Access**.
3. If Pane is missing from the list, click **+** and add `Pane.app` from your Applications folder.
4. Select an app window and press **Control + Option + ←**. Press once for the left half, then again for the left quarter.

Accessibility permission lets Pane move and resize other apps' windows. You can also open Pane from the menu bar and click a layout tile.

The current app interface is in Korean; both English and Korean documentation are available.

### Updating

- **DMG installation:** Quit Pane, then replace the installed app with the version from the latest DMG.
- **Homebrew installation:** Quit Pane, then run:

```sh
brew update
brew upgrade --cask doumab180/pane/pane
open -a Pane
```

If permission prompts persist after an update, see the reset instructions under [Tips](#tips).

## Features

- **Repeat to resize:** Repeat the same direction to cycle through `½ → ¼ → ½`. Left and right keep the full available height; up and down keep the full available width.
- Horizontal and vertical splits, corners, thirds, maximize, and center
- Restore the previous layout for each window; repeat Restore to switch between its last two layouts
- Move windows between displays, using the space available around the menu bar and Dock
- Adjustable gaps, a global shortcut toggle, and an optional Command modifier to avoid conflicts
- Selected app and action feedback in the panel

## Keyboard shortcuts

The default modifier is **Control + Option (⌃⌥)**. Enable the additional Command modifier in settings to use **⌃⌥⌘** instead. Hover over a tile to see its shortcut.

| Key | Action |
| --- | --- |
| ← / → / ↑ / ↓ | Cycle between ½ and ¼ along that edge |
| U / I / J / K | Top left / top right / bottom left / bottom right |
| D / F / G | Left / middle / right third |
| Return | Maximize |
| C | Center |
| Delete | Restore the previous layout |
| P / N | Previous / next display |

Letter shortcuts use the physical key positions of a US keyboard. Displays follow the order provided by macOS and wrap around at either end.

<a id="사용-팁"></a>

## Tips

- If Spectacle, Rectangle, or another app uses the same shortcuts, disable those bindings or enable the additional Command modifier in Pane. Shortcuts that could not be registered appear in settings.
- Some apps enforce a minimum window size and may prevent a quarter-size layout. Pane reports when the resulting size is constrained.
- Exit full-screen mode before arranging a window. Maximize fits the current display's available area without creating a separate Space.
- Manually moving or resizing a window resets the next directional placement to half size. A window already at the exact half-size position switches to quarter size.
- If permission stops working after moving or replacing the app, quit Pane, remove it from the accessibility list, and add it again from its actual installation path. If the problem persists, run `tccutil reset Accessibility io.github.doumAb180.Pane` to reset **only Pane's permission**, then add and enable it again.
- To launch at login, add Pane in **System Settings → General → Login Items**.
- The current version supports shortcuts and panel controls. Drag-to-edge snapping and individual shortcut customization are not yet available.

## Development and distribution

Building from source requires Xcode or Command Line Tools with Swift 5.9 or later.

```sh
git clone https://github.com/doumAb180/pane.git
cd pane
bash scripts/build.sh
open dist
```

Move the generated `dist/Pane.app` into Applications, launch it, and follow **First launch** above.

```sh
swift test                        # Layout, coordinate, and display movement tests
bash scripts/build.sh             # App, DMG, and ZIP for the current Mac
bash scripts/build.sh --universal # App, DMG, and ZIP for Apple Silicon and Intel
bash scripts/package-dmg.sh       # Package the existing dist/Pane.app without rebuilding
```

Build outputs are written to `dist/`. To set a version, run `VERSION=0.2.0 bash scripts/build.sh --universal`.

GitHub Actions runs tests and builds on updates to `main` and pull requests. Pushing a version tag such as `v0.1.0` publishes a Universal DMG, ZIP, and SHA-256 checksums to GitHub Releases, then updates the Homebrew Cask on `main` with the DMG's checksum.

```sh
git tag v0.1.0
git push origin v0.1.0
```

| Path | Purpose |
| --- | --- |
| `Sources/Pane` | Panel, settings, shortcuts, and accessibility-based window control |
| `Sources/PaneCore` | Layout cycling and screen geometry |
| `Tests/PaneCoreTests` | Layout and multi-display logic tests |
| `scripts` | App bundle, icon, DMG, and ZIP generation |
| `Casks/pane.rb` | Homebrew installation metadata and DMG checksum |

No third-party package dependencies, analytics, or automatic updates. Settings stay on your Mac, and window information is never sent to an external service.

An independent project inspired by Rectangle and Spectacle.
