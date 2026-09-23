# Security Policy

## Supported versions

Only the **latest release** of Sip & Stretch gets security fixes. Please update before reporting.

| Version | Supported |
|---|---|
| Latest release | ✅ |
| Older releases | ❌ |

## Reporting a vulnerability

Please **don't open a public issue** for security problems.

Report it privately with GitHub's **private vulnerability reporting**: go to the repository's **Security** tab → **Report a vulnerability**, or open <https://github.com/ramamona/sip-and-stretch/security/advisories/new>.

Please include what you found, how to reproduce it, the app version, and your macOS version. We'll acknowledge the report as soon as we can, keep you updated, and credit you in the release notes if you'd like.

## Scope

Sip & Stretch runs entirely on your Mac. It makes no network requests and stores data only in `UserDefaults` (`com.sipstretch.app`). Things worth reporting include, for example, the `sipstretch://` URL handler doing something it shouldn't, or problems with how release builds are packaged.
