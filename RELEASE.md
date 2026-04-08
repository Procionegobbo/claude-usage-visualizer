# Release Guide for ClaudeUsageWidget

This guide documents the process for creating releases and distributing ClaudeUsageWidget as unsigned DMGs.

## Overview

ClaudeUsageWidget is distributed as an **unsigned DMG** with no code signing or notarization. This allows us to distribute without an Apple Developer account, but requires users to manually bypass macOS Gatekeeper once.

### Why Unsigned?

- No Apple Developer Program fees
- Faster release cycles  
- Simpler distribution infrastructure

### Trade-off for Users

- One-time Gatekeeper bypass needed (GUI or terminal command)
- Users accept responsibility for security verification
- Documented in README.md with clear instructions

---

## Version Consistency Requirements

**CRITICAL:** The version in the app bundle **MUST** match the GitHub release tag exactly, or UpdateChecker will show false "update available" notifications to users.

### Version Sources of Truth

| Source | Location | Format | Purpose |
|--------|----------|--------|---------|
| Bundle Version | `Info.plist` → `CFBundleShortVersionString` | `1.2.3` (no 'v') | UpdateChecker semver comparison |
| Release Tag | GitHub Releases | `v1.2.3` (with 'v') | Download URL, version source |
| Build Script | `scripts/build-dmg.sh` | Compares and validates | Pre-release safety check |

### Version Validation in Build Script

The `build-dmg.sh` script automatically verifies version consistency:

```bash
# Extract version from Info.plist
BUNDLE_VERSION=$(python3 -c "import plistlib; p=plistlib.load(open('ClaudeUsageWidget/Resources/Info.plist','rb')); print(p['CFBundleShortVersionString'])")

# Strip 'v' from release tag
TAG_VERSION="${VERSION#v}"  # v1.0.0 → 1.0.0

# Exit with error if mismatch detected
if [[ "$BUNDLE_VERSION" != "$TAG_VERSION" ]]; then
  echo "❌ VERSION MISMATCH"
  exit 1
fi
```

**If the build script reports a mismatch, DO NOT proceed.** Fix the version in Info.plist first.

---

## Release Workflow Checklist

Follow this checklist **in order** for each release:

### 1. Preparation
- [ ] All features for this release are merged to `main`
- [ ] All tests pass: `xcodebuild test -scheme ClaudeUsageWidget`
- [ ] Code review completed (run `/bmad-code-review` if applicable)
- [ ] No outstanding bugs or regressions

### 2. Version Bump
- [ ] Decide on version number (semantic versioning: major.minor.patch)
  - Example: If current is `1.0.0`, bump to `1.0.1` (patch), `1.1.0` (minor), or `2.0.0` (major)
- [ ] Update `ClaudeUsageWidget/Resources/Info.plist`:
  - Find: `<key>CFBundleShortVersionString</key>`
  - Change value to new version (e.g., `1.1.0`) **without leading 'v'**
- [ ] Verify the change:
  ```bash
  plutil -p ClaudeUsageWidget/Resources/Info.plist | grep -A1 CFBundleShortVersionString
  ```

### 3. Testing
- [ ] Run full test suite: `xcodebuild test -scheme ClaudeUsageWidget`
- [ ] All 122+ tests pass with no regressions
- [ ] Manual smoke test (if applicable):
  - [ ] Launch app in menu bar
  - [ ] Check API token detection works
  - [ ] Verify usage display is correct
  - [ ] Test notification threshold functionality

### 4. Build DMG
- [ ] Create git tag with release version: 
  ```bash
  git tag v1.1.0  # Must match version in Info.plist
  ```
- [ ] Build DMG using the script:
  ```bash
  ./scripts/build-dmg.sh v1.1.0
  ```
- [ ] Script verifies version consistency and exits on mismatch
- [ ] Verify DMG was created: `ls -lh output/ClaudeUsageWidget-v1.1.0.dmg`

### 5. Create GitHub Release
- [ ] Push tag to remote: `git push origin v1.1.0`
- [ ] Create GitHub Release from tag at [Releases page](https://github.com/anthropics/claude-usage-visualizer/releases)
  - Release title: `ClaudeUsageWidget v1.1.0`
  - Description: Copy relevant sections from README.md or release notes
  - Include Gatekeeper bypass instructions in release body (optional, but helpful for new users)
- [ ] Attach DMG as release asset:
  - Upload: `output/ClaudeUsageWidget-v1.1.0.dmg`
- [ ] Publish release

### 6. Verification on Clean System (Optional but Recommended)
See "Manual QA Checklist" below.

---

## Manual QA Checklist

Verify the release on a clean macOS 14+ system (or simulator):

- [ ] **Download & Mount DMG**
  - [ ] Download DMG from GitHub Releases
  - [ ] Double-click to mount (no errors)
  - [ ] Volume labeled "ClaudeUsageWidget" appears on desktop

- [ ] **Drag Installation**
  - [ ] Drag ClaudeUsageWidget.app to Applications folder (visible in DMG)
  - [ ] Installation completes without errors
  - [ ] Eject DMG and delete from Downloads

- [ ] **Gatekeeper Interaction**
  - [ ] Navigate to Applications folder in Finder
  - [ ] Double-click ClaudeUsageWidget.app (should fail with "unidentified developer" error)
  - [ ] Right-click app → Open (shows security dialog)
  - [ ] Click "Open" button (app launches)

- [ ] **App Launch & Functionality**
  - [ ] Menu bar icon appears (SF Symbol or text indicator)
  - [ ] Popover opens showing usage rings (or error state if no token)
  - [ ] Preferences panel opens (if token detected, shows menu bar on/off)
  - [ ] Version in About dialog matches release tag (if About view exists)

- [ ] **Alternative Gatekeeper Bypass (Optional)**
  - [ ] Delete app from Applications folder
  - [ ] Re-download and drag to Applications again
  - [ ] Open Terminal and run:
    ```bash
    xattr -d com.apple.quarantine /Applications/ClaudeUsageWidget.app
    ```
  - [ ] Double-click app in Finder (should launch without security dialog)

---

## System Requirements

The build script requires:

- **macOS 14+** (deployment target)
- **Xcode command-line tools** (`xcode-select --install`)
- **python3** (for reading Info.plist)
- **hdiutil** (native macOS tool, included with OS)
- **Disk space:** At least 2GB free in `/tmp` (or use `TMPDIR=/var/tmp ./scripts/build-dmg.sh` for alternate location)

---

## Troubleshooting

### Build Script Says "python3 not found"
- Install via Homebrew: `brew install python3`
- Verify: `python3 --version`

### Build Script Says "xcodebuild not found"
- Install Xcode command-line tools: `xcode-select --install`
- Verify: `which xcodebuild`

### DMG Build Fails: "VERSION MISMATCH"
- [ ] Check Info.plist version:
  ```bash
  plutil -p ClaudeUsageWidget/Resources/Info.plist | grep CFBundleShortVersionString
  ```
- [ ] Ensure version matches the tag (without 'v'):
  - Tag: `v1.1.0` → Info.plist: `1.1.0`
- [ ] Fix Info.plist and retry: `./scripts/build-dmg.sh v1.1.0`

### DMG Creation Command Fails
- [ ] Ensure `hdiutil` is available (macOS native tool, should always be present)
- [ ] Check disk space: `df -h` (need at least 100MB free)
- [ ] Verify app was built in Release config: `ls -la build/Release/ClaudeUsageWidget.app`
- [ ] Try building from project root: `cd ClaudeUsageWidget && ../scripts/build-dmg.sh v1.1.0`

### Tests Fail Before Release
- [ ] Run: `xcodebuild clean && xcodebuild test -scheme ClaudeUsageWidget`
- [ ] Fix any failing tests before proceeding
- [ ] DO NOT release with failing tests

### Gatekeeper Still Blocks After Following Instructions
- [ ] Ensure app is in `/Applications` (not Downloads or other location)
- [ ] Try the terminal command: `xattr -d com.apple.quarantine /Applications/ClaudeUsageWidget.app`
- [ ] Restart and try again (macOS may cache Gatekeeper decisions)

---

## Rollback Procedure

If a release needs to be pulled:

1. Delete the GitHub Release
2. Delete the git tag:
   ```bash
   git tag -d v1.1.0
   git push origin --delete v1.1.0
   ```
3. Fix the issue (bug in code, version mismatch, etc.)
4. Bump to a new patch version and re-release

---

## Automation & CI/CD (Future)

Currently, the release process is **manual**. For future enhancement:

- [ ] GitHub Actions workflow could automate:
  - Running tests on tag push
  - Building DMG
  - Creating GitHub Release with DMG attachment
  - Notifying UpdateChecker subscribers

No automation is required for MVP — manual releases are acceptable for a single-developer or small-team project.

---

## Questions?

- For issues with unsigned apps and Gatekeeper, see [Apple's Gatekeeper documentation](https://support.apple.com/en-us/HT202491)
- For questions about distribution, open an issue: [GitHub Issues](https://github.com/anthropics/claude-usage-visualizer/issues)
