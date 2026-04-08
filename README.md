# ClaudeUsageWidget — macOS Menu Bar Usage Monitor

Monitor your Claude Pro/Max API usage directly in the macOS menu bar with real-time updates and customizable alerts.

## Quick Start

**ClaudeUsageWidget** displays your Claude Pro/Max API usage in the macOS menu bar, showing both 5-hour and 7-day rolling window utilization at a glance.

**Requirements:** macOS 14.0 or later

## Installation

1. **Download** the latest DMG from [GitHub Releases](https://github.com/anthropics/claude-usage-visualizer/releases)
2. **Double-click** the DMG to mount it
3. **Drag** ClaudeUsageWidget.app to your Applications folder

## ⚠️ Gatekeeper Warning

macOS Gatekeeper will block the unsigned app on first run because it's not code-signed (we don't have an Apple Developer account). This is a **one-time setup** — after you grant permission once, the app launches normally.

### Option A: Graphical (Recommended)

1. Open **Applications** folder
2. Right-click **ClaudeUsageWidget.app**
3. Select **"Open"** (not "Open With...")
4. Click **"Open"** in the security dialog

### Option B: Command Line (Advanced Users)

Open Terminal and run:

```bash
xattr -d com.apple.quarantine /Applications/ClaudeUsageWidget.app
```

This removes the quarantine flag entirely. No dialog will appear on next launch.

---

## Features

- **Real-time Usage Display:** 5-hour and 7-day rolling window utilization in the menu bar
- **Inline Preferences:** Threshold notifications for usage alerts
- **Automatic Polling:** Configurable refresh interval (default: 5 minutes)
- **Smart Re-authentication:** Automatically refreshes expired tokens
- **Update Notifications:** Alerts when a new version is available on GitHub
- **Resilient:** Handles network errors gracefully; displays stale data when API is unreachable

## Contributing & Building

### Build from Source

```bash
cd ClaudeUsageWidget
xcodebuild build -scheme ClaudeUsageWidget
```

### Run Tests

```bash
xcodebuild test -scheme ClaudeUsageWidget
```

### Building a Release

See [RELEASE.md](RELEASE.md) for step-by-step release and distribution instructions.

## Support

- **Report Issues:** [GitHub Issues](https://github.com/anthropics/claude-usage-visualizer/issues)
- **License:** MIT

---

## Why Unsigned?

ClaudeUsageWidget is distributed as an unsigned app because we don't have an Apple Developer account. This means:

- ✅ **Free distribution** — no Developer Program fees
- ✅ **No code signing overhead** — faster release cycles
- ⚠️ **One-time user setup** — users must bypass Gatekeeper once
- ⚠️ **No notarization** — macOS may warn on download

For production apps with Apple Developer accounts, see [Apple's code signing documentation](https://developer.apple.com/support/code-signing/).
