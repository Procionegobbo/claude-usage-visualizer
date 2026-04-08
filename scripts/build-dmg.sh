#!/bin/bash
set -e

# Build script for creating unsigned DMG distribution package
# Usage: ./scripts/build-dmg.sh v1.0.0

VERSION=$1
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 v1.0.0"
  exit 1
fi

# Validate version format (v1.0.0 or 1.0.0)
if ! [[ "$VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid version format (use v1.0.0 or 1.0.0)"
  exit 1
fi

# Check for required tools upfront
if ! command -v python3 &>/dev/null; then
  echo "❌ python3 not found. Required to read Info.plist"
  echo "   Install via: brew install python3"
  exit 1
fi

if ! command -v xcodebuild &>/dev/null; then
  echo "❌ xcodebuild not found. Xcode command-line tools required"
  echo "   Install via: xcode-select --install"
  exit 1
fi

if ! command -v hdiutil &>/dev/null; then
  echo "❌ hdiutil not found (native macOS tool). Running on macOS?"
  exit 1
fi

# Determine if we're being run from repo root or ClaudeUsageWidget subdirectory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if we need to change to ClaudeUsageWidget directory
if [[ -d "$REPO_ROOT/ClaudeUsageWidget" && -f "$REPO_ROOT/ClaudeUsageWidget/ClaudeUsageWidget.xcodeproj/project.pbxproj" ]]; then
  cd "$REPO_ROOT/ClaudeUsageWidget"
elif [[ -f "$REPO_ROOT/ClaudeUsageWidget.xcodeproj/project.pbxproj" ]]; then
  # Already in ClaudeUsageWidget directory
  cd "$REPO_ROOT"
else
  echo "❌ Cannot find Xcode project. Run from repo root or ClaudeUsageWidget directory."
  exit 1
fi

# Extract version without leading 'v' for comparison
TAG_VERSION="${VERSION#v}"

# Get bundle version from Info.plist with error handling
if [[ ! -f "Resources/Info.plist" ]]; then
  echo "❌ Info.plist not found at Resources/Info.plist"
  echo "   Current directory: $(pwd)"
  exit 1
fi

BUNDLE_VERSION=$(python3 -c "import plistlib; p=plistlib.load(open('Resources/Info.plist','rb')); print(p['CFBundleShortVersionString'])" 2>&1) || {
  echo "❌ Failed to read Info.plist:"
  echo "$BUNDLE_VERSION"
  exit 1
}

# Normalize version strings (strip whitespace)
BUNDLE_VERSION=$(echo "$BUNDLE_VERSION" | xargs)
TAG_VERSION=$(echo "$TAG_VERSION" | xargs)

# Verify version consistency (critical for UpdateChecker semver comparison)
if [[ "$BUNDLE_VERSION" != "$TAG_VERSION" ]]; then
  echo "❌ VERSION MISMATCH"
  echo "  Bundle CFBundleShortVersionString: $BUNDLE_VERSION"
  echo "  GitHub release tag: $TAG_VERSION"
  echo "  UpdateChecker will show false 'update available' to users"
  exit 1
fi

echo "✅ Version verified: $BUNDLE_VERSION == $TAG_VERSION"

# Setup cleanup trap for staging directory (ensures cleanup even on failure)
STAGING="/tmp/dmg-staging-$$-$RANDOM"
trap "rm -rf \"$STAGING\"" EXIT

# Build release configuration (output goes to DerivedData)
echo "🔨 Building release configuration..."
BUILD_OUTPUT=$(xcodebuild -scheme ClaudeUsageWidget -configuration Release -arch arm64 -derivedDataPath build 2>&1)

if [[ $? -ne 0 ]]; then
  echo "❌ Build failed:"
  echo "$BUILD_OUTPUT"
  exit 1
fi

# Dynamically find the built app (more robust than hardcoded path)
APP_PATH=$(find build -name "ClaudeUsageWidget.app" -type d | head -1)

if [[ -z "$APP_PATH" ]]; then
  echo "❌ App bundle not found in build output"
  echo "   Searched for: ClaudeUsageWidget.app in build/ directory"
  echo "   Available:"
  find build -type d -name "*.app" 2>/dev/null || echo "   (No .app bundles found)"
  exit 1
fi

# Verify app bundle is complete (contains executable)
if [[ ! -f "$APP_PATH/Contents/MacOS/ClaudeUsageWidget" ]]; then
  echo "❌ App bundle incomplete: missing executable"
  echo "   Expected: $APP_PATH/Contents/MacOS/ClaudeUsageWidget"
  exit 1
fi

echo "✅ App built successfully: $APP_PATH"

# Create DMG staging
mkdir -p "$STAGING"
cp -r "$APP_PATH" "$STAGING/"
echo "📦 App copied to staging: $STAGING"

# Create output directory (in repo root, not project root)
OUTPUT_DIR="$REPO_ROOT/output"
mkdir -p "$OUTPUT_DIR" || {
  echo "❌ Cannot create output directory: $OUTPUT_DIR"
  exit 1
}

# Check output directory is writable
if [[ ! -w "$OUTPUT_DIR" ]]; then
  echo "❌ Output directory not writable: $OUTPUT_DIR"
  exit 1
fi

# Create DMG
echo "💿 Creating DMG image..."
hdiutil create \
  -volname "ClaudeUsageWidget" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$OUTPUT_DIR/ClaudeUsageWidget-${VERSION}.dmg" || {
    echo "❌ Failed to create DMG"
    exit 1
  }

echo "✅ DMG created: $OUTPUT_DIR/ClaudeUsageWidget-${VERSION}.dmg"
