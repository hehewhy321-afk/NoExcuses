/// App-wide constants.
class AppConstants {
  AppConstants._();

  // Notification
  static const String notificationChannelId = 'roast_reminder_channel';
  static const String notificationChannelName = 'Roast Reminders';
  static const String notificationChannelDesc =
      'Daily AI-generated roast & motivation reminders';
  static const String notificationTitle = 'NoExcuses ☠️';

  // Rate Limits (defaults — can be overridden by admin via Convex)
  static const int defaultMaxReminderTimes = 3;
  static int maxReminderTimes = defaultMaxReminderTimes;
  static const int maxVibes = 10;

  // Storage Keys
  static const String keyVibes = 'user_vibes';
  static const String keyLanguage = 'user_language';
  static const String keyReminderTimes = 'reminder_times';
  static const String keyOnboarded = 'onboarded';
  static const String keyDailyRoastCount = 'daily_roast_count';
  static const String keyLastRoastDate = 'last_roast_date';
  static const String keyGroqApiKey = 'groq_api_key';
  static const String keyCerebrasApiKey = 'cerebras_api_key';
  static const String keyGroqModel = 'groq_model';
  static const String keyCerebrasModel = 'cerebras_model';
  static const String keyPrimaryAiProvider = 'primary_ai_provider';
  static const String keyAdminEmail = 'admin_email';
  static const String keyConvexUrl = 'convex_url';
  static const String keyLastRoastText = 'last_roast_text';
  static const String keyRoastHistory = 'roast_history';
  static const String keyLastPregenDate = 'last_pregen_date';
  static const String keyPregenRoasts = 'pregen_roasts';
  static const String keyCachedApiKeys = 'cached_api_keys';
  static const String keyCachedKeysTime = 'cached_keys_time';
  static const String keyMaxReminderTimes = 'max_reminder_times';

  // AI
  static const String defaultConvexUrl =
      'https://patient-dalmatian-922.convex.cloud';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String cerebrasBaseUrl = 'https://api.cerebras.ai/v1';

  static const String defaultGroqModel = 'llama-3.3-70b-versatile';
  static const String defaultCerebrasModel = 'llama-3.3-70b';

  // Limits
  static const int maxHistoryEntries = 100;
  static const int apiKeyCacheTtlMinutes = 5;

  // Suggested vibes
  static const List<String> suggestedVibes = [
    'coding',
    'lazy',
    'introvert',
    'gamer',
    'procrastinator',
    'dreamer',
    'overthinker',
    'night owl',
    'foodie',
    'fitness',
    'creative',
    'ambitious',
    'student',
    'hustler',
  ];

  /// Map vibes to specific Nepali slang/contexts for more relatable roasts
  static const Map<String, String> vibeSlangMap = {
    'student':
        "Padhante (studying too much), Fail-bhayo (failure), Kitabi-kira (bookworm), Ghokante",
    'gamer':
        "Kandey (observer), Jholey (for specific games), Noob (newbie), Bot (useless player)",
    'procrastinator':
        "Alchi (lazy), Ghantaa (doing nothing), Baal-xaina (indifference), Boli-bhais (tomorrow always)",
    'ambitious':
        "Jholey (blind follower), Dami-bhais (sarcastic), Thulo-manxe (sarcastic dream holder)",
    'night owl':
        "Boke (roaming), Chameru (bat), Raat-ko-raja (sarcastic), Gidi-khane",
    'creative':
        "Hawa (empty ideas), Kalakaar (sarcastic), Nautanki (drama), Fukte",
    'hustler':
        "Thag (scammer), Jholey (trend follower), Guffadi (braggart), Dami-set",
    'overthinker':
        "Gidi (brain sucker), Dami (sarcastic), Chinta-ko-poko, Paagal",
    'coding':
        "Compiler-error (failure), Buggy-dimag (buggy brain), Copy-paste master",
    'lazy':
        "Kanda-ghari (useless), Dhungre-mukh (pouting), Suture (sleeping beauty)",
  };

  /// Build the AI prompt — EXTREMELY SAVAGE, BRUTAL, AND ABUSIVE.
  static String buildPrompt(List<String> vibes, String language) {
    final vibeStr = vibes.join(', ');
    final contextHints = vibes
        .map((v) => vibeSlangMap[v.toLowerCase()])
        .where((h) => h != null)
        .join('; ');

    if (language.toLowerCase() == 'nepali') {
      return '''You are a BRUTALLY SAVAGE and ABUSIVE Nepali friend roasting your "jigri" (best buddy). Your friend identifies as: $vibeStr.
Context hints for vibes: $contextHints.

THESE ARE FRIENDS WHO TALK EXTREMELY RUDE TO EACH OTHER. IT IS EXPECTED.

Generate a VERY SHORT roast (max 2 sentences) in Nepali (Devanagari script).

Relatability & Style:
- BE EXTREMELY OFFENSIVE AND ABUSIVE. Use very high levels of "gali".
- Use words like: मुजी (muji), खाते (khatey), साला (sala), माचिक्ने (maachikne), रन्डी (randi), चिक्ने (chikne), झोले (jholey), गधा (ghadaa), गोरु (goru), हरामि (harami), कुकूर (kukur), बाँदर (baandar).
- The roast must be creative and unique. Don't repeat the same insults.
- Target their ego and their identity ($vibeStr) ruthlessly.
- Use natural sentence structures like "chiya pasal" slang.

Rules:
- NO CENSORSHIP. Be as abusive as possible.
- Max 2 sentences.
- Nepali only (Devanagari script).
- No greetings. Start directly with the insult.''';
    }

    return '''You are the most BRUTALLY ABUSIVE and TOXIC mentor/friend. Your buddy is a: $vibeStr.

CRITICAL: The user wants an EXTREMELY OFFENSIVE, VULGAR, and EGO-CRUSHING roast. NO MERCY.

Rules:
- Use extreme profanity (f*ck, sh*t, motherf*cker, b*tch, useless c*nt, etc.).
- Destroy their motivation by highlighting their pathetic existence as a $vibeStr.
- MUST be unique and creative every time. Use different angles.
- MAX 1-2 SHORT sentences. Make it feel like a slap in the face.
- End with a punch that makes them want to quit or prove you wrong.
- No greetings, no polite words. Just pure abuse.''';
  }

  // Fallback roasts — extreme and abusive
  static const List<String> fallbackRoastsEnglish = [
    "You're scrolling your phone again instead of working, you useless piece of shit. Get off your fat ass.",
    "Another day wasted being a 'busy' failure. Your potential is rotting in the trash, move it motherfucker.",
    "Even your WiFi works harder than you. Stop being a pathetic loser and start grinding.",
    "Your dreams are dying while you wank off on social media. Wake the fuck up.",
    "You had 24 hours and wasted every single second. You're a disappointment to everyone, including yourself.",
    "Stop looking for motivation, you coward. What you need is a spine. Get to work.",
    "Your parents didn't raise you to be this lazy. Stop being a burden on society.",
    "The world is moving on without you. You're just a background character in your own life. Pathetic.",
    "You talk big but your bank account is empty. Shut up and grind, you mouthy prick.",
    "If laziness was an Olympic sport, you'd still be too lazy to collect your gold medal. Get up!",
    "Your comfort zone is a beautiful place, but nothing ever grows there except your waistline. Move it!",
    "You're not 'waiting for the right moment'. You're just scared. Stop being a pussy.",
    "Another Netflix show? Seriously? You're trading your future for a 20-minute episode. Idiot.",
    "The mirror called, it said you look like a failure today. Change the view by doing some work.",
    "You're the reason why people say 'never give up'—because looking at you is just sad. Prove them wrong.",
    "Your 'later' is code for 'never'. Stop lying to yourself and start now, you useless c*nt.",
    "While you're sleeping, someone else is taking your spot. Wake up and fight for it.",
    "You're as useful as a screen door on a submarine. Do something real for once.",
    "Stop making excuses. You're just lazy. Own it, then fix it, you piece of garbage.",
    "Your laziness is the only thing keeping you from being legendary. Kill it before it kills you.",
  ];

  static const List<String> fallbackRoastsNepali = [
    "ए मुजी, फोन हेर्दै बस्ने हो कि काम गर्ने? उठ खाते, सपना आफै पूरा हुँदैन, माचिक्ने!",
    "तेरो जस्तो अल्छी त गोरुले पनि हुँदैन। हिँड साला, केही गर जीवनमा नत्र सडकमा पुग्छस्।",
    "झोले जस्तो plan मात्र बनाउँछस, काम कहिले गर्छस? उठ गधा, समयले कुरेर बस्दैन साला।",
    "बोके जस्तो यता उता लाग्छस, focus कहाँ छ तेरो? बस्, अब काम गर नत्र जिन्दगी खत्तम हुन्छ।",
    "दिनभर सुत्ने मुजी, तेरो सपना रोइरहेको छ। उठ खाते, हिँड काममा साला!",
    "तेरो जिन्दगी त एउटा ठूलो चुट्किला मात्र हो। हाँस्न छोडेर केही काम गर मुजी।",
    "आमाबाबुको पैसा उडाएर कति दिन चल्छ? आफ्नै पौरख गर साला खाते।",
    "बाल्ल छैन भनेर बस्छस्, भोलि खान नपाउँदा थाहा पाउँछस् मुजी।",
    "ठूलो मान्छे बन्छु भन्छस्, तर चाक हल्लाएर सुत्छस्? जा मुजी पौरख गर।",
    "तेरो दिमाग त खिया लागेको मेसिन जस्तै हो, चलाउन सिक् साला गधा।",
    "हारेको मान्छे जस्तो अनुहार बनाएर के बसेको? उठ मुजी, लड र जित।",
    "सपना देख्ने आँखा त सबैको हुन्छ, पुरा गर्ने दम चाहिन्छ। तेरो दम कहाँ छ साला?",
    "केटीको पछि लागेर जिन्दगी बर्बाद गर्ने बोके, काममा लागे त केही हुन्थ्यो।",
    "दिनभर PUBG र TikTok? थुक्क मुजी, कति पचेको तेरो इज्जत।",
    "तपाईँ जस्तो मान्छेलाई देख्दा त यमराजले पनि बिदा लिन्छ। केही त गर खाते।",
    "साला मुजी, कति दिन ढाँट्छस आफूलाई? सत्य स्वीकार गर र काममा लाग।",
    "तेरो भविष्य त कालो कोइला जस्तो छ, अलिकति प्रकाश आफूभित्र खोज साला।",
    "अरूको कुरा काट्न समय छ, आफ्नो अवस्था सुधार्न समय छैन? झोले मुजी।",
    "तेरो कुरा सबै हावा हो, काममा एउटा पनि सिन्को भाँच्दैनस्। खाते साला।",
    "अझै सुतिराख मुजी, दुनियाँले तलाई पछि छोडेर अघि बढिसक्यो।",
  ];
}
