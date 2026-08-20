# BrowserChooser

A macOS menu bar app that routes URLs to different browsers based on rules you define. Set it as your default browser, and every link you click gets sent to the right place.

## Why

You have multiple browsers (or Chrome profiles) for different contexts: work, personal, side projects. Every link you click opens in whichever browser macOS last remembers. BrowserChooser fixes that.

## How it works

1. Register BrowserChooser as your default browser
2. Define rules in a TOML config file
3. Click a link anywhere on your Mac
4. BrowserChooser matches the URL against your rules (top to bottom, first match wins) and opens it in the right browser

If no rule matches, it falls back to your configured default. Set the default to `"ask"` and you'll get a picker dialog instead.

## Install

Requires macOS 14 (Sonoma) or later.

```bash
make install
```

This builds the app, copies it to `/Applications`, installs a login item so it starts automatically at login, and launches it. Since macOS doesn't let apps set themselves as the default browser silently, it also opens **System Settings > Desktop & Dock** for you — pick BrowserChooser as your default web browser there.

## Configuration

BrowserChooser writes `~/.config/browser-chooser/config.toml` for you the first time it runs, pre-filled with a `[[browsers]]` entry for every browser (and Chrome/Firefox profile) it finds on your Mac — no need to hand-create it or look up bundle IDs yourself. From there, edit it directly:

```toml
[defaults]
browser = "ask"           # Show picker when no rule matches

[[browsers]]
name = "Chrome Work"
id = "com.google.Chrome"
profile = "Default"

[[browsers]]
name = "Chrome Personal"
id = "com.google.Chrome"
profile = "Profile 1"

[[browsers]]
name = "Firefox Personal"
id = "org.mozilla.firefox"
profile = "6eov930b.default-release"   # folder name under Firefox's Profiles/ dir

# Route multiple domains to the same browser in one rule
[[rules]]
patterns = [
    "*.notion.so", "*.hibob.com",
    "*.okta.com", "*.slack.com",
]
browser = "Chrome Work"

# Or use a single pattern per rule
[[rules]]
pattern = "*.github.com"
browser = "Chrome Personal"
```

The app watches this file and reloads automatically when you save changes. If a browser references a profile that doesn't exist, a rule references an unknown browser, or the default browser doesn't match anything configured or detected, BrowserChooser shows a "Config Warnings" section in the menu bar dropdown instead of failing silently.

### Config reference

**`[defaults]`** — `browser`: the browser name (or `"ask"`) to use when no rule matches.

**`[[browsers]]`** — defines browsers and their profiles:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name, referenced in rules |
| `id` | Yes | macOS bundle identifier (e.g. `com.apple.Safari`) |
| `profile` | No | Profile identifier — meaning depends on the browser, see below |

Browsers installed on your Mac are auto-detected, including their profiles — you only need `[[browsers]]` entries to override names or scope rules to a specific profile. If you install a new browser (or create a new profile) later, pick **Add Detected Browsers to Config** from the menu bar dropdown to append its entry to your existing config, or run:

```bash
make list-browsers
```

to print detected browsers/profiles as `[[browsers]]` blocks without touching the file. Both skip anything whose bundle ID is already referenced in your config, so existing entries and rules are never touched.

`profile` means different things depending on the browser family:

- **Chromium** (Chrome, Brave, Edge, Vivaldi, Arc): the profile directory name, e.g. `"Default"`, `"Profile 1"` — read from the browser's `Local State` file.
- **Firefox**: the profile's folder name under `~/Library/Application Support/Firefox/Profiles/`, e.g. `"6eov930b.default-release"` — find it with `ls ~/Library/Application\ Support/Firefox/Profiles/`, or omit `profile` and let auto-detection list your profiles by their display name in the menu bar picker. Profiles created via Firefox's newer multi-profile panel work too, but since they aren't registered in `profiles.ini`, BrowserChooser falls back to showing their folder name instead of the friendly name you gave them in Firefox.

**`[[rules]]`** — evaluated top to bottom, first match wins:

| Field | Description |
|-------|-------------|
| `pattern` | Single glob pattern |
| `patterns` | Array of glob patterns (use instead of `pattern` to group multiple domains) |
| `browser` | Browser name or `"ask"` to show the picker |

Each rule needs either `pattern` or `patterns` (not both). Without `/`, patterns match hostname only. With `/`, they match hostname + path.

Pattern examples: `*.example.com` (any subdomain), `example.com/docs/*` (path matching), `?oogle.com` (single-character wildcard).

## Building

```bash
make build       # swift build -c release
make bundle      # build + assemble .app bundle + codesign
make install     # bundle + copy to /Applications + launch
make test        # swift test
make run         # bundle + run from build directory
make list-browsers # bundle + print detected browsers/profiles as [[browsers]] TOML
make clean       # remove build artifacts
```

## How it's built

Swift + SwiftUI menu bar app (no Dock icon). URLs arrive as Apple Events and route through pattern-matching rules to the target browser. Local HTML files are handled the same way.

Browser discovery queries NSWorkspace for installed apps that handle both `https://` URLs and `public.html`. Chromium profiles are read from each browser's `Local State` JSON; Firefox profiles are read from `profiles.ini` and the `Profiles/` directory.
