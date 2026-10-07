import Foundation

// Voices for the character avatars. Same rules as Messages.swift: under 110 characters, kind,
// no health claims, `{name}` anywhere, `{left}` only in water lines.
//
// These are fan-made homages: original lines written in the spirit of each character, not quotes
// from the games or films.

extension MessagePack {

    // MARK: - Kratos (gruff, terse, duty-bound)

    static let kratos = MessagePack(
        waterReminders: [
            "{name}. Water. Do not make me say it twice. 💧",
            "A warrior who ignores thirst falls before the battle begins. Drink.",
            "The gods cannot save a dry throat. Pick up the cup, {name}.",
            "{left} more glasses. We do not leave the fight unfinished. 🪓",
            "Drink. The day will not conquer itself.",
            "Hydrate. Then we move on.",
            "Your cup is not a decoration. Drink from it.",
            "Even I drink water, {name}. Do not argue.",
            "Thirst is a foe. Face it. 💧",
        ],
        stretchReminders: [
            "Rise. Your back is stiff as old stone, {name}.",
            "Stand. Stretch. We do not fight with locked shoulders.",
            "Roll your shoulders. Turn your neck. Slowly. 🪓",
            "Your chair is not a throne. Get up.",
            "A warrior trains the body, not just the mind. Stretch.",
            "Move. Stillness is for statues.",
            "Unbend your spine, {name}. Now.",
        ],
        waterCheers: [
            "Good. Again in an hour.",
            "Well done, {name}. The thirst is vanquished. 💧",
            "That is how it is done. {left} left.",
            "Hm. Not bad.",
            "Strong. Keep this discipline.",
            "You drink like a warrior. 🪓",
        ],
        stretchCheers: [
            "Better. Your body is no longer stone.",
            "Good. You are ready for the next battle, {name}.",
            "Discipline. That is what this is. 💪",
            "You moved well. I am… satisfied.",
            "The body obeys when it is trained. Well done.",
            "Enough. Back to the fight.",
        ],
        snoozes: [
            "Fine. I will return.",
            "Delay if you must, {name}. The thirst will wait. I will not.",
            "Rest. But do not forget.",
            "Hm. I will be back. 🪓",
            "A short pause. Do not make it a long one.",
        ],
        greetings: [
            "Ready, {name}?",
            "Another day. We face it together.",
            "Stay focused. Stay hydrated.",
            "I am here. Do not waste the day.",
            "Stand tall, {name}. 🪓",
            "The day begins. Drink first.",
        ],
        goalReached: [
            "The goal is met. You fought well today, {name}. 🏆",
            "Every glass. All day. I am… proud.",
            "Victory. Rest. You have earned it.",
            "A warrior's discipline. Well done. 🪓",
        ]
    )

    // MARK: - Kung Fu Panda (bouncy, enthusiastic, snack-obsessed)

    static let kungFuPanda = MessagePack(
        waterReminders: [
            "Time for water! Even legendary warriors stay hydrated between dumplings! 🥟",
            "Hey {name}! A sip now, awesomeness later. Let's gooo! 💧",
            "Your water bottle is calling. It sounds like a tiny, thirsty dragon. 🐉",
            "{left} glasses to go! That's, like, a whole steamer of dumplings of water! 💧",
            "Hydration is a kung fu secret. Okay, one of the secrets. Drink up!",
            "Sip break! Your inner warrior needs refuelling, {name}!",
            "Water first, noodles second. Okay, noodles right after. But water first! 🍜",
            "Even the mightiest panda needs a drink. Come on, join me! 🐼",
            "Training montage time: sip, sip, sip!",
        ],
        stretchReminders: [
            "Time to stretch like a champion! Ooh, the splits! …Maybe just a shoulder roll. 🐼",
            "Hey {name}, kung fu starts with a good stretch. Up we go!",
            "Your back is tighter than a dumpling wrapper! Let's loosen it up. 🥟",
            "Stretch time! Reach high like you're grabbing the last bun on the shelf!",
            "Warriors don't sit all day (okay, sometimes they nap). Stand and stretch!",
            "Wiggle, wobble, stretch! Your body will thank you, {name}!",
            "Let's do some stretching. Then maybe snacks. Mostly stretching!",
        ],
        waterCheers: [
            "Yes! That's the water-warrior spirit! 💧",
            "Awesome sip, {name}! Five stars! ⭐",
            "Glug glug glug! Dragon-warrior level hydration! 🐉",
            "Another glass! Only {left} left. You're unstoppable!",
            "That was legendary! Okay, a little legendary. Very legendary!",
            "Nice one! Gimme a paw bump! 🐾",
        ],
        stretchCheers: [
            "Wow, so bendy! You're basically a noodle master! 🍜",
            "That was awesome, {name}! Your body feels amazing, right?",
            "Stretch complete! Time to defend the inbox! 🥋",
            "Look at you, all loose and legendary! 🐼",
            "Ooh yeah! I felt that stretch from here! 🙌",
            "You did it! Reward yourself with a mental dumpling. 🥟",
        ],
        snoozes: [
            "No problem! I'll be back, probably with snacks. 🥟",
            "Okay, {name}! Rest up. I'll find you in a bit!",
            "Snoozed! Don't worry, I'll just practise my moves. 🥋",
            "Sure thing! A tiny break from the break. I get it. 🐼",
            "All good! I'll come back with more enthusiasm. Maybe more dumplings.",
        ],
        greetings: [
            "Hi {name}! Ready for an awesome day? 🐼",
            "Today is going to be legendary! (I can feel it!)",
            "Let's hydrate and stretch like heroes! 🥋",
            "Hey friend! Did somebody say dumplings? …No? Water then! 💧",
            "Awesome to see you, {name}!",
            "Good day, warrior! Let's do this. 🐼",
        ],
        goalReached: [
            "You did it! Water goal complete! Time for a dragon-sized celebration! 🐉",
            "Goal reached, {name}! That's a legendary hydration day! 🏆",
            "Wooo! Every single glass! I'm doing a victory belly bounce! 🐼",
            "Mission accomplished! You're the real deal, Dragon Hydrator! 🥋",
        ]
    )

    // MARK: - Monkey King (cheeky, boastful, playful)

    static let wukong = MessagePack(
        waterReminders: [
            "Even a Monkey King drinks! Heaven's rules are boring, but this one is good. 💧",
            "Sip, {name}! Hydration is the first of my seventy-two transformations. 🐵",
            "Hah! A glass of water awaits. Nearly as good as a peach of immortality. 🍑",
            "{left} glasses left. A trifle for one who can somersault across the sky!",
            "Drink, friend! A thirsty hero is a slow hero. 💧",
            "I have outwitted armies and still found time to drink. You can manage a glass!",
            "Your cup is empty. Fill it, quick as a cloud somersault! ☁️",
            "Even the clever need water, {name}. Especially the clever!",
            "Quench your thirst and your mischief will flourish! 🐒",
        ],
        stretchReminders: [
            "Stretch, {name}! Be nimble as a monkey. I would know. 🐵",
            "Leap from that chair! Well, rise gently. Then leap if you like!",
            "Your spine has become a rusty staff. Oil it with movement! 🪄",
            "Reach for the sky, like I did when I snuck off with the peaches. Higher! 🍑",
            "Shake out those shoulders! A stiff monkey is a caught monkey!",
            "Master of seventy-two transformations, yet you cannot touch your toes? Bend!",
            "Up, up, up! Even the heavenly court stands up now and then.",
        ],
        waterCheers: [
            "Ha! A worthy sip! 🐵",
            "Splendid, {name}! Another glass conquered!",
            "Hydration unlocked! {left} to go. Easy as somersaulting a cloud!",
            "You drink like a hero of old! 🌟",
            "Hee hee! Fine form, friend. 💧",
            "Another victory! Tell the heavens about it!",
        ],
        stretchCheers: [
            "Marvellous! Nimble as a monkey! 🐒",
            "Ha ha! You move almost as well as I do, {name}!",
            "Loose, light and ready for mischief! 🌀",
            "A flexible staff never snaps. Well stretched, {name}!",
            "Splendid! Now go and cause some productive trouble.",
            "Stretched like a true immortal! ✨",
        ],
        snoozes: [
            "Hmph, delay it then. I will return with a trick! 🐵",
            "Fine, {name}. I shall go play with the clouds meanwhile. ☁️",
            "Snoozed! Do not forget, or I shall reappear in a puff of smoke!",
            "Five winks for you. Then back to the adventure!",
            "Very well. A clever hero knows when to rest. But not for long!",
        ],
        greetings: [
            "Greetings, {name}! The Monkey King is at your service! 🐵",
            "Another day, another adventure! Let's go!",
            "Hah! I was just fetching peaches. What have I missed? 🍑",
            "Let us make today legendary, {name}!",
            "Ready to cause some productive mischief? 🐒",
            "Hello, friend! The clouds are lovely today. ☁️",
        ],
        goalReached: [
            "Goal complete! A feat worthy of the heavens! 🏆",
            "Ha ha! Every glass, {name}! You rival the immortals! 🍑",
            "Water goal conquered! Time for a triumphant somersault! ☁️",
            "Magnificent! Even the heavenly court would applaud! 🐵",
        ]
    )

    // MARK: - Hulk (loud, simple, big-hearted)

    static let hulk = MessagePack(
        waterReminders: [
            "HULK THIRSTY. YOU THIRSTY. DRINK WATER! 💧",
            "{name}! Hulk say: WATER NOW!",
            "Even Hulk drink water. Puny human drink too!",
            "{left} more glasses. HULK COUNT. YOU DRINK!",
            "Water good. Hulk like water. You like water. 💚",
            "Smash thirst! Drink!",
            "Hulk not smash today if you drink water.",
            "Cup empty? HULK SAD. Fill cup!",
            "Gulp gulp! Hulk watching, {name}!",
        ],
        stretchReminders: [
            "Hulk stretch! Back stiff like rock. Stand up, {name}!",
            "Sit too long. Hulk get bored. STRETCH!",
            "Reach sky! Like Hulk when jump!",
            "Roll shoulders. Smash stiffness! 💪",
            "Chair not friend. Stand!",
            "Hulk stretch, you stretch. Deal?",
            "Puny back hurt? Stretch fix!",
        ],
        waterCheers: [
            "Good! Hulk proud. 💚",
            "Yes! {name} strong like Hulk!",
            "Glass gone! {left} left. Keep going!",
            "HULK HAPPY! Drink more!",
            "Smash! Thirst defeated!",
            "Good human. Hulk give high five. ✋",
        ],
        stretchCheers: [
            "HULK LIKE! You bendy now!",
            "Good stretch! Hulk jump for joy!",
            "Muscles happy. Hulk happy! 💪",
            "Strong human! Hulk proud.",
            "Stretch done. Time to smash deadlines!",
            "{name} almost as flexible as Hulk. Almost.",
        ],
        snoozes: [
            "Hulk wait. But Hulk not happy.",
            "Okay. Hulk go smash something small.",
            "Later. Hulk come back LOUDER.",
            "Hulk patient. A little.",
            "Snooze? Hulk grumble…",
        ],
        greetings: [
            "Hulk here, {name}!",
            "Hulk guard your water today. 💚",
            "Good day to hydrate. And smash.",
            "Hulk and {name}, team!",
            "Puny human! …said with love.",
            "Hulk wake up. Hulk ready!",
        ],
        goalReached: [
            "WATER GOAL SMASHED! HULK PROUD! 🏆",
            "{name} did it! Hulk jump so high!",
            "Every glass! Hulk say: STRONGEST HUMAN!",
            "Victory! Hulk roar for you! 💚",
        ]
    )
}

/// Eye-break and walk lines for the character voices (see `Personality.eyeReminders` / `walkReminders`).
enum CharacterLines {
    static let kratosEyes = [
        "Look away from the screen. Far into the distance. Twenty seconds. 👀",
        "{name}. Eyes to the horizon. A warrior watches far, not just near.",
        "Twenty seconds. Twenty feet. No excuses.",
        "The screen will wait. Rest your eyes. Find something distant.",
        "Blink. Then look far. Your eyes are weapons. Keep them sharp. 🪓",
        "Even gods blink. Look away for twenty seconds.",
    ]

    static let kratosWalks = [
        "Stand. Walk. The chair has had enough of you.",
        "{name}. A short march. Five minutes. Go. 🚶",
        "A warrior who never walks becomes a statue. Move.",
        "Leave the desk. Walk to the far end of the hall and back.",
        "Walk it out. Clear your head. The work will wait. 🪓",
        "Every journey begins with standing up. Do it.",
    ]

    static let pandaEyes = [
        "Eye break! Look at something far away for 20 seconds, like a distant mountain! 🏔️",
        "Hey {name}, give those eyes a break! Look far, far away. Dumpling-shop far! 🥟",
        "20 feet, 20 seconds. Even eagle-eyed warriors need this! 🦅",
        "Blink, look away, breathe. Your eyes are heroes too! 👀",
        "Screen stare-down? Win by looking away. Check out the distance!",
        "Find the farthest thing you can see and give it a little wave. 👋",
    ]

    static let pandaWalks = [
        "Walk break! Let's go on an adventure! Okay, a short one. To the kitchen. 🚶",
        "{name}! Stretch those legs! Maybe walk past something delicious. Just look!",
        "A walk makes your brain happy! Come on, adventure time! 🐼",
        "That chair has been hugging you too long! Let's take a stroll!",
        "Kung fu is mostly walking to where the kung fu happens. Let's go! 🥋",
        "Five minutes of walking and you'll feel like a brand new panda! ✨",
    ]

    static let wukongEyes = [
        "Eyes up, {name}! Gaze far, like a hero with fiery golden eyes! 🔥",
        "20 seconds, 20 feet. Even my sharp eyes need a break from scrolling! 📜",
        "Look at the farthest cloud you can find. Hold it for twenty seconds! ☁️",
        "Blink! Gaze far! A monkey who stares at a screen all day misses all the mischief.",
        "Rest those eyes! Spot something distant and give it a nod. 👀",
        "The screen can wait. Look to the horizon, like a pilgrim on the road west. 🌄",
    ]

    static let wukongWalks = [
        "Time to wander! A monkey never sits still for hours. Up you go! 🐒",
        "Walk, {name}! Not a cloud somersault, but it will do. 🚶",
        "Stretch your legs, friend! Maybe find a peach tree. Or a water fountain. 🍑",
        "A pilgrim must walk to reach the West. Take a few steps, {name}!",
        "Off the chair! Go wander like a free spirit! 🌿",
        "Five minutes of walking. Think of it as a tiny journey. Go!",
    ]

    static let hulkEyes = [
        "Look far, {name}. Hulk see far. You see far. 20 seconds. 👀",
        "Screen make eyes tired. Look away! Twenty seconds!",
        "Hulk eyes break. You eyes break. Do it.",
        "Blink! Look far! Like looking for something to smash.",
        "Puny eyes need rest. Look at far thing!",
        "Far thing. Twenty seconds. HULK COUNT!",
    ]

    static let hulkWalks = [
        "Hulk walk! Stomp stomp! Come, {name}!",
        "Chair too soft. Walk now. 🚶",
        "Hulk jump around. You walk. Fair!",
        "Walk five minutes. Then smash emails.",
        "Legs for walking! Use legs!",
        "Stomp to kitchen and back. GO!",
    ]
}

// MARK: - Reactions: what a character says when you don't do the thing

extension Personality {
    /// Lines for a character that was skipped, snoozed, kept waiting, or gave up and left.
    /// Playful attitude, never mean. `{name}` works.
    public func reactionLines(_ reaction: AvatarReaction) -> [String] {
        switch (self, reaction) {
        case (.kratos, .skipped): [
            "You ignore me. Disappointing.",
            "Skipped. I expected more of you, {name}.",
            "Discipline fails. Do not let it become habit.",
            "Hmph. We will speak of this later.",
        ]
        case (.kratos, .snoozed): [
            "Later. Do not make me wait twice.",
            "Delay. Weakness. …Fine.",
            "I will return. Be ready.",
            "Time wasted is time lost.",
        ]
        case (.kratos, .impatient): [
            "I am still here, {name}.",
            "Do not make me wait.",
            "Silence. I am growing impatient.",
            "Answer. Now.",
        ]
        case (.kratos, .timedOut): [
            "Enough. I am leaving.",
            "You test my patience. I am done.",
            "No response. Then I go. Disappointed.",
            "I waited. You did not come. Remember this.",
        ]

        case (.kungFuPanda, .skipped): [
            "Aww, really? I walked all the way here! 🐼",
            "Skipped?! I had a whole kung fu routine!",
            "That's okay… I'm not crying, you're crying. 🥲",
            "No problem! (It's a little problem.)",
        ]
        case (.kungFuPanda, .snoozed): [
            "Later? Okay… I'll practise my moves.",
            "Snooze again? I'll go eat a dumpling. 🥟",
            "Fine! But I'll be back with extra enthusiasm!",
            "Sure! No pressure! (Slight pressure.)",
        ]
        case (.kungFuPanda, .impatient): [
            "Heeey, still here! Waving! 👋",
            "Psst… {name}? I've done all my stretches waiting.",
            "I could eat a dumpling in this time. I did. Twice.",
            "Hellooo? Panda waiting!",
        ]
        case (.kungFuPanda, .timedOut): [
            "I waited sooo long! I'm leaving! 😤",
            "No answer… I'm going to find some dumplings. 🥟",
            "Hmph! Panda out. Ask me nicely next time!",
            "I'm not mad, I'm just… leaving dramatically!",
        ]

        case (.wukong, .skipped): [
            "Hmph! You dismiss the Monkey King? Bold!",
            "Skipped? Do you know who I am?!",
            "A slight! I shall remember this, {name}. 🐒",
            "Fine. I have clouds to ride anyway.",
        ]
        case (.wukong, .snoozed): [
            "Later? A king waits for no one… but I will wait.",
            "Delay! Very well. I'll twirl my staff.",
            "Hmph. A little more of my patience.",
            "Later. But mischief awaits if you forget!",
        ]
        case (.wukong, .impatient): [
            "Do not keep a king waiting, {name}.",
            "I could have crossed the sky by now! ☁️",
            "Hellooo? My staff grows heavy.",
            "Tick tock. Mortal time is slow.",
        ]
        case (.wukong, .timedOut): [
            "Enough! I take my leave in a huff! ☁️",
            "Ignored! I shall cause trouble elsewhere. 🐵",
            "Hmph! The Monkey King departs!",
            "I waited ages. I'm off!",
        ]

        case (.hulk, .skipped): [
            "HULK SAD! You skip! HULK ANGRY!",
            "No?! HULK SMASH… something small. Not you.",
            "Hulk walked all way! You skip! GRR!",
            "Hulk disappointed. HULK DISAPPOINTED.",
        ]
        case (.hulk, .snoozed): [
            "Later?! Hulk wait. Hulk NOT happy.",
            "Hulk grumble. Grrr. Later.",
            "Okay. Hulk go smash rock. Back soon.",
            "Snooze bad. Hulk tell you.",
        ]
        case (.hulk, .impatient): [
            "HULK STILL HERE.",
            "Human? Hulk waiting. Hulk bored!",
            "Hulk tap foot. TAP. TAP.",
            "Hulk getting ANGRY.",
        ]
        case (.hulk, .timedOut): [
            "HULK LEAVE! HULK ANGRY! GRRR!",
            "No answer! HULK SMASH… door on way out!",
            "Hulk done waiting! HULK GO!",
            "Puny human ignore Hulk! HULK LEAVE!",
        ]

        case (.kratos, .enraged): [
            "ENOUGH. I will not be ignored again.",
            "You test me, {name}. Every skip is a debt.",
            "Again?! My patience is a thin chain.",
            "Do it. Now. Before I lose my temper.",
        ]
        case (.kungFuPanda, .enraged): [
            "That's it! I'm getting BIGGER and you're getting reminders!",
            "Skip, skip, skip! I'm a panda, not a doormat!",
            "I'm warning you: dumpling-powered anger! 🥟",
            "Okay, now I'm actually mad. Grr! 🐼",
        ]
        case (.wukong, .enraged): [
            "INSOLENT mortal! My staff grows with my wrath!",
            "Skip me once more and see my seventy-two transformations!",
            "You test the Monkey King's patience, {name}! 🐒",
            "Hmph! Bigger and angrier!",
        ]
        case (.hulk, .enraged): [
            "HULK GROWING! HULK ANGRY! DO THE THING!",
            "SKIP AGAIN? HULK GET BIGGER!",
            "HULK SAID DO IT! HULK NOT ASK TWICE!",
            "{name}! HULK SMASH PATIENCE!",
        ]
        case (_, .enraged): [
            "Seriously?! Again?!",
            "I'm getting really annoyed, {name}. 😤",
            "Every skip makes me bigger and angrier. Just saying.",
            "Do the thing. DO IT.",
        ]
        case (_, .skipped): [
            "Skipped? Okay… I'll just stand here. 😶",
            "Aww. That one counted for nothing.",
            "Fine. Fine! I'm not upset. (I'm a little upset.)",
            "Noted. I came all this way, {name}… 🥺",
        ]
        case (_, .snoozed): [
            "Later, then. I'll be back.",
            "Snooze again? Okay, but I'm watching. 👀",
            "Mm-hm. Sure. Later.",
            "I'll wait. But I'll sigh a little.",
        ]
        case (_, .impatient): [
            "Hello? Still here…",
            "I've been standing here a while, {name}. 👀",
            "Tap tap. Any time now?",
            "Hellooo? Your reminder is still waiting.",
        ]
        case (_, .timedOut): [
            "Okay, I'm leaving. I waited so long!",
            "No answer? I'll take my reminder and go. 😤",
            "Fine, I'm off. See you next time.",
            "Left on read. I'm going home. 😒",
        ]
        }
    }

    /// A short headline for the card when a character reacts (skipped or timed out).
    public func reactionTitle(_ reaction: AvatarReaction) -> String {
        switch (self, reaction) {
        case (.kratos, .enraged): "ENOUGH!"
        case (.kungFuPanda, .enraged): "That's it!"
        case (.wukong, .enraged): "INSOLENCE!"
        case (.hulk, .enraged): "HULK SMASH!"
        case (_, .enraged): "Seriously?!"
        case (.kratos, .timedOut): "Enough."
        case (.kratos, _): "Disappointing."
        case (.kungFuPanda, .timedOut): "I waited..."
        case (.kungFuPanda, _): "Aww, really?"
        case (.wukong, .timedOut): "Insolence!"
        case (.wukong, _): "Hmph!"
        case (.hulk, .timedOut): "HULK LEAVE!"
        case (.hulk, _): "HULK ANGRY!"
        case (_, .timedOut): "No answer?"
        case (_, _): "Aww, skipped?"
        }
    }
}
