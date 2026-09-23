import Foundation

// Lines for the eye-break and walk reminders, per personality. Same rules as Messages.swift:
// under 110 characters, kind, no health claims. `{name}` works; `{left}` doesn't belong here.

extension Personality {
    /// Shown after an eye break. Short and personality-neutral: the eyes did the work.
    public static let eyeCheers = [
        "Eyes refreshed! ✨",
        "Ahh, much better. Welcome back, eyeballs. 👀",
        "Twenty seconds well spent. 🌄",
        "Your eyes say thank you (they'd wave if they could). 👋",
        "Focus restored. Carry on, legend. 😎",
        "Blink, blink. Crisp and clear! 💎",
    ]

    public var eyeReminders: [String] {
        switch self {
        case .cheerful: [
            "Eye break! Look at something far away for 20 seconds. Your eyes will do a happy dance. 👀",
            "Hey {name}, give those hard-working eyes a little vacation. Look far, far away! 🌄",
            "20 feet, 20 seconds. You've got this! ✨",
            "Blink, breathe, look out the window. Tiny break, big refresh! 😊",
            "Your eyes have been amazing today. Let's give them a view! 🌳",
            "Quick eye stretch: find the farthest thing you can see and say hi to it. 👋",
        ]
        case .sassy: [
            "Babe. The screen will survive 20 seconds without you. Look away. 💅",
            "Your eyes asked me to file a complaint. Look at something far away, {name}.",
            "Staring contest with the monitor? You lost. Look out the window. 👀",
            "Blink. No, a real blink. Now look far away like you're in a music video.",
            "20 seconds of looking at literally anything else. I believe in you. Barely. 😌",
            "Those pixels aren't going anywhere. Your eyeballs deserve a view, honey.",
        ]
        case .pirate: [
            "Avast! Spy the far horizon, {name}, like a true lookout for 20 seconds! 🔭",
            "Eyes off the charts, matey! Gaze across the sea (or the room) a spell.",
            "Land ho? Dunno! Look far away and find out, ye scallywag. 🏴‍☠️",
            "A sailor's eyes need the horizon, not the glowin' rectangle. Look yonder!",
            "Blink like the wind be in yer face, then stare at somethin' distant. Arr!",
            "20 seconds in the crow's nest, crew! Eyes to the far shore. ⚓️",
        ]
        case .zen: [
            "The screen is near. The world is far. Rest your gaze on the far. 🪷",
            "Twenty seconds of distance is a small journey for the eyes, {name}.",
            "Look at the farthest thing you can see. Let it look back.",
            "Soft eyes, slow blink. Nothing on the screen needs you right now.",
            "The mountain does not stare at the monitor. Be the mountain. 🏔️",
            "Let your gaze travel where your feet cannot. Just for twenty breaths' worth.",
        ]
        case .dramatic: [
            "And lo, {name} lifted their weary eyes from the glowing tablet toward the distant horizon…",
            "Twenty seconds. Twenty feet. The most daring quest of the afternoon begins NOW. 🎬",
            "The pixels held them captive for hours. But today, the eyes break free!",
            "A hush falls over the office as our hero gazes, heroically, out the window.",
            "Their eyes had seen too much spreadsheet. It was time to see the world. 🌍",
            "In a world of screens, one person dared to look… far away.",
        ]
        case .robot: [
            "BEEP. OCULAR COOLDOWN REQUIRED. FOCUS ON OBJECT ≥ 6 METRES FOR 20 SECONDS. 👀",
            "SCREEN STARE DURATION: EXCESSIVE. INITIATING 20-20-20 PROTOCOL.",
            "HELLO {name}. PLEASE REDIRECT OPTICAL SENSORS TO DISTANT TARGET.",
            "BLINK RATE BELOW OPTIMAL. RECOMMEND: BLINK. LOOK FAR. BLINK AGAIN. 🤖",
            "RECALIBRATING HUMAN LENSES… LOOK AWAY FROM DISPLAY TO CONTINUE.",
            "EYE BREAK SCHEDULED. RESISTANCE IS NOT RECOMMENDED. BOOP.",
        ]
        case .grandma: [
            "Sweetheart, you'll go square-eyed! Look out the window for a little bit. 👵",
            "{name}, dear, rest your eyes a moment. Look at the trees, they're lovely today.",
            "In my day we looked at the horizon, not little glowing boxes. Try it, dear!",
            "Blink a few times for Grandma, and look at something far away. There we go. 💕",
            "Your poor eyes! Twenty seconds looking far off. I'll wait right here.",
            "Look away from that screen, dear, and tell me what you can see outside.",
        ]
        case .gymBro: [
            "Eye day, bro! 20-second rep of looking far away. Let's GO! 👀💪",
            "{name}, your eyeballs need recovery too. Look across the room, king.",
            "Rest set for the eyes, bro. Horizon. Twenty seconds. No skipping.",
            "Blinks are reps. Hit a few, then lock eyes on something distant. 🔥",
            "You can't grind the screen 24/7, bro. Eyes need a deload. Look far!",
            "Twenty feet, twenty seconds, twenty percent more gains (in vibes). 💯",
        ]
        }
    }

    public var walkReminders: [String] {
        switch self {
        case .cheerful: [
            "Walk break! A few minutes on your feet is a gift to future you. 🚶",
            "Hey {name}, let's go for a little wander! Fresh steps, fresh ideas. 🌈",
            "Time to stretch those legs for real. Even a lap of the room counts! 😊",
            "Up you get! A short walk is one of the best breaks there is. ☀️",
            "Your legs have been so patient. Let's take them somewhere! 👟",
            "A tiny walk now, a happier afternoon later. Let's go! 🎉",
        ]
        case .sassy: [
            "You've been sitting so long the chair has your outline. Walk, {name}. 💅",
            "Go take a little strut. Pretend it's a runway. It kind of is.",
            "Legs: remember those? Take them for a walk before they file for divorce.",
            "A walk. Five minutes. You can even bring your phone, drama queen. 🚶",
            "Your step count is giving 'houseplant'. Let's fix that.",
            "Get up and walk somewhere. Anywhere. The fridge doesn't count. Okay, it counts.",
        ]
        case .pirate: [
            "All hands on deck, {name}! Stretch yer sea legs with a stroll! ⚓️",
            "Walk the plank! …Er, walk the hallway. Much safer, arr. 🏴‍☠️",
            "A pirate who never leaves the ship grows barnacles. Take a wander!",
            "Hoist yerself up and patrol the deck a spell, matey!",
            "Treasure won't find itself! Go explore a few paces, ye landlubber.",
            "Shore leave granted! Five minutes of walkin', then back to the helm.",
        ]
        case .zen: [
            "A walk is a meditation with scenery. Go find some. 🪷",
            "Each step arrives somewhere. Take a few, {name}.",
            "The river keeps moving. Be like the river, briefly, down the hallway.",
            "Walk slowly. Notice five things. Return renewed. 🍃",
            "Stillness is good. Stillness for three hours is a chair's life. Walk.",
            "Leave the desk. It will be exactly where you left it. Such is its nature.",
        ]
        case .dramatic: [
            "And so {name} rose from the chair, and set forth upon the great corridor… 🎬",
            "The quest: five minutes of walking. The stakes: an entire afternoon of vibes.",
            "Legend speaks of a traveller who walked to the far water fountain. Today, it's you.",
            "Our hero stood. The chair wept. The journey had begun.",
            "Behold! A walk of epic proportions (around the kitchen). 🏰",
            "The legs, long forgotten, awaken for their greatest role yet.",
        ]
        case .robot: [
            "BEEP. SEDENTARY TIMER EXCEEDED. DEPLOY LOCOMOTION MODULE. 🤖",
            "HELLO {name}. PLEASE RELOCATE YOUR CHASSIS FOR 5 MINUTES.",
            "STEP COUNTER REQUESTS INPUT. WALK TO GENERATE STEPS.",
            "PATROL ROUTE SUGGESTED: DESK → WINDOW → WATER → DESK. EXECUTE?",
            "LEG ACTUATORS IDLE FOR TOO LONG. RECOMMEND: WALK.",
            "WALK PROTOCOL ENGAGED. HUMANS FUNCTION BETTER WHEN MOBILE. BOOP.",
        ]
        case .grandma: [
            "Go get some fresh air, sweetheart. A little walk never hurt anybody. 👵",
            "{name}, dear, stretch those legs. Maybe pop outside, the sun's lovely.",
            "You've been sat there all day! Take a little stroll for Grandma. 💕",
            "A walk after a long sit, that's what my mother always said. Off you go!",
            "Go walk to the kitchen and back, dear, and have a biscuit while you're there.",
            "Up you get, love. Your legs need a little outing too.",
        ]
        case .gymBro: [
            "Cardio time, bro! Five-minute walk, let's GOOO! 🚶💪",
            "{name}, legs don't grow in a chair. Hit that walk, king.",
            "Active recovery, bro. Walk it out. Hydrate on the way.",
            "Steps are reps you can do in sneakers. Get some! 🔥",
            "Bro, we don't skip leg day. Not even walk day. MOVE!",
            "Quick stroll, big gains. Well, medium gains. Still gains. 💯",
        ]
        }
    }
}
