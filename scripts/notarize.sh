#!/usr/bin/env bash
# Notarizes and staples build/SipStretch.app, then writes dist/SipStretch-<version>.zip.
# The app must already be signed with a Developer ID (see `make release` and docs/RELEASING.md).
#
# Credentials (pick one):
#   NOTARY_PROFILE=sipstretch   a keychain profile made once with `xcrun notarytool store-credentials`
#   APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD   an Apple ID + app-specific password (used in CI)
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/SipStretch.app"
VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Support/Info.plist)"
ZIP="dist/SipStretch-$VERSION.zip"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    AUTH=(--keychain-profile "$NOTARY_PROFILE")
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]]; then
    AUTH=(--apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD")
else
    echo "✗ Set NOTARY_PROFILE, or APPLE_ID + APPLE_TEAM_ID + APPLE_APP_PASSWORD." >&2
    exit 1
fi

mkdir -p dist
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "▸ Submitting to Apple's notary service (usually a few minutes)…"
xcrun notarytool submit "$ZIP" "${AUTH[@]}" --wait

echo "▸ Stapling the ticket so the app opens offline too"
xcrun stapler staple "$APP"
spctl --assess --type execute --verbose=2 "$APP"

# Re-zip so the download contains the stapled app.
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "✓ $ZIP (notarized)"
