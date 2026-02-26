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

This builds the app, copies it to `/Applications`, and launches it. Then set BrowserChooser as your default browser in **System Settings > Desktop & Dock > Default web browser**.

## Configuration

Create `~/.config/browser-chooser/config.toml`:

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

The app watches this file and reloads automatically when you save changes.

### Config reference

**`[defaults]`** — `browser`: the browser name (or `"ask"`) to use when no rule matches.

**`[[browsers]]`** — defines browsers and Chromium profiles:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name, referenced in rules |
| `id` | Yes | macOS bundle identifier (e.g. `com.apple.Safari`) |
| `profile` | No | Chromium profile directory (e.g. `"Default"`, `"Profile 1"`) |

Browsers installed on your Mac are auto-detected. You only need `[[browsers]]` entries for Chromium profiles or to override names.

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
make clean       # remove build artifacts
```

## How it's built

Swift + SwiftUI menu bar app (no Dock icon). URLs arrive as Apple Events and route through pattern-matching rules to the target browser. Local HTML files are handled the same way.

Browser discovery queries NSWorkspace for installed apps that handle both `https://` URLs and `public.html`. Chromium profiles are read from each browser's `Local State` JSON.
