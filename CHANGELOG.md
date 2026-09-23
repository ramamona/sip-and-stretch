# Changelog

All notable changes to Sip & Stretch are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-09-23

The first release. Say hi to Drip! 💧

### Added

- Menu bar app (no Dock icon) with a popover: Drip the mascot with moods, a greeting, level + XP bar, an animated water bottle with +1 / -1 glass, streak flame, stretches today, and countdown rings for the next water and stretch reminder with **Now** and **Skip**.
- Menu bar display options: icon only, countdown to the next reminder, or water progress (`3/8`). Shows a moon during Do Not Disturb.
- Floating, animated nudge cards that don't steal keyboard focus, shown at a configurable screen corner and queued when several are due. Water card: Drank it! / Snooze / Skip. Stretch card: a guided routine of 1–5 stretches with countdown rings, ending in confetti.
- Delivery as nudge card, macOS system notification (with actionable buttons), or both, falling back to cards if notification permission is denied.
- Per-reminder system sound with preview, and optional reminders read aloud.
- 8 personalities (Cheerful Coach, Sassy Bestie, Captain Hydro, Zen Master, Dramatic Narrator, Robo Buddy, Grandma, Gym Bro) with nickname support, and 5 themes (Ocean, Sunset, Mint, Grape, Bubblegum).
- Customisation: per-reminder enable, interval (15 min – 3 h), snooze length and sound; daily water goal, glass size, ml/oz; stretches per break; stretch focus areas.
- Active hours with start/end time (overnight windows supported) and active weekdays.
- Do Not Disturb with 30 min / 1 h / 2 h / until tomorrow / until turned off presets, a catch-up nudge after DND ends, and persistence across restarts.
- Away detection (screen lock, sleep, idle threshold): reminders hold while you're away, and coming back resets the stretch, eye and walk timers.
- Gamification: XP, levels from Dusty Cactus 🌵 to Ocean Overlord 🌊, daily water-goal streak, 13 achievements, and a 14-day history chart.
- Launch at login.
- Accessibility: Reduce Motion support, VoiceOver announcements for new cards, labelled custom controls.
- `sipstretch://` URL scheme for Shortcuts and scripts (drink, undo-drink, remind/water|stretch|eyes|walk, dnd, settings).
- Eye-break reminder (20-20-20, every 20 min) with a 20-second countdown card.
- Walk reminder (every 2 h) with walk ideas.
- Five stretch-break formats: guided stretches, stretch roulette, box breathing, mini challenges (rep counter / timed holds) and a posture check.
- Pause for meetings: reminders wait while the camera or microphone is in use, and any card on screen tucks itself away.
- Daily water goal set in litres (default 3 L); glasses are derived from your glass size.
- Signed & notarized releases via `make release` and the Release workflow (see docs/RELEASING.md).
- 100% local storage in `UserDefaults`, with no network access and no analytics.

[Unreleased]: https://github.com/ramamona/sip-and-stretch/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ramamona/sip-and-stretch/releases/tag/v1.0.0
