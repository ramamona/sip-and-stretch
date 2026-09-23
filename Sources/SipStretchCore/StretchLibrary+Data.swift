import Foundation

// The desk-friendly stretch catalogue. Every stretch should be gentle, doable in regular clothes
// next to a desk, and described in one or two short imperative sentences.
// Ids are stable (they're stored in "recently done" history), so don't rename them.

extension StretchLibrary {
    public static let all: [Stretch] = [

        // MARK: Neck

        Stretch(
            id: "ear-to-shoulder", name: "Ear-to-Shoulder Tilt", emoji: "🦒", area: .neck, seconds: 30,
            steps: "Sit tall and slowly tip your right ear toward your right shoulder, then switch sides. Keep your shoulders relaxed and breathe slowly."
        ),
        Stretch(
            id: "chin-tucks", name: "Double-Chin Tucks", emoji: "🐢", area: .neck, seconds: 20,
            steps: "Sit tall and glide your chin straight back like you're making a double chin. Hold for a breath, release, and repeat gently."
        ),
        Stretch(
            id: "owl-turns", name: "Owl Turns", emoji: "🦉", area: .neck, seconds: 30,
            steps: "Slowly turn your head to look over your right shoulder, pause, then turn to the left. Only go as far as feels comfortable."
        ),
        Stretch(
            id: "yes-no-nods", name: "Yes & No Nods", emoji: "🙆", area: .neck, seconds: 20,
            steps: "Nod a slow, small \"yes\" a few times, then shake a slow, small \"no\". Keep every movement soft, never jerky."
        ),
        Stretch(
            id: "half-moon-neck-roll", name: "Half-Moon Neck Roll", emoji: "🌙", area: .neck, seconds: 30,
            steps: "Drop your chin toward your chest and slowly sweep it from shoulder to shoulder in a half circle. Skip the backward roll and breathe easy."
        ),

        // MARK: Shoulders

        Stretch(
            id: "shoulder-rolls", name: "Shoulder Rolls", emoji: "🔄", area: .shoulders, seconds: 20,
            steps: "Roll your shoulders up, back, and down in big slow circles, then reverse direction. Breathe out each time they drop."
        ),
        Stretch(
            id: "cross-body-hug", name: "Cross-Body Hug", emoji: "🤗", area: .shoulders, seconds: 30,
            steps: "Bring your right arm across your chest and gently hug it closer with your left hand. Hold without bouncing, then switch arms."
        ),
        Stretch(
            id: "doorway-chest-opener", name: "Doorway Chest Opener", emoji: "🚪", area: .shoulders, seconds: 40,
            steps: "Rest your forearms on each side of a doorway and lean forward slightly until your chest feels a gentle stretch. Keep breathing and don't push."
        ),
        Stretch(
            id: "shrug-and-drop", name: "Shrug & Drop", emoji: "🤷", area: .shoulders, seconds: 20,
            steps: "Lift your shoulders up toward your ears, hold for three seconds, then let them drop. Repeat and feel the tension melt away."
        ),
        Stretch(
            id: "seated-snow-angels", name: "Seated Snow Angels", emoji: "😇", area: .shoulders, seconds: 30,
            steps: "Sit tall with your arms bent like goalposts, then slowly slide them overhead and back down. Keep your ribs soft and breathe steadily."
        ),

        // MARK: Back

        Stretch(
            id: "seated-twist", name: "Seated Spinal Twist", emoji: "🌀", area: .back, seconds: 30,
            steps: "Sit tall, hold the back of your chair with your right hand, and gently turn your torso right. Breathe, then repeat on the left."
        ),
        Stretch(
            id: "desk-cat-cow", name: "Desk Cat-Cow", emoji: "🐈", area: .back, seconds: 30,
            steps: "With hands on your knees, inhale as you arch your back and lift your chest. Exhale as you round your spine and tuck your chin."
        ),
        Stretch(
            id: "side-bend-reach", name: "Rainbow Side Bend", emoji: "🌈", area: .back, seconds: 30,
            steps: "Reach your right arm overhead and lean gently to the left, then switch sides. Keep both hips on the chair and breathe into your ribs."
        ),
        Stretch(
            id: "seated-forward-fold", name: "Rag Doll Fold", emoji: "🙇", area: .back, seconds: 40,
            steps: "Scoot back from your desk, plant your feet, and slowly fold forward, letting your arms and head hang heavy. Roll up slowly when you're done."
        ),
        Stretch(
            id: "sky-reach", name: "Sky Reach", emoji: "☀️", area: .back, seconds: 20,
            steps: "Interlace your fingers, turn your palms up, and press them toward the ceiling. Grow tall, take a deep breath, and lower slowly."
        ),

        // MARK: Wrists

        Stretch(
            id: "prayer-stretch", name: "Prayer Stretch", emoji: "🙏", area: .wrists, seconds: 20,
            steps: "Press your palms together in front of your chest, then slowly lower them toward your waist until you feel a gentle stretch. Hold and breathe."
        ),
        Stretch(
            id: "wrist-circles", name: "Wrist Circles", emoji: "⭕", area: .wrists, seconds: 20,
            steps: "Make loose fists and slowly circle your wrists ten times in each direction. Keep your shoulders relaxed."
        ),
        Stretch(
            id: "finger-fans", name: "Finger Fans", emoji: "🖐️", area: .wrists, seconds: 15,
            steps: "Spread your fingers as wide as they'll go, hold for a few seconds, then curl them into a soft fist. Repeat a few times."
        ),
        Stretch(
            id: "tendon-glides", name: "Tendon Glides", emoji: "✊", area: .wrists, seconds: 30,
            steps: "Slowly move through five shapes: open hand, hook fist, full fist, tabletop, and straight fist. Go gently and repeat the sequence."
        ),
        Stretch(
            id: "stop-sign-stretch", name: "Stop Sign Stretch", emoji: "✋", area: .wrists, seconds: 30,
            steps: "Hold one arm out, palm forward like a stop sign, and gently pull your fingers back with your other hand. Hold, breathe, then switch."
        ),

        // MARK: Legs

        Stretch(
            id: "seated-hamstring-reach", name: "Seated Hamstring Reach", emoji: "🦵", area: .legs, seconds: 30,
            steps: "Sit near the edge of your chair, stretch one leg out with the heel down, and hinge forward from your hips. Hold without bouncing, then switch."
        ),
        Stretch(
            id: "ankle-circles", name: "Ankle Doodles", emoji: "🦶", area: .legs, seconds: 20,
            steps: "Lift one foot and slowly draw ten circles with your toes in each direction. Switch feet and keep it smooth."
        ),
        Stretch(
            id: "calf-raises", name: "Tiptoe Calf Raises", emoji: "🩰", area: .legs, seconds: 30,
            steps: "Stand behind your chair and hold it lightly, rise up onto your toes, then lower slowly. Repeat at a steady, comfortable pace."
        ),
        Stretch(
            id: "flamingo-quad-stretch", name: "Flamingo Quad Stretch", emoji: "🦩", area: .legs, seconds: 30,
            steps: "Hold your desk for balance, bend one knee, and gently hold that foot behind you. Keep your knees close together, then switch legs."
        ),
        Stretch(
            id: "figure-four", name: "Pretzel Hip Opener", emoji: "🥨", area: .legs, seconds: 30,
            steps: "Sit tall and rest your right ankle on your left knee, then lean forward slightly with a long back. Hold, breathe, and switch sides."
        ),

        // MARK: Eyes

        Stretch(
            id: "twenty-twenty-twenty", name: "20-20-20 Gaze", emoji: "🔭", area: .eyes, seconds: 20,
            steps: "Look at something about 20 feet (6 meters) away for 20 seconds. Let your eyes and face soften."
        ),
        Stretch(
            id: "palming", name: "Warm Palming", emoji: "🤲", area: .eyes, seconds: 45,
            steps: "Rub your palms together until warm, then cup them over your closed eyes without pressing. Breathe slowly and enjoy the darkness."
        ),
        Stretch(
            id: "figure-eight-tracking", name: "Figure-Eight Tracking", emoji: "♾️", area: .eyes, seconds: 20,
            steps: "Imagine a big sideways figure eight on the wall and slowly trace it with your eyes. Switch direction halfway through."
        ),
        Stretch(
            id: "blink-break", name: "Butterfly Blinks", emoji: "🦋", area: .eyes, seconds: 15,
            steps: "Blink slowly and fully ten times, then close your eyes and rest them for a few seconds."
        ),
        Stretch(
            id: "near-far-focus", name: "Near & Far Focus", emoji: "👁️", area: .eyes, seconds: 30,
            steps: "Hold up a thumb about arm's length away and focus on it, then shift focus to something across the room. Switch back and forth slowly."
        ),
    ]
}
