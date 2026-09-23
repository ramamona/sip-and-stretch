# Releasing a signed & notarized build

Ad-hoc builds work fine on the Mac that built them, but anyone who downloads one gets
"Apple could not verify…". Signing with a **Developer ID** and having Apple **notarize** the app
removes that warning. You need a paid Apple Developer account (you do this setup once).

## 1. Create a Developer ID Application certificate

1. Open **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority…**
   Enter your email, choose **Saved to disk**, and save the `.certSigningRequest`.
2. Go to [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates/list),
   click **+**, choose **Developer ID Application** (profile type G2 Sub-CA), upload the request,
   and download the `.cer`.
3. Double-click the `.cer` to install it. Check that it's there:

   ```bash
   security find-identity -v -p codesigning
   # 1) ABCDEF… "Developer ID Application: Your Name (TEAMID1234)"
   ```

   The quoted text is your **signing identity**, and the part in parentheses is your **Team ID**.

## 2. Create an app-specific password for the notary service

1. Sign in at [account.apple.com](https://account.apple.com) → **Sign-In and Security → App-Specific Passwords**.
2. Create one called `sipstretch-notary` and copy it (it looks like `abcd-efgh-ijkl-mnop`).
3. Store it in your keychain once, so you never type it again:

   ```bash
   xcrun notarytool store-credentials sipstretch \
     --apple-id "you@example.com" --team-id "TEAMID1234" --password "abcd-efgh-ijkl-mnop"
   ```

## 3. Release from your Mac

```bash
make release SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID1234)" NOTARY_PROFILE=sipstretch
```

This builds a universal app, signs it with the hardened runtime, sends it to Apple
(`xcrun notarytool submit --wait`, usually 1–5 minutes), staples the ticket, checks it with
`spctl`, and writes `dist/SipStretch-<version>.zip`. It only needs the Command Line Tools.

## 4. Or let GitHub Actions do it on every tag

Add these **repository secrets** (Settings → Secrets and variables → Actions → New repository secret):

| Secret | What to put in it |
|---|---|
| `DEVELOPER_ID_CERT_P12` | Your certificate + private key, base64-encoded (see below) |
| `DEVELOPER_ID_CERT_PASSWORD` | The password you gave the `.p12` export |
| `APPLE_ID` | Your Apple ID email |
| `APPLE_TEAM_ID` | Your Team ID, e.g. `TEAMID1234` |
| `APPLE_APP_PASSWORD` | The app-specific password from step 2 |

To make the `.p12`: in Keychain Access, open **My Certificates**, right-click
**Developer ID Application: …** → **Export…**, save as `cert.p12` with a strong password, then:

```bash
base64 -i cert.p12 | pbcopy   # paste into the DEVELOPER_ID_CERT_P12 secret
rm cert.p12
```

Or set them from the terminal with the GitHub CLI:

```bash
base64 -i cert.p12 | gh secret set DEVELOPER_ID_CERT_P12
gh secret set DEVELOPER_ID_CERT_PASSWORD
gh secret set APPLE_ID
gh secret set APPLE_TEAM_ID
gh secret set APPLE_APP_PASSWORD
```

Then release:

1. Bump `CFBundleShortVersionString` (and `CFBundleVersion`) in `Support/Info.plist`, and move the
   `[Unreleased]` notes in `CHANGELOG.md` under the new version.
2. Commit, tag, and push:

   ```bash
   git tag v1.1.0
   git push origin main v1.1.0
   ```

3. The **Release** workflow tests, signs, notarizes and publishes the zip on the Releases page.
   Without the secrets (for example on a fork) it still publishes an ad-hoc build, labelled as such.

## 5. Keep the Homebrew cask in sync (optional)

The cask lives in [ramamona/homebrew-tap](https://github.com/ramamona/homebrew-tap). To have each release
bump its version and checksum automatically, create a **fine-grained personal access token** at
[github.com/settings/personal-access-tokens](https://github.com/settings/personal-access-tokens/new):
repository access **Only select repositories → ramamona/homebrew-tap**, permission **Contents: Read and write**.
Then:

```bash
gh secret set TAP_TOKEN -R ramamona/sip-and-stretch   # paste the token
```

Without it, update `version` and `sha256` in `Casks/sip-and-stretch.rb` by hand after each release
(`shasum -a 256 dist/SipStretch-X.Y.Z.zip`).

## Troubleshooting

- **`notarytool` says "Invalid"**: run `xcrun notarytool log <submission-id> --keychain-profile sipstretch`
  to see exactly which file failed and why.
- **"The signature does not include a secure timestamp" / "hardened runtime not enabled"**: make sure you
  built with `SIGN_IDENTITY` set (that's what adds `--options runtime --timestamp`).
- **The app needs no entitlements.** It doesn't record audio or video. Meeting detection only reads the
  "is this device running?" flag, which needs no permission.
