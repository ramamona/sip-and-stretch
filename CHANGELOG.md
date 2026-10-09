# Changelog

All notable changes to Sip & Stretch are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Imported models now move like people.** Models with a person-shaped skeleton (arms, legs, spine and head, in a T-pose, like the Kratos and Kung Fu Panda models) are posed joint by joint instead of being slid around as one rigid block: they lower their arms out of the T-pose, walk with knees, ankles and counter-swinging arms with a stride matched to the walking speed so feet don't skate, breathe and glance around while they wait, and stretch with you. The joints are found from the shape of the skeleton, not bone names. Models without such a skeleton keep the whole-body moves, and **Settings → Avatar → Move its arms and legs like a person** turns the new behaviour off.
- Every character's gestures were rewritten as keyframed clips with anticipation, follow-through and weight: Kratos coils, raises both hands overhead and chops (twice, harder the second time), Kung Fu Panda bows, drops into a horse stance, throws punches and a high kick, Hulk roars and smashes, the Monkey King crouches, scratches his head and leaps, everyone else waves. Celebrating, sulking, grumbling and the escalating tantrums are in character too, and skipping makes the tantrum faster and bigger. Impacts throw a ring of dust and jolt the ground.

### Added

- The skeleton animation engine (`Animation.swift`, `Motion.swift`, `MotionClips.swift`) lives in the testable core: keyframes with easing over a flat pose, a procedural walk, idle and stretch, and the gestures as plain text keyframes.
- `SIPSTRETCH_AVATAR_DEBUG=1` prints which bones were found in a model when you launch the app from a terminal.

- **A 3D avatar with attitude**: when a reminder is due it walks in from the bottom-right corner of the main screen only, performs its signature move, and stands under the nudge card. Finish the task and it celebrates and leaves happy; skip it and it sulks and storms off; ignore it and it gets steadily more impatient, then leaves angry after 10 minutes (configurable). It stretches along during guided stretches. Built with SceneKit from a few dozen primitives, capped at 15/24/30 fps, paused while standing still, and freed after it leaves. Honors Reduce Motion and never takes clicks or focus. New **Avatar** tab in Settings.
- Avatar characters: Drip, a customizable person (gender, skin tone, hair style and color, outfit and colors, accessories), Robo Buddy, and fan-made Kratos (axe and Blades of Chaos), Kung Fu Panda (kung fu), Wukong (staff) and Hulk (smash and jump), each with its own moves.
- Design an avatar from a photo: on-device face detection puts your face on the custom person and suggests skin tone and hair color. Nothing is uploaded.
- Import your own detailed 3D model (USDZ, DAE, SCN, OBJ) for any character, or as a separate avatar. A model replaces the built-in shapes but keeps the character's voice, and moves with the character's attitude (axe-chop lunges, punches and a spin kick, somersaults, smashes).
- Four new voices (Kratos, Kung Fu Panda, Monkey King, Hulk) with their own reminders, cheers, snoozes, greetings, card titles, eye/walk lines, and how they react when skipped, snoozed, ignored or timed out. Characters talk in their own voice by default (switch off to keep your chosen personality), and read-aloud speech uses a matching pitch and pace.
- Avatars stay alive while they wait: they breathe, shift their weight and look around at about 12 fps (switch to "Hold still" for zero CPU). Imported models walk with a forward lean, a twist, a roll and squash-and-stretch, and slam, hop and land with cartoon weight.
- Skipping, swiping away or ignoring a reminder irritates the avatar: it swells on the spot, then shows up 20% bigger and redder after every skip in a row (up to 1.8x), greets you with a scowl and, from the second skip, furious lines of its own. Doing a reminder resets it. Angry sulks are also louder: a roar, shockwaves, harder stomps and more head shaking.
- A list of imported models in Settings → Avatar with a Delete button for each (your original file is never touched).
- Avatar options: size, walking speed, patience, animation frame rate, idle behaviour. All of it persists with your other settings.
- Swipe a card toward the screen edge (trackpad or mouse drag) to dismiss it, like a notification banner.

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
