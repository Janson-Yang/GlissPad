<p align="center">
  <img src="docs/assets/glisspad-icon.png" alt="GlissPad app icon" width="128">
</p>

<h1 align="center">GlissPad</h1>

<p align="center">
  <strong>A macOS trackpad productivity app for custom gestures and automation workflows.</strong>
</p>

<p align="center">
  Create trackpad triggers, attach ordered actions, and keep the listener
  running from the menu bar while the editor window is hidden.
</p>

<p align="center">
  <a href="#features">Features</a> ·
  <a href="#install-from-a-dmg">Install</a> ·
  <a href="#build-from-source">Build</a> ·
  <a href="#configuration">Configuration</a> ·
  <a href="#license">License</a>
</p>

## Features

- Native macOS editor for triggers, actions, parameters, and test runs.
- One-finger and two-finger trigger types, including taps, holds, corner clicks,
  custom paths, two-finger swipes, pinch, rotate, and release gestures.
- Ordered action workflows. Actions run from top to bottom and stop on failure.
- Action types for AppleScript, shell commands, keyboard shortcuts, test HUDs,
  and explicit latency delays.
- Menu bar control, settings window, and optional launch at login.
- JSON configuration stored outside the app bundle.
- Import and export JSON configurations from the editor window.
- This is the first public version, with more trigger and workflow features on
  the way.

## Requirements

- macOS 13 or newer. The Swift package currently declares `.macOS(.v13)` as
  its minimum supported platform.
- Xcode or Command Line Tools for building from source.
- Accessibility permission for global event observation and UI automation.

GlissPad reads trackpad data through Apple's private MultitouchSupport
framework, keeping the app small, native, and local.

## Install From A DMG

Open the DMG, then drag `GlissPad.app` to `Applications`.

On first launch, macOS may ask for Accessibility permission. Grant permission to
GlissPad in `System Settings > Privacy & Security > Accessibility`, then restart
the app if needed.

If you build the DMG locally without a Developer ID certificate, macOS may show
the usual unsigned-app warning. Right-click `GlissPad.app` and choose `Open`, or
sign and notarize the app before distributing it.

## Build From Source

```sh
swift build -c release
```

Run the editor:

```sh
swift run glisspad
```

Run only the listener:

```sh
swift run glisspad --agent
```

Useful flags:

```sh
swift run glisspad --debug
swift run glisspad --config ./config.json
swift run glisspad --agent --no-permission-prompt
```

## Package A DMG

Create a drag-to-install DMG:

```sh
Scripts/package-macos-dmg.sh
```

The default output is:

```text
dist/GlissPad-v1.0.0.dmg
```

Set `GLISSPAD_VERSION` to build a different versioned artifact:

```sh
GLISSPAD_VERSION=1.0.1 Scripts/package-macos-dmg.sh
```

Set `GLISSPAD_CODESIGN_IDENTITY` to choose a signing identity. If it is not set,
the script tries the first local Apple Development identity and falls back to
ad-hoc signing.

## Configuration

The app stores user configuration at:

```text
~/Library/Application Support/GlissPad/config.json
```

The app bundle and DMG do not include this file. Local test triggers and actions
stay in the user's Application Support directory and are not packaged into a
release build.

Fresh installs start with an empty configuration. Users add triggers and actions
through the editor or import an exported JSON configuration.

`config.example.json` contains a disabled example trigger that demonstrates the
current JSON shape. Most users should edit triggers through the native UI.
Use `Export` and `Import` in the editor window to move configured triggers and
actions between machines.

## Actions

Each trigger owns an ordered action list:

- `Run AppleScript` runs the text through `/usr/bin/osascript`.
- `Run Shell Script` runs the text through `/bin/bash -lc`.
- `Keyboard Shortcut` sends a key or key combination.
- `Pop up a test HUD` shows a small confirmation overlay.
- `Action Latency` waits for a configured duration before the next action.

More action types are on the way.

AppleScript is best for macOS app automation, System Events, Finder commands,
and UI scripting. Shell scripts are best for command-line tools, files,
environment setup, and launching external commands.

## Development

Run the test suite:

```sh
swift test
```

Install a local build into `/Applications`:

```sh
Scripts/install-macos-app.sh
```

The install script does not remove or rewrite your existing configuration.

## Troubleshooting

- If gestures are not detected, confirm Accessibility permission for the exact
  binary or app bundle you are running.
- If an AppleScript action fails, test the same script in Script Editor or with
  `osascript`.
- If a shell action fails, remember that it runs under `/bin/bash -lc`; use
  absolute paths when tools are not on the default PATH.
- If a workflow stops early, inspect the failing action first. Later actions do
  not run after a failure.

## License

MIT.
