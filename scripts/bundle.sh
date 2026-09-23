#!/usr/bin/env bash
# Builds build/SipStretch.app from the Swift package:
#   release build → .app bundle (Info.plist + icon) → ad-hoc code signature.
#
# Usage: scripts/bundle.sh [output-dir]      (default: build)
#   UNIVERSAL=1 scripts/bundle.sh            also include an Intel slice (used for releases)
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/bundle.sh
#                                            sign for distribution (hardened runtime, ready to notarize)
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="${1:-build}"
APP="$OUT/SipStretch.app"

ARCH_FLAGS=()
if [[ "${UNIVERSAL:-0}" == "1" ]]; then
    ARCH_FLAGS=(--arch arm64 --arch x86_64)
fi

echo "▸ Building SipStretch (release)…"
swift build -c release --product SipStretch ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"}
BIN_DIR="$(swift build -c release --product SipStretch ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} --show-bin-path)"

echo "▸ Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/SipStretch" "$APP/Contents/MacOS/SipStretch"
cp Support/Info.plist "$APP/Contents/Info.plist"
cp Support/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

IDENTITY="${SIGN_IDENTITY:--}"
if [[ "$IDENTITY" == "-" ]]; then
    # Ad-hoc: fine for your own Mac (notifications, login item, URL scheme all work).
    codesign --force --sign - --timestamp=none "$APP"
else
    # Developer ID + hardened runtime + secure timestamp: what notarization requires.
    echo "▸ Signing with $IDENTITY"
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
    codesign --verify --strict --verbose=2 "$APP"
fi

echo "✓ $APP ($(lipo -archs "$APP/Contents/MacOS/SipStretch"))"
