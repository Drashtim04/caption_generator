import '../models/caption_request.dart';
import '../models/caption_response.dart';

/// ---------------------------------------------------------------------------
/// CaptionEngine
/// ---------------------------------------------------------------------------
/// Locally generates captions based on [CaptionRequest] parameters.
///
/// Architecture notes
/// ------------------
/// • All generation logic is *pure Dart* – no network calls.
/// • When [CaptionRequest.useAI] is true the engine returns a placeholder
///   response; swap [_callAiApi] for a real HTTP call when you wire up the
///   backend.
/// • Styles are applied *sequentially* after base generation:
///   1. humanize  2. rhyming  3. savage / funny / romantic transformations
/// ---------------------------------------------------------------------------
class CaptionEngine {
  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Generate captions for the given [request].
  /// Returns at least 5 unique captions.
  Future<CaptionResponse> generate(CaptionRequest request) async {
    if (request.useAI) {
      return _callAiApi(request); // placeholder – expand later
    }
    return _generateLocally(request);
  }

  /// Transform a single [caption] into multiple styled variants.
  /// The original caption is NOT included in the result list.
  List<String> transformCaption(
    String caption,
    List<CaptionStyle> styles,
  ) {
    final results = <String>[];
    for (final style in styles) {
      final transformed = _applyStyle(caption, style);
      if (transformed != caption && !results.contains(transformed)) {
        results.add(transformed);
      }
    }
    return results;
  }

  // -------------------------------------------------------------------------
  // AI placeholder
  // -------------------------------------------------------------------------

  Future<CaptionResponse> _callAiApi(CaptionRequest request) async {
    // TODO: Replace with actual API call when backend is integrated.
    // Example:
    //   final response = await http.post(Uri.parse('$baseUrl/generate'), ...);
    //   return CaptionResponse(captions: jsonDecode(response.body)['captions']);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return CaptionResponse(
      captions: [
        '✨ [AI] Caption coming soon – connect your backend!',
        '🚀 [AI] Backend integration pending.',
      ],
      requestSummary: 'AI mode – ${request.category.name}',
    );
  }

  // -------------------------------------------------------------------------
  // Local generation
  // -------------------------------------------------------------------------

  CaptionResponse _generateLocally(CaptionRequest request) {
    final keywords = request.keywords.trim();
    final kwList = keywords.isEmpty
        ? <String>[]
        : keywords
            .split(RegExp(r'[,\s]+'))
            .map((k) => k.trim().toLowerCase())
            .where((k) => k.isNotEmpty)
            .toList();

    // 1. Pull base templates for the category.
    final basePool = _buildBasePool(request.category, request.length, kwList);

    // 2. Enforce uniqueness and generate extras if the pool is small.
    final unique = _deduped(basePool);
    final padded = _padToMin(unique, request.category, request.length, kwList);

    // 3. Apply style transformations (sequentially in logical order).
    final styled = _applyStyles(padded, request.styles);

    return CaptionResponse(
      captions: styled,
      requestSummary:
          '${request.category.name} · ${request.length.name} · "$keywords"',
    );
  }

  // -------------------------------------------------------------------------
  // Base pool builder
  // -------------------------------------------------------------------------

  List<String> _buildBasePool(
    CaptionCategory category,
    CaptionLength length,
    List<String> keywords,
  ) {
    final core = _coreTemplates(category, length);
    if (keywords.isEmpty) return core;

    // Weave the primary keyword into several templates.
    final primary = _capitalized(keywords.first);
    final keyworded = core.map((t) {
      if (t.contains('{{kw}}')) return t.replaceAll('{{kw}}', primary);
      // Optionally append keyword context to half the captions.
      return t;
    }).toList();

    // Add a few purely keyword-driven lines.
    keyworded.addAll(_keywordDrivenLines(category, length, keywords));

    return keyworded;
  }

  // -------------------------------------------------------------------------
  // Core templates per category × length
  // -------------------------------------------------------------------------

  List<String> _coreTemplates(CaptionCategory category, CaptionLength length) {
    switch (category) {
      case CaptionCategory.men:
        return _menTemplates(length);
      case CaptionCategory.women:
        return _womenTemplates(length);
      case CaptionCategory.savage:
        return _savageTemplates(length);
      case CaptionCategory.romantic:
        return _romanticTemplates(length);
      case CaptionCategory.funny:
        return _funnyTemplates(length);
      case CaptionCategory.aesthetic:
        return _aestheticTemplates(length);
      case CaptionCategory.travel:
        return _travelTemplates(length);
      case CaptionCategory.fitness:
        return _fitnessTemplates(length);
      case CaptionCategory.attitude:
        return _attitudeTemplates(length);
      case CaptionCategory.none:
        return _noneTemplates(length);
    }
  }

  // ---- MEN ----
  List<String> _menTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short:
        return [
          'Built different.',
          'No excuses.',
          'Stay hard.',
          'Grind over comfort.',
          'Earn it.',
          'Silent but deadly.',
          'Own the room.',
          'Less talk, more action.',
          '{{kw}} or nothing.',
          'Level up, always.',
        ];
      case CaptionLength.medium:
        return [
          'They said it couldn\'t be done. Watch me.',
          'The grind doesn\'t stop — neither do I.',
          'Confidence isn\'t arrogance; it\'s earned.',
          'Silence speaks louder than empty promises.',
          'Be the version of yourself they underestimated.',
          'Every setback is a setup for a stronger comeback.',
          '{{kw}} — that\'s the mission, not the motivation.',
          'Low-key moves, high-key results.',
          'Real men build; they don\'t just talk.',
          'Pressure makes diamonds — I\'ve been under pressure.',
        ];
      case CaptionLength.long:
        return [
          'They counted me out. I counted my reps, my hours, and my wins. '
              'Now the scoreboard speaks for itself.',
          'Success isn\'t given — it\'s forged in the hours nobody sees, '
              'in the sacrifices nobody claps for.',
          'A real man\'s strength isn\'t just physical. It\'s the discipline '
              'to show up even when motivation is long gone.',
          'Some chase trends. Some chase clout. I chase excellence — '
              'every single day, without apology.',
          '{{kw}} is more than a word for me. It\'s a standard I hold myself to '
              'when nobody\'s watching.',
          'The journey is long, the road is rough, but the man who keeps moving '
              'is the one who eventually arrives.',
        ];
    }
  }

  // ---- WOMEN ----
  List<String> _womenTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short:
        return [
          'She blooms in her own time. 🌸',
          'Soft but unbreakable.',
          'Radiant, always.',
          'She glows different. ✨',
          'Unapologetically her.',
          'Aesthetic and authentic.',
          'Living her best life.',
          '{{kw}} and loving it. 💫',
          'Grace under pressure.',
          'Pretty and purposeful.',
        ];
      case CaptionLength.medium:
        return [
          'She carries storms behind a smile and sunshine in her soul.',
          'Not just a pretty face — a force of nature.',
          'She decided to be the magic she always wanted to see. 🌙',
          'Elegance is when beauty meets intention.',
          'Behind every strong woman is herself — that\'s it, that\'s the post.',
          'She didn\'t come to compete; she came to create.',
          '{{kw}} is just her beginning — watch what comes next.',
          'Softness is not weakness; it takes strength to stay gentle.',
          'Her vibe is handcrafted — not for everyone, just for the right ones.',
          'She blooms where others forget to water themselves.',
        ];
      case CaptionLength.long:
        return [
          'She walks into a room and quietly rearranges the energy. '
              'No announcement needed — her presence says everything.',
          'There\'s something deeply beautiful about a woman who knows '
              'exactly who she is — unbothered, unfiltered, unmistakable.',
          'She is the poem that never needed an author. '
              'Written in kindness, signed in strength, illustrated in grace.',
          'She holds the universe in a glance and the ocean in a breath. '
              'She is not ordinary — she never was.',
          '{{kw}} is what she pours into everything — and you can feel it '
              'in every room she enters and every life she touches.',
          'Softness is her superpower. Resilience is her backstory. '
              'Beauty is the least interesting thing about her.',
        ];
    }
  }

  // ---- SAVAGE ----
  List<String> _savageTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short:
        return [
          'Too real for fakes.',
          'Stay mad.',
          'Unbothered. Period.',
          'Bite me.',
          'Not your type.',
          'Cut off and thriving.',
          '{{kw}}? Never heard of it.',
          'Classy until provoked.',
          'Selectively savage.',
          'Your loss, literally.',
        ];
      case CaptionLength.medium:
        return [
          'I don\'t hold grudges. I just remember facts and act accordingly.',
          'The audacity of some people to underestimate me — love that for them.',
          'My vibe is expensive. You can\'t afford the attitude.',
          'I don\'t compete. I don\'t even compare. I just glow.',
          'Darling, I\'m not the villain you needed — I\'m the plot twist.',
          'You peaked. I\'m still loading.',
          'They wanted me to fail. I turned that into fuel.',
          '{{kw}} is something I do, not something I prove to anyone.',
          'The only opinion that matters is mine — and I\'m impressed.',
          'Block me? Please. That\'s called protecting my energy.',
        ];
      case CaptionLength.long:
        return [
          'They underestimated me — big mistake. '
              'I don\'t argue, I don\'t explain, I just let the results '
              'do the talking. And they\'re loud.',
          'You spent more time watching me fail than I spent failing. '
              'Meanwhile, I leveled up while you were busy being a spectator.',
          'Not everyone deserves access to me. Not everyone gets the best version. '
              'The ones who do — they know how to treat it.',
          'They called it arrogance. I call it accurate self-assessment. '
              'The difference is the receipts I carry.',
          '{{kw}} isn\'t my goal — it\'s my default setting. '
              'The rest of the world is just catching up.',
          'I cut off people without drama, without explanation, and without regret. '
              'My peace is not up for negotiation.',
        ];
    }
  }

  // ---- ROMANTIC ----
  List<String> _romanticTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short:
        return [
          'You\'re my favorite daydream. 💭',
          'Still falling for you.',
          'Home is wherever you are.',
          'My person. Always.',
          'Love, simply. 🤍',
          '{{kw}} and you — perfect.',
          'You make the ordinary extraordinary.',
          'Forever sounds right.',
          'My heart chose you.',
          'Endlessly yours. 🌷',
        ];
      case CaptionLength.medium:
        return [
          'You didn\'t just walk into my life — you changed the direction of it.',
          'Every love song makes sense now that I have you.',
          'I found home in a person, and that person is you.',
          'The world gets quieter and more beautiful when you\'re near. 🌙',
          'Loving you feels like the most natural thing I\'ve ever done.',
          'You\'re not just my partner — you\'re my favorite adventure.',
          '{{kw}} reminds me of you — and that makes everything better.',
          'My heart skips a beat every time, like it\'s the first time.',
          'Some things are worth holding onto forever. You\'re one of them.',
          'With you, ordinary moments become my favorite memories.',
        ];
      case CaptionLength.long:
        return [
          'There are a million ways to say I love you. '
              'But in truth, every song I hum, every sunset I stop to notice, '
              'every warm cup of coffee — they all say it better.',
          'You came into my life so quietly, '
              'and yet the world has never been louder with color, warmth, and joy. '
              'Loving you is the easiest thing I\'ve ever done.',
          'I didn\'t know what forever meant until the thought of it without you '
              'became completely impossible. You are my forever.',
          'They write poems about moments like this — '
              'two people finding each other in the ordinary and turning it into '
              'something extraordinary. That\'s us.',
          '{{kw}} is the word that reminds me of everything we share — '
              'the laughs, the silences, the small moments that somehow '
              'hold the whole universe inside them.',
          'The world is so much gentler, so much warmer, so much more worth '
              'waking up to — simply because you\'re in it with me.',
        ];
    }
  }

  // ---- FUNNY ----
  List<String> _funnyTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short:
        return [
          'Send help. And snacks.',
          'Mood: buffering. 🔄',
          'Plot twist: I napped.',
          'Not lazy, just efficient.',
          'WiFi > people.',
          '{{kw}} was not my idea.',
          'Still figuring it out.',
          'My spirit animal is pizza.',
          'Adulting level: 2%.',
          'I tried. Sort of.',
        ];
      case CaptionLength.medium:
        return [
          'Woke up like this — confused, hungry, and mildly optimistic.',
          'My therapist said I need boundaries. The pizza place now closes at 10.',
          'I\'m not late — I\'m on my own timezone, and it\'s very exclusive.',
          'Running on caffeine, sarcasm, and the sheer will to not go back to bed.',
          'They said chase your dreams. Nobody mentioned the cardio.',
          'Currently accepting apologies for underestimating me. Line forms here.',
          '{{kw}} sounded like a great idea — until it wasn\'t.',
          'My vibe is "accidentally funny but too lazy to monetize it."',
          'Life is short. Eat the dessert first, explain later.',
          'I\'m not a morning person or an afternoon person. Just check back at 10 PM.',
        ];
      case CaptionLength.long:
        return [
          'They said "believe in yourself" — so I did, and now I\'m explaining '
              'to my bank account why I needed all of that. Still believe in myself though.',
          'My fitness journey: opened the fridge, assessed the situation, '
              'closed the fridge, ordered takeout. Progress is progress.',
          'Honestly I came here for the snacks and stayed for the chaos. '
              'If you see me looking focused, I\'m just thinking about lunch.',
          'I was told this would make sense when I grew up. '
              'I am an adult now and I have more questions than before.',
          '{{kw}} was supposed to be the responsible choice. '
              'But then things happened, and now I have a story I tell at dinner parties.',
          'Tried to get my life together this morning. '
              'Then I sat down for "just five minutes" and woke up three hours later. '
              'It\'s called self-care.',
        ];
    }
  }

  // ---- AESTHETIC ----
  List<String> _aestheticTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short: return ['Vibes ✨', 'Art.', 'Details.', 'Aesthetic.', 'Minimal.', 'Golden hour.', 'Lost in the details.', 'Just right.', '{{kw}} dreams.', 'Simply aesthetic.'];
      case CaptionLength.medium: return ['Finding beauty in the little things.', 'Aesthetic state of mind.', 'Chasing the golden hour.', 'Less is always more.', 'Curated moments.', 'Romancing my own life.', 'Details that matter.', 'Living for these aesthetics.', '{{kw}} hitting perfectly.', 'Lost in the art of living.'];
      case CaptionLength.long: return ['There is poetry in the everyday if you know how to look for it. Every detail matters.', 'Curating my life like a museum, finding the perfect balance between chaos and art.', 'Some moments are just so perfectly composed you have to stop and admire them.', 'The aesthetic is not just what you see, it is how it makes you feel inside.', 'Romanticizing the mundane until everything looks like a movie scene. Especially {{kw}}.', 'A quiet corner, a beautiful moment, a timeless memory captured forever.'];
    }
  }

  // ---- TRAVEL ----
  List<String> _travelTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short: return ['Out of office.', 'Wanderlust.', 'Next stop.', 'Exploring.', 'On the move.', 'Catch flights.', 'Lost here.', 'New views.', '{{kw}} vibes.', 'Away.'];
      case CaptionLength.medium: return ['Catching flights, not feelings.', 'Always take the scenic route.', 'Wander often, wonder always.', 'Collecting passport stamps and memories.', 'Let the adventure begin.', 'Finding a new home in every city.', 'The world is too big to stay in one place.', 'Leave nothing but footprints.', '{{kw}} and a one-way ticket.', 'Letting the compass guide me.'];
      case CaptionLength.long: return ['There is a whole world out there waiting to be explored, and I intend to see it all.', 'Travel is the only thing you buy that makes you richer. My soul is full.', 'We travel not to escape life, but for life not to escape us. Enjoying every second.', 'Every new destination brings a new perspective. I leave a piece of my heart everywhere.', 'The best stories are found between the pages of a passport. Adding a new chapter today with {{kw}}.', 'Getting lost in a new city is the best way to find yourself. The journey is the destination.'];
    }
  }

  // ---- FITNESS ----
  List<String> _fitnessTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short: return ['Work in progress.', 'Sweat it out.', 'No days off.', 'Push harder.', 'Beast mode.', 'Earned it.', 'Level up.', 'Stronger.', '{{kw}} gains.', 'Focus.'];
      case CaptionLength.medium: return ['Sore today, strong tomorrow.', 'Discipline over motivation.', 'The only bad workout is the one that did not happen.', 'Train like you have something to prove.', 'Excuses do not burn calories.', 'Pushing past the limits.', 'Sweat is just fat crying.', 'Hustle for that muscle.', 'Focusing on {{kw}} and getting better every day.', 'It never gets easier, you just get stronger.'];
      case CaptionLength.long: return ['Motivation is what gets you started. Habit is what keeps you going. Showing up is half the battle.', 'You are entirely up to you. Make your body the sexiest outfit you own.', 'It hurts now, but one day it will be your warm-up. Trust the process and keep grinding.', 'Do not stop when you are tired. Stop when you are done. Giving everything I have today.', 'The hardest lift of all is lifting your butt off the couch. Once you do that, {{kw}} is easy.', 'Fitness is not about being better than someone else. It is about being better than you used to be.'];
    }
  }

  // ---- ATTITUDE ----
  List<String> _attitudeTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short: return ['I do me.', 'Watch this.', 'Built different.', 'Unapologetic.', 'My rules.', 'Top tier.', 'Take it or leave it.', 'Not sorry.', '{{kw}} boss.', 'Next level.'];
      case CaptionLength.medium: return ['I am not bossy, I just know what I want.', 'They told me I could not, so I did.', 'I am the exception to the rule.', 'Do not study me, you will not graduate.', 'I am a vibe you can not find anywhere else.', 'Make them stop and stare.', 'Too glam to give a damn.', 'I don\'t follow trends, I set them.', 'With {{kw}} and this attitude, I am unstoppable.', 'Confidence level: Selfie with no filter.'];
      case CaptionLength.long: return ['I am currently under construction. Thank you for your patience, but the final result will be flawless.', 'Throw me to the wolves and I will return leading the pack. It is just in my nature.', 'People will stare. Make it worth their while. I am not here to blend in.', 'I am a limited edition, there is only one me. Treat me like the rare collectible I am.', 'They said I was too much, so I asked them to go find less. Embracing my {{kw}} and my energy.', 'I do not need your approval to be me. I am perfectly fine with my own vibe.'];
    }
  }

  // ---- NONE ----
  List<String> _noneTemplates(CaptionLength length) {
    switch (length) {
      case CaptionLength.short: return ['Just this.', 'Here.', 'Moments.', 'Today.', 'Life.', 'Uncaptioned.', 'Simply.', 'This.', '{{kw}}.', 'Yes.'];
      case CaptionLength.medium: return ['Just a simple moment captured.', 'No words needed for this.', 'Enjoying the little things.', 'Living in the present.', 'Just keeping it real.', 'A memory for the books.', 'Sometimes silence is the best caption.', 'Taking it all in.', 'Just {{kw}}.', 'Appreciating today.'];
      case CaptionLength.long: return ['There are moments in life that do not need a deep quote or a funny joke. Just this.', 'Capturing life as it happens, without overthinking the description. Just enjoying the view.', 'Some photos speak for themselves. This is one of them. Letting the moment breathe.', 'A simple snapshot of a good day. No filter, no crazy caption, just reality.', 'Sometimes the best thing you can say is nothing at all. Letting {{kw}} do the talking.', 'Here is a piece of my day. Unfiltered, unbothered, and uncaptioned.'];
    }
  }

  // -------------------------------------------------------------------------
  // Keyword-driven extra lines
  // -------------------------------------------------------------------------

  List<String> _keywordDrivenLines(
    CaptionCategory category,
    CaptionLength length,
    List<String> keywords,
  ) {
    if (keywords.isEmpty) return [];

    final primary = _capitalized(keywords.first);
    final all = keywords.map(_capitalized).join(', ');

    final tone = _toneWord(category);
    final lengthHint = _lengthHint(length);

    return [
      '$primary — $lengthHint $tone.',
      'It\'s giving $all energy.',
      '$primary hits different when you\'re $tone.',
      'Just $all things. Always.',
      'Life\'s too short not to embrace $all.',
    ];
  }

  String _toneWord(CaptionCategory cat) {
    switch (cat) {
      case CaptionCategory.men:
        return 'bold';
      case CaptionCategory.women:
        return 'graceful';
      case CaptionCategory.savage:
        return 'unbothered';
      case CaptionCategory.romantic:
        return 'in love';
      case CaptionCategory.funny:
        return 'chaotic';
      case CaptionCategory.aesthetic:
        return 'vibe';
      case CaptionCategory.travel:
        return 'adventurous';
      case CaptionCategory.fitness:
        return 'driven';
      case CaptionCategory.attitude:
        return 'confident';
      case CaptionCategory.none:
        return 'real';
    }
  }

  String _lengthHint(CaptionLength len) {
    switch (len) {
      case CaptionLength.short:
        return 'purely';
      case CaptionLength.medium:
        return 'endlessly';
      case CaptionLength.long:
        return 'undeniably and unequivocally';
    }
  }

  // -------------------------------------------------------------------------
  // Deduplication & padding
  // -------------------------------------------------------------------------

  List<String> _deduped(List<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final s in raw) {
      final k = s.trim().toLowerCase();
      if (k.isNotEmpty && seen.add(k)) out.add(s.trim());
    }
    return out;
  }

  List<String> _padToMin(
    List<String> existing,
    CaptionCategory category,
    CaptionLength length,
    List<String> keywords,
  ) {
    const minCount = 5;
    if (existing.length >= minCount) return existing;

    final extra = _keywordDrivenLines(category, length, keywords.isEmpty
        ? ['']
        : keywords);
    final combined = _deduped([...existing, ...extra]);
    return combined;
  }

  // -------------------------------------------------------------------------
  // Style application
  // -------------------------------------------------------------------------

  List<String> _applyStyles(List<String> captions, List<CaptionStyle> styles) {
    if (styles.isEmpty) return captions;

    // Logical order: humanize first, then rhyming, then tone transforms.
    final ordered = _orderedStyles(styles);
    return captions.map((c) {
      var out = c;
      for (final s in ordered) {
        out = _applyStyle(out, s);
      }
      return out;
    }).toList();
  }

  List<CaptionStyle> _orderedStyles(List<CaptionStyle> styles) {
    const order = [
      CaptionStyle.humanize,
      CaptionStyle.rhyming,
      CaptionStyle.savage,
      CaptionStyle.funny,
      CaptionStyle.romantic,
    ];
    return order.where(styles.contains).toList();
  }

  String _applyStyle(String caption, CaptionStyle style) {
    switch (style) {
      case CaptionStyle.humanize:
        return _humanize(caption);
      case CaptionStyle.rhyming:
        return _addRhyme(caption);
      case CaptionStyle.savage:
        return _savagify(caption);
      case CaptionStyle.funny:
        return _funnify(caption);
      case CaptionStyle.romantic:
        return _romanticize(caption);
    }
  }

  // -------------------------------------------------------------------------
  // Humanize transformer
  // -------------------------------------------------------------------------

  String _humanize(String text) {
    var out = text;

    // Apply contractions.
    for (final entry in _contractions.entries) {
      out = out.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }

    // Sprinkle natural fillers & emojis (lightly).
    if (!_containsFiller(out)) {
      out = _sprinkleFiller(out);
    }

    return out;
  }

  bool _containsFiller(String text) {
    const fillers = ['just', 'kinda', 'really', 'honestly', 'literally'];
    final lower = text.toLowerCase();
    return fillers.any((f) => lower.contains(f));
  }

  String _sprinkleFiller(String text) {
    final fillerEmoji = ['✨', '💯', '🙌', '🔥', '🌟'];
    final fillerWord = ['honestly', 'just', 'kinda', 'really', 'literally'];

    // Add a filler word near the start (non-destructively).
    if (text.length > 10) {
      final words = text.split(' ');
      final insertAt =
          words.length > 2 ? 1 : 0; // after the first word if possible
      final filler =
          fillerWord[(text.length) % fillerWord.length]; // deterministic pick
      words.insert(insertAt, filler);
      text = words.join(' ');
    }

    // Append an emoji if the text doesn't already end with one.
    if (!text.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true))) {
      final emoji = fillerEmoji[text.length % fillerEmoji.length];
      text = '$text $emoji';
    }

    return text;
  }

  static const Map<String, String> _contractions = {
    r'\bI am\b': "I'm",
    r'\bI have\b': "I've",
    r'\bI will\b': "I'll",
    r'\bI would\b': "I'd",
    r'\bI had\b': "I'd",
    r'\byou are\b': "you're",
    r'\byou have\b': "you've",
    r'\byou will\b': "you'll",
    r'\bwe are\b': "we're",
    r'\bwe have\b': "we've",
    r'\bthey are\b': "they're",
    r'\bthey have\b': "they've",
    r'\bdo not\b': "don't",
    r'\bdoes not\b': "doesn't",
    r'\bdid not\b': "didn't",
    r'\bcannot\b': "can't",
    r'\bwill not\b': "won't",
    r'\bwould not\b': "wouldn't",
    r'\bshould not\b': "shouldn't",
    r'\bcould not\b': "couldn't",
    r'\bis not\b': "isn't",
    r'\bare not\b': "aren't",
    r'\bwas not\b': "wasn't",
    r'\bwere not\b': "weren't",
    r'\bhave not\b': "haven't",
    r'\bhas not\b': "hasn't",
    r'\bhad not\b': "hadn't",
    r'\bit is\b': "it's",
    r'\bthat is\b': "that's",
    r'\bthere is\b': "there's",
    r'\bwhat is\b': "what's",
    r'\bwho is\b': "who's",
    r'\blet us\b': "let's",
  };

  // -------------------------------------------------------------------------
  // Rhyming transformer
  // -------------------------------------------------------------------------

  static const Map<String, String> _rhymeDict = {
    // end-word → rhyme pair
    'night': 'light',
    'light': 'night',
    'game': 'flame',
    'flame': 'game',
    'vibe': 'tribe',
    'tribe': 'vibe',
    'grind': 'mind',
    'mind': 'grind',
    'rise': 'skies',
    'skies': 'rise',
    'free': 'me',
    'me': 'free',
    'stay': 'way',
    'way': 'stay',
    'heart': 'start',
    'start': 'heart',
    'glow': 'flow',
    'flow': 'glow',
    'dream': 'stream',
    'stream': 'dream',
    'real': 'feel',
    'feel': 'real',
    'soul': 'whole',
    'whole': 'soul',
    'time': 'climb',
    'climb': 'time',
    'fire': 'higher',
    'higher': 'fire',
    'go': 'grow',
    'grow': 'go',
    'shine': 'divine',
    'divine': 'shine',
    'power': 'hour',
    'hour': 'power',
    'move': 'prove',
    'prove': 'move',
    'gold': 'bold',
    'bold': 'gold',
    'strong': 'long',
    'long': 'strong',
    'loud': 'crowd',
    'crowd': 'loud',
  };

  String _addRhyme(String caption) {
    // Find the last word and look up a rhyme.
    final words = caption
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .split(RegExp(r'\s+'));
    if (words.isEmpty) return caption;

    final lastWord = words.last.toLowerCase();
    final rhyme = _rhymeDict[lastWord];
    if (rhyme == null) return caption;

    // Append a short rhyming line (A-A pattern).
    final suffix =
        '${_capitalized(rhyme)} is all I know.'; // short rhyming couplet
    return '$caption\n$suffix';
  }

  // -------------------------------------------------------------------------
  // Tone transformers
  // -------------------------------------------------------------------------

  String _savagify(String caption) {
    const savagePrefix = [
      'Honestly? ',
      'Plot twist: ',
      'Unpopular opinion: ',
      'Let that sink in — ',
      'Not to brag, but ',
    ];
    const savageSuffix = [
      ' Deal with it.',
      ' You\'re welcome.',
      ' Take notes.',
      ' Period.',
      ' Stay mad.',
    ];

    final p = savagePrefix[caption.length % savagePrefix.length];
    final s = savageSuffix[(caption.length + 1) % savageSuffix.length];
    // Lowercase the first char of caption to blend with prefix.
    final body = caption.isEmpty
        ? caption
        : caption[0].toLowerCase() + caption.substring(1);
    return '$p$body$s';
  }

  String _funnify(String caption) {
    const funnyPrefixes = [
      'POV: ',
      'Me explaining to my wallet why ',
      'Nobody asked but ',
      'Genuine question: ',
      'Chapter 1: ',
    ];
    const funnySuffixes = [
      ' (ask me how)',
      ' — anyway, send snacks.',
      ' ¯\\_(ツ)_/¯',
      ' I have no idea what I\'m doing.',
      ' But here we are.',
    ];

    final p = funnyPrefixes[caption.length % funnyPrefixes.length];
    final s = funnySuffixes[(caption.length + 2) % funnySuffixes.length];
    final body = caption.isEmpty
        ? caption
        : caption[0].toLowerCase() + caption.substring(1);
    return '$p$body$s';
  }

  String _romanticize(String caption) {
    const romanticPrefix = [
      'Softly: ',
      'For you — ',
      'Between the lines: ',
      'With love, ',
      'You make me think — ',
    ];
    const romanticSuffix = [
      ' 🌙',
      ', and that\'s enough.',
      ' — always.',
      ', my heart agrees.',
      ' 🌷',
    ];

    final p = romanticPrefix[caption.length % romanticPrefix.length];
    final s = romanticSuffix[(caption.length + 3) % romanticSuffix.length];
    final body = caption.isEmpty
        ? caption
        : caption[0].toLowerCase() + caption.substring(1);
    return '$p$body$s';
  }

  // -------------------------------------------------------------------------
  // Utilities
  // -------------------------------------------------------------------------

  String _capitalized(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }
}
