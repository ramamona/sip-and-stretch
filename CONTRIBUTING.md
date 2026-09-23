# Contributing to Sip & Stretch

Thanks for helping Drip keep people hydrated! 💧 Bug fixes, new stretches, new personalities, themes, translations, and docs fixes are all welcome.

By taking part you agree to follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Dev setup

**You need:** macOS 14 Sonoma or later, and either Xcode 16+ or the Command Line Tools with Swift 6 (`xcode-select --install`). There are no third-party dependencies.

```bash
git clone https://github.com/ramamona/sip-and-stretch.git
cd sip-and-stretch
make test   # run the unit tests
make run    # build build/SipStretch.app and launch it
```

You can open the folder in Xcode (File → Open → `Package.swift`) or use any editor with SourceKit-LSP.

> **`swift run` vs `make run`:** `swift run SipStretch` is fine for quick UI iteration, but a bare executable has no bundle. System notifications, launch at login, and the `sipstretch://` URL scheme only work from the bundled app, so use `make run` whenever you touch those.

If the app is already running from `/Applications`, quit it first so you don't end up with two Drips in your menu bar.

## Make targets

| Target | What it does |
|---|---|
| `make build` | Debug build (`swift build`) |
| `make test` | Run the unit tests (`swift test`, plus the swift-testing plugin path when you only have the Command Line Tools) |
| `make app` | Release build, assembled into `build/SipStretch.app` by `scripts/bundle.sh` (ad-hoc signed) |
| `make run` | `make app`, then launch it |
| `make install` | `make app`, then copy it to `/Applications` |
| `make zip` | Package a universal (arm64 + x86_64) app as `dist/SipStretch-<version>.zip` |
| `make release` | Universal, Developer ID-signed and **notarized** zip (see [docs/RELEASING.md](docs/RELEASING.md)) |
| `make icon` | Regenerate `Support/AppIcon.icns` and `docs/icon.png` from `scripts/make-icon.swift` |
| `make snapshots` | Regenerate `docs/screenshots/*.png` (runs the app with `--snapshots docs/screenshots`) |
| `make clean` | Remove build outputs |

## How the code is organised

- **`Sources/SipStretchCore`** holds pure logic: scheduling, active hours, DND, stats, achievements, personalities, messages, stretches. **No UI imports** (no SwiftUI, AppKit, or UserNotifications), just Foundation. That keeps it fast and easy to test.
- **`Sources/SipStretch`** is the app: `AppModel` (the `@Observable`, `@MainActor` source of truth) and persistence in `App/`, services (notifications, sound, presence, login item), nudge cards, and SwiftUI views.
- **`Tests/SipStretchCoreTests`** has the tests, written with [swift-testing](https://github.com/swiftlang/swift-testing) (`import Testing`, `@Test`, `#expect`), **not** XCTest.

See the [Architecture section of the README](README.md#-architecture) for the full picture.

## Code style

- **Match the surrounding code.** Consistency beats personal preference.
- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/): clear names, no abbreviations, and doc comments (`///`) on public API.
- **Use `@ViewState`, not `@State`.** With the macOS 27 SDK, SwiftUI's `@State` is a macro whose compiler plugin ships with Xcode but not with the Command Line Tools, so `@State` breaks the build for anyone without Xcode. [`@ViewState`](Sources/SipStretch/Views/Components/ViewState.swift) is a drop-in replacement (same syntax, same behaviour), and CI fails if `@State` sneaks in. The same goes for `#Preview`, `@Entry` and `@Animatable`.
- **Keep `SipStretchCore` free of UI imports.** If logic needs the clock, a random number generator, or the calendar, pass it in as a parameter so tests can control it. Don't reach for globals.
- **Logic change? Add a test.** Any behaviour change in `SipStretchCore` should come with a swift-testing test that fails without your change. Time math (active hours, DND, overnight windows, weekdays) especially needs one.
- Keep views small. If a view starts making decisions, move the decision into the core or the model.
- No new dependencies without discussing it in an issue first.
- Keep all copy family-friendly and kind. Drip can tease, but never shame.

## Recipes

### 🎭 Add a personality

1. Add a case to the `Personality` enum in [`Sources/SipStretchCore/Personality.swift`](Sources/SipStretchCore/Personality.swift) and fill in its `displayName`, `emoji`, and `tagline` (the compiler will point you to each `switch`).
2. Add a matching `MessagePack` in [`Sources/SipStretchCore/Messages.swift`](Sources/SipStretchCore/Messages.swift) with lines for every category: water reminders, stretch reminders, water cheers, stretch cheers, snoozes, greetings, and goal reached.
   - Use `{name}` for the user's nickname (it falls back to "friend") and `{left}` for glasses left today (water lines only).
   - A few lines per category is plenty. Variety is what keeps it fun.
3. Run `make test`. The tests check that **every personality has a non-empty pack for every category**, so a missing category fails the build.
4. Add the personality to the table in the README.

Not ready to code it? Pitch it with the **"New Drip personality"** issue template.

### 🧘 Add a stretch

1. Add a `Stretch` to `StretchLibrary.all` in [`Sources/SipStretchCore/StretchLibrary+Data.swift`](Sources/SipStretchCore/StretchLibrary+Data.swift).
2. Give it a **unique `id`** (kebab-case, e.g. `"seated-figure-four"`). Ids are stored in history, so never rename an existing one.
3. Pick its `area` (`BodyArea`: neck, shoulders, back, wrists, legs, eyes), an emoji, a duration in `seconds`, and `steps`: one or two short sentences in the imperative voice.
4. Keep it **gentle and desk-friendly**: nothing that needs a floor, equipment, or bouncing, and nothing that should hurt.
5. Run `make test`, then try it: set **Stretches per break** to 5 make your stretch's area the only focus area, and hit **Now** on the stretch ring.

### 💪 Add a mini challenge, walk idea or posture tip

All in [`Sources/SipStretchCore/Breaks.swift`](Sources/SipStretchCore/Breaks.swift): add to `Challenge.all` (unique id; either `reps` or a timed `seconds`, not both), `BreakPlanner.walkIdeas`, `BreakPlanner.eyeTips` or `BreakPlanner.postureItems`. Keep them doable at a desk in regular clothes.

### 🃏 Add a new stretch format

1. Add a case to `StretchFormat` and plan it in `BreakPlanner.plan` (both in `Breaks.swift`), plus a `BreakActivity` case if it needs new data.
2. Add its view to [`Sources/SipStretch/Nudge/BreakViews.swift`](Sources/SipStretch/Nudge/BreakViews.swift): it gets the card area and calls `done` when finished.
3. Route it in `NudgeCardView` (`summary`, `primaryLabel`, `start`, and the `content` switch). The compiler lists every spot.
4. Add it to the snapshot list in `Dev/Snapshots.swift` and run `make snapshots`.

### 🎨 Add a theme

1. Add a case to the theme enum in `Sources/SipStretchCore/Settings.swift` (next to `ocean`, `sunset`, `mint`, `grape`, `bubblegum`).
2. Add its gradient stops to `Theme.hexStops` in the same file (the `switch` won't compile until you do). If the lighter stop is pale, also add the theme to the dark-text list in `Theme.onPrimary` (`Sources/SipStretch/Views/Components/Styles.swift`) so button labels stay readable.
3. Check it in light **and** dark mode, then regenerate the screenshots if it's the default.

### 🌍 Translate

Localization isn't wired up yet (it's on the roadmap). If you want to lead it, open an issue first so we can agree on the approach before anyone translates hundreds of lines.

### 🖼 Regenerate the icon and screenshots

```bash
make icon        # rewrites Support/AppIcon.icns from scripts/make-icon.swift
make snapshots   # rewrites docs/screenshots/*.png from the real views
```

Commit the regenerated files together with the change that caused them. If your PR changes the UI, please run `make snapshots` and include the updated screenshots.

## Commits and pull requests

- **Open an issue first** for anything bigger than a small fix, so nobody wastes a weekend.
- Branch from `main`, keep PRs **focused** (one feature or fix each), and keep commits readable.
- Write commit messages in the imperative mood: `Add Gym Bro goal lines`, `Fix overnight window on Sundays`. [Conventional Commits](https://www.conventionalcommits.org/) prefixes (`feat:`, `fix:`, `docs:`) are welcome but optional.
- Before you open the PR:
  - [ ] `make test` passes
  - [ ] `make app` builds and the app runs
  - [ ] UI changes include screenshots (or updated `docs/screenshots`)
  - [ ] User-facing changes have an entry under **[Unreleased]** in [CHANGELOG.md](CHANGELOG.md)
- CI runs `swift build`, `make test`, an `@State` check, and `make app` on every push and pull request to `main`.

## Release process (maintainers)

Signing and notarization setup is in [docs/RELEASING.md](docs/RELEASING.md).


1. Bump `CFBundleShortVersionString` (and `CFBundleVersion`) in `Support/Info.plist`.
2. In `CHANGELOG.md`, move the **[Unreleased]** entries into a new `## [X.Y.Z] - YYYY-MM-DD` section and update the compare links at the bottom.
3. Commit (`Release vX.Y.Z`), then tag and push:
   ```bash
   git tag vX.Y.Z
   git push origin main vX.Y.Z
   ```
4. The [release workflow](.github/workflows/release.yml) runs `make zip` and creates a GitHub Release for the tag with `dist/SipStretch-X.Y.Z.zip` attached and auto-generated notes. Edit the notes if you like.

## Reporting security issues

Please **don't** open a public issue. See [SECURITY.md](SECURITY.md).
