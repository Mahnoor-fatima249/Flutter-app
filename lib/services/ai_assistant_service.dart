import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clothing_item.dart';
import 'storage_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] ?? '',
    isUser: json['isUser'] ?? false,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
  );
}

enum DetectedLanguage { urdu, hindi, punjabi, english, romanUrdu, romanHindi }

class AIAssistantService {
  static final AIAssistantService _instance = AIAssistantService._internal();
  factory AIAssistantService() => _instance;
  AIAssistantService._internal();

  final Random _random = Random();
  DetectedLanguage _lastDetectedLanguage = DetectedLanguage.romanUrdu;
  static const String _chatHistoryBox = 'chat_history';
  static const int _maxHistoryDays = 30;

  DetectedLanguage get lastDetectedLanguage => _lastDetectedLanguage;

  // Urdu/Nastaliq script patterns
  static final RegExp _urduScript = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
  // Devanagari (Hindi) script patterns
  static final RegExp _hindiScript = RegExp(r'[\u0900-\u097F]');
  // Gurmukhi (Punjabi) script patterns
  static final RegExp _punjabiScript = RegExp(r'[\u0A00-\u0A7F]');

  // Roman Urdu/Hindi word indicators
  static const List<String> _romanUrduWords = [
    'kya', 'hai', 'hain', 'ho', 'ka', 'ki', 'ke', 'ko', 'se', 'me',
    'pe', 'par', 'aur', 'ya', 'nahi', 'nahin', 'haan', 'ji', 'bhai',
    'acha', 'achha', 'theek', 'sahi', 'galat', 'karo', 'karna', 'mat',
    'mera', 'meri', 'mere', 'tera', 'teri', 'tere', 'uska', 'uski',
    'kahan', 'kab', 'kyun', 'kaise', 'kaisa', 'kaun', 'kitna',
    'chahiye', 'chahiye', 'de', 'do', 'le', 'lo', 'ja', 'aa',
    'bata', 'batao', 'suno', 'dekho', 'bolo', 'poochho',
    'pehnu', 'pehna', 'pehne', 'kapde', 'kapda', 'juta',
    'outfit', 'match', 'suggest', 'karo', 'style',
  ];

  static const List<String> _punjabiWords = [
    'ki', 'haal', 'ho', 'thik', 'ahan', 'ji', 'bhai', 'yaar',
    'mera', 'tera', 'usda', 'kida', 'kidha', 'kado', 'kithe',
    'naa', 'eh', 'oh', 'assi', 'tussi', 'ohda', 'edda',
    'poochho', 'dasso', 'sunno', 'dekho', 'bolo',
    'pehnu', 'pehna', 'jutte', 'kurta', 'pajama',
    'changa', 'wadiya', 'sohna', 'sohni',
  ];

  DetectedLanguage detectLanguage(String text) {
    // Check for script-based detection first
    if (_urduScript.hasMatch(text)) return DetectedLanguage.urdu;
    if (_punjabiScript.hasMatch(text)) return DetectedLanguage.punjabi;
    if (_hindiScript.hasMatch(text)) return DetectedLanguage.hindi;

    final lower = text.toLowerCase().trim();
    final words = lower.split(RegExp(r'\s+'));

    // Check for Punjabi-specific roman words
    int punjabiScore = 0;
    int urduScore = 0;
    int englishScore = 0;

    for (final word in words) {
      if (_punjabiWords.contains(word)) punjabiScore += 2;
      if (_romanUrduWords.contains(word)) urduScore += 1;
      if (RegExp(r'^[a-z]+$').hasMatch(word) && !_romanUrduWords.contains(word)) {
        englishScore += 1;
      }
    }

    if (punjabiScore > urduScore && punjabiScore > englishScore) {
      return DetectedLanguage.punjabi;
    }
    if (urduScore > englishScore) return DetectedLanguage.romanUrdu;

    // Default
    if (englishScore > urduScore) return DetectedLanguage.english;
    return DetectedLanguage.romanUrdu;
  }

  DetectedLanguage _langFromStorage(String lang) {
    switch (lang) {
      case 'urdu':
        return DetectedLanguage.urdu;
      case 'hindi':
        return DetectedLanguage.hindi;
      case 'punjabi':
        return DetectedLanguage.punjabi;
      case 'english':
        return DetectedLanguage.english;
      default:
        return DetectedLanguage.english;
    }
  }

  String _localize(String urdu, String hindi, String punjabi, String english, [String romanUrdu = '']) {
    switch (_lastDetectedLanguage) {
      case DetectedLanguage.urdu:
        return urdu;
      case DetectedLanguage.hindi:
        return hindi;
      case DetectedLanguage.punjabi:
        return punjabi;
      case DetectedLanguage.english:
        return english;
      case DetectedLanguage.romanUrdu:
        return romanUrdu.isNotEmpty ? romanUrdu : urdu;
      case DetectedLanguage.romanHindi:
        return romanUrdu.isNotEmpty ? romanUrdu : hindi;
    }
  }

  static const Map<String, List<String>> _colorMatches = {
    'white': ['black', 'navy', 'blue', 'red', 'grey', 'brown', 'maroon', 'green', 'any color'],
    'black': ['white', 'red', 'pink', 'grey', 'beige', 'gold', 'silver', 'any color'],
    'navy': ['white', 'beige', 'cream', 'pink', 'yellow', 'tan', 'grey'],
    'blue': ['white', 'grey', 'brown', 'tan', 'orange', 'yellow', 'pink'],
    'red': ['black', 'white', 'grey', 'navy', 'beige', 'denim blue'],
    'pink': ['black', 'grey', 'navy', 'white', 'denim blue', 'brown'],
    'grey': ['white', 'black', 'pink', 'red', 'blue', 'yellow', 'any color'],
    'brown': ['white', 'cream', 'beige', 'pink', 'light blue', 'orange'],
    'beige': ['navy', 'black', 'brown', 'white', 'red', 'dark green'],
    'green': ['white', 'beige', 'brown', 'cream', 'grey', 'pink'],
    'yellow': ['navy', 'black', 'grey', 'brown', 'white', 'purple'],
    'orange': ['blue', 'navy', 'white', 'grey', 'brown', 'denim'],
    'purple': ['white', 'grey', 'pink', 'black', 'beige', 'lavender'],
    'maroon': ['white', 'grey', 'beige', 'cream', 'black', 'gold'],
    'cream': ['navy', 'black', 'brown', 'maroon', 'green', 'red'],
    'tan': ['navy', 'black', 'white', 'brown', 'forest green', 'red'],
  };

  String getResponse(String userMessage, List<ClothingItem> wardrobe) {
    final msg = userMessage.toLowerCase().trim();
    
    // Detect language from user message first
    final detected = detectLanguage(userMessage);
    
    // Use preferred language from settings as fallback
    final storage = StorageService();
    final preferred = storage.getPreferredLanguage();
    _lastDetectedLanguage = detected != DetectedLanguage.english ? detected : _langFromStorage(preferred);

    // Greetings - respond in user's language
    if (_matches(msg, ['hello', 'hi', 'hey', 'salam', 'assalam', 'hola', 'sup', 'yo',
        'sat sri akal', 'sat Sri', 'adab'])) {
      return _greeting();
    }
    if (_matches(msg, ['kaise ho', 'kaisa hai', 'how are you', 'kya hal', 'kaise hain',
        'kiday ho', 'kida haal', 'kida'])) {
      return _iamFine();
    }
    if (_matches(msg, ['naam', 'name', 'who are you', 'tumhara naam', 'tera naam', 'introduce',
        'tussi kon', 'tum kaun'])) {
      return _myName();
    }
    if (_matches(msg, ['thanks', 'shukriya', 'thank', 'dhanyavaad', 'meherbani',
        'bande', 'shukriya'])) {
      return _youWelcome();
    }
    if (_matches(msg, ['bye', 'alvida', 'goodbye', 'chalo', 'chal',
        'chal phir', 'rabb rakha'])) {
      return _goodbye();
    }

    // Help
    if (_matches(msg, ['help', 'madad', 'kya kar sakte', 'what can you do', 'features', 'kya hai'])) {
      return _helpText();
    }

    // Chat History
    if (_matches(msg, ['history', 'chat history', 'purani chat', 'pehle kya bola', 'what did i say', 'kal kya baat'])) {
      return getChatSummary();
    }

    // Wardrobe
    if (_matches(msg, ['wardrobe', 'kapde', 'clothes', 'mera wardrobe', 'closet'])) {
      return _wardrobeInfo(wardrobe);
    }
    if (_matches(msg, ['add', 'jod', 'add kaise', 'kaise jod', 'kapda kaise', 'upload', 'scan'])) {
      return _howToAdd();
    }
    if (_matches(msg, ['delete', 'hatao', 'remove', 'kaise hataye', 'kaise delete'])) {
      return _howToDelete();
    }

    // COLOR MATCHING - Smart color coordination
    if (_matches(msg, ['kaunsa colour', 'konsa color', 'which color', 'colour match', 'color match', 'colour ke sath', 'color ke sath', 'kiske sath', 'kis ke saath'])) {
      return _colorMatching(wardrobe, msg);
    }

    // SPECIFIC COLOR queries
    if (_matches(msg, ['white ke sath', 'white ke saath', 'white ke sath kya'])) return _specificColorMatch('white', wardrobe);
    if (_matches(msg, ['black ke sath', 'black ke saath', 'black ke sath kya'])) return _specificColorMatch('black', wardrobe);
    if (_matches(msg, ['navy ke sath', 'navy ke saath', 'navy ke sath kya'])) return _specificColorMatch('navy', wardrobe);
    if (_matches(msg, ['red ke sath', 'red ke saath', 'red ke sath kya'])) return _specificColorMatch('red', wardrobe);
    if (_matches(msg, ['blue ke sath', 'blue ke saath', 'blue ke sath kya'])) return _specificColorMatch('blue', wardrobe);
    if (_matches(msg, ['pink ke sath', 'pink ke saath', 'pink ke sath kya'])) return _specificColorMatch('pink', wardrobe);
    if (_matches(msg, ['grey ke sath', 'grey ke saath', 'grey ke sath kya'])) return _specificColorMatch('grey', wardrobe);
    if (_matches(msg, ['brown ke sath', 'brown ke saath', 'brown ke sath kya'])) return _specificColorMatch('brown', wardrobe);
    if (_matches(msg, ['beige ke sath', 'beige ke saath', 'beige ke sath kya'])) return _specificColorMatch('beige', wardrobe);
    if (_matches(msg, ['green ke sath', 'green ke saath', 'green ke sath kya'])) return _specificColorMatch('green', wardrobe);
    if (_matches(msg, ['yellow ke sath', 'yellow ke saath', 'yellow ke sath kya'])) return _specificColorMatch('yellow', wardrobe);

    // OUTFIT - Smart outfit suggestions using actual wardrobe
    if (_matches(msg, ['outfit', 'combination', 'pehnao', 'suggestion', 'kya pehnu', 'outfit suggestion', '搭配'])) {
      return _smartOutfitSuggestion(wardrobe, msg);
    }

    // STYLE & FASHION
    if (_matches(msg, ['style', 'fashion', 'trend', 'style tips', 'fashion tips'])) {
      return _styleTip();
    }
    if (_matches(msg, ['formal', 'office', 'party', 'casual', 'date', 'occasion'])) {
      return _occasionTip();
    }

    // WEATHER
    if (_matches(msg, ['weather', 'mausam', 'garmi', 'thand', 'barish'])) {
      return _weatherTip();
    }
    if (_matches(msg, ['season', 'summer', 'winter', 'spring', 'autumn'])) {
      return _seasonTip();
    }

    // CARE
    if (_matches(msg, ['care', 'dhulai', 'wash', 'clean', 'dhone', 'kapde kaise dhoye'])) {
      return _careTip();
    }
    if (_matches(msg, ['iron', 'press', 'istri'])) {
      return _ironingTip();
    }

    // MATERIAL & FABRIC
    if (_matches(msg, ['material', 'fabric', 'kapda kis bane', 'kapda kya hai', 'kapda kaisa'])) {
      return _materialTip();
    }
    if (_matches(msg, ['cotton', 'linen', 'silk', 'wool', 'denim', 'leather'])) {
      return _fabricDetail(msg);
    }

    // BODY TYPE
    if (_matches(msg, ['body type', 'body shape', 'mere hisaab se', 'mere liye kya', 'moti hun', 'patla hun', 'height'])) {
      return _bodyTypeTip();
    }

    // BUDGET
    if (_matches(msg, ['brand', 'brands', 'brand kya'])) return _brandTip();
    if (_matches(msg, ['price', 'kimat', 'kitne', 'mahnga', 'sasta', 'budget'])) return _priceTip();

    // FAVORITES
    if (_matches(msg, ['favorite', 'favourite', 'pasand', 'best'])) return _favoriteTip(wardrobe);

    // PROFILE & SETTINGS
    if (_matches(msg, ['profile', 'mera profile', 'profile kaise'])) return _profileTip();
    if (_matches(msg, ['setting', 'settings', 'badlav', 'change', 'kaise badle'])) return _settingsTip();

    // VIRTUAL TRY-ON
    if (_matches(msg, ['virtual', 'try on', 'tryon', 'ar', 'virtual try'])) return _virtualTryOnTip();

    // PHOTO
    if (_matches(msg, ['photo', 'picture', 'image', 'tasveer', 'photo kaise'])) return _photoTip();

    // FIT
    if (_matches(msg, ['fit', 'size', 'measurement', 'naap'])) return _fitTip();

    // WARDROBE GAPS - What's missing
    if (_matches(msg, ['missing', 'kya kam hai', 'kya chahiye', 'aur kya', 'gap', 'kya add karun'])) {
      return _wardrobeGaps(wardrobe);
    }

    // MIX & MATCH
    if (_matches(msg, ['mix', 'match', 'mix match', 'combine', 'jod'])) {
      return _mixAndMatch(wardrobe);
    }

    // CAPSULE WARDROBE
    if (_matches(msg, ['capsule', 'minimal', 'kam kapde', 'basic'])) {
      return _capsuleWardrobe();
    }

    // COLOR THEORY
    if (_matches(msg, ['color theory', 'colour theory', 'complementary', 'analogous', 'triadic'])) {
      return _colorTheory();
    }

    // LAUNDRY
    if (_matches(msg, ['laundry', 'dhobi', 'kapde dhoye', 'washing machine'])) {
      return _laundryTips();
    }

    // STAIN
    if (_matches(msg, ['stain', 'daag', 'daag kaise', 'stain kaise'])) {
      return _stainRemoval();
    }

    // PACKING
    if (_matches(msg, ['pack', 'packing', 'safar', 'travel', 'trip'])) {
      return _packingTips();
    }

    // WEAR COUNT
    if (_matches(msg, ['wear count', 'kitni baar', 'worn', 'pehna kab'])) {
      return _wearStats(wardrobe);
    }

    // LAYERING
    if (_matches(msg, ['layer', 'layering', 'layer up', 'layer kaise', 'jacket ke saath', 'sweater ke saath'])) {
      return _layeringGuide();
    }

    // ACCESSORIES
    if (_matches(msg, ['accessori', 'accessory', 'accessories', 'watch', 'belt', 'sunglasses', 'jewellery', 'jewelry'])) {
      return _accessoriesGuide();
    }

    // MONOCHROME
    if (_matches(msg, ['monochrome', 'mono', 'ek colour', 'ek color', 'same colour'])) {
      return _monochromeGuide();
    }

    // SMART CASUAL
    if (_matches(msg, ['smart casual', 'smart', 'semi formal', 'semi-formal'])) {
      return _smartCasualGuide();
    }

    // STREET STYLE
    if (_matches(msg, ['street', 'streetwear', 'urban', 'hypebeast'])) {
      return _streetStyleGuide();
    }

    // MINIMALIST
    if (_matches(msg, ['minimal', 'minimalist', 'simple', 'clean look'])) {
      return _minimalistGuide();
    }

    // PRINTS & PATTERNS
    if (_matches(msg, ['print', 'pattern', 'prints', 'stripes', 'check', 'plaid', 'floral'])) {
      return _printsGuide();
    }

    // FOOTWEAR GUIDE
    if (_matches(msg, ['shoe', 'shoes', 'footwear', 'sneaker', 'heels', 'boots', 'chappal', 'slippers'])) {
      return _footwearGuide();
    }

    // JEANS GUIDE
    if (_matches(msg, ['jeans', 'denim', 'jean'])) {
      return _jeansGuide();
    }

    // BAGS
    if (_matches(msg, ['bag', 'bags', 'handbag', 'backpack', 'purse'])) {
      return _bagsGuide();
    }

    // PERFUME / FRAGRANCE
    if (_matches(msg, ['perfume', 'fragrance', 'cologne', 'scent', 'khushbu'])) {
      return _perfumeGuide();
    }

    // GROOMING
    if (_matches(msg, ['grooming', 'groom', 'shaving', 'skincare', 'hair'])) {
      return _groomingTips();
    }

    return _fallback(userMessage);
  }

  bool _matches(String msg, List<String> keywords) {
    return keywords.any((k) => msg.contains(k));
  }

  // ==================== COLOR MATCHING ====================

  String _colorMatching(List<ClothingItem> wardrobe, String msg) {
    for (final color in _colorMatches.keys) {
      if (msg.contains(color)) {
        return _specificColorMatch(color, wardrobe);
      }
    }

    return _localize(
      '**رنگ میل گائیڈ:** 🎨\n\nکس رنگ کے بارے میں جاننا ہے؟\n\n'
          'سوچھ سکتے ہو:\n• "سفید کے ساتھ کیا پہنnoop؟"\n'
          '• "سیاہ کے ساتھ کونسا رنگ؟"\n\n'
          'یا **"Color theory"** ٹائپ کرو!',
      '**Color Matching Guide:** 🎨\n\nकिस रंग के बारे में जानना है?\n\n'
          'पूछ सकते हो:\n• "सफ़ेद के साथ क्या पहनूं?"\n'
          '• "काले के साथ कौन सा रंग?"\n\n'
          'या **"Color theory"** टाइप करो!',
      '**ਰੰਗ ਮਿਲਾਉਣ ਗਾਈਡ:** 🎨\n\nਕਿਸ ਰੰਗ ਬਾਰੇ ਜਾਣਨਾ ਹੈ?\n\n'
          'ਪੁੱਛ ਸਕਦੇ ਹੋ:\n• "ਚਿੱਟੇ ਨਾਲ ਕੀ ਪਹਿਨਾਂ?"\n'
          '• "ਕਾਲੇ ਨਾਲ ਕਿਹੜਾ ਰੰਗ?"\n\n'
          'ਜਾਂ **"Color theory"** ਟਾਈਪ ਕਰੋ!',
      '**Color Matching Guide:** 🎨\n\nWhich color do you want to know about?\n\n'
          'Ask:\n• "What goes with white?"\n'
          '• "What color with black?"\n\n'
          'Or type **"Color theory"** for full guide!',
      '**Color Matching Guide:** 🎨\n\nKis colour ke baare mein jaanna hai?\n\n'
          'Pooch sakte ho:\n• "White ke sath kya pehnu?"\n'
          '• "Black ke sath konsa colour?"\n\n'
          'Ya **"Color theory"** type karo!',
    );
  }

  String _specificColorMatch(String color, List<ClothingItem> wardrobe) {
    final matches = _colorMatches[color] ?? ['any color'];

    String wardrobeAdvice = '';
    if (wardrobe.isNotEmpty) {
      final matchingItems = wardrobe.where((item) =>
        matches.any((m) => item.primaryColor.toLowerCase().contains(m))).toList();

      if (matchingItems.isNotEmpty) {
        final itemNames = matchingItems.take(3).map((i) => '• ${i.name} (${i.primaryColor})').join('\n');
        wardrobeAdvice = _localize(
          '\n\n**تیرے Wardrobe سے match:**\n$itemNames',
          '\n\n**तुम्हारे Wardrobe से match:**\n$itemNames',
          '\n\n**ਤੁਹਾਡੇ Wardrobe ਤੋਂ match:**\n$itemNames',
          '\n\n**From your Wardrobe:**\n$itemNames',
          '\n\n**Tumhare Wardrobe se match:**\n$itemNames',
        );
      }
    }

    return _localize(
      '**${color.toUpperCase()} کے ساتھ یہ رنگ بیسٹ ہیں:** 🎨\n\n'
          '• ${matches.join("\n• ")}\n\n'
          '**$color Style Tips:**\n'
          '${_getColorStyleTips(color)}$wardrobeAdvice',
      '**${color.toUpperCase()} के साथ ये रंग best हैं:** 🎨\n\n'
          '• ${matches.join("\n• ")}\n\n'
          '**$color Style Tips:**\n'
          '${_getColorStyleTips(color)}$wardrobeAdvice',
      '**${color.toUpperCase()} ਨਾਲ ਇਹ ਰੰਗ best ਹਨ:** 🎨\n\n'
          '• ${matches.join("\n• ")}\n\n'
          '**$color Style Tips:**\n'
          '${_getColorStyleTips(color)}$wardrobeAdvice',
      '**${color.toUpperCase()} goes best with:** 🎨\n\n'
          '• ${matches.join("\n• ")}\n\n'
          '**$color Style Tips:**\n'
          '${_getColorStyleTips(color)}$wardrobeAdvice',
      '**${color.toUpperCase()} ke saath ye colors best hain:** 🎨\n\n'
          '• ${matches.join("\n• ")}\n\n'
          '**$color Style Tips:**\n'
          '${_getColorStyleTips(color)}$wardrobeAdvice',
    );
  }

  String _getColorStyleTips(String color) {
    switch (color) {
      case 'white':
        return '• White + Black = Classic formal look\n'
            '• White + Navy = Smart casual\n'
            '• White + Denim Blue = Weekend vibe\n'
            '• White + Red = Bold statement\n'
            '• White + Beige = Summer fresh';
      case 'black':
        return '• Black + White = Timeless combo\n'
            '• Black + Red = Night out look\n'
            '• Black + Pink = Feminine touch\n'
            '• Black + Gold = Party ready\n'
            '• Black + Grey = Monochrome chic';
      case 'navy':
        return '• Navy + White = Nautical classic\n'
            '• Navy + Beige = Preppy look\n'
            '• Navy + Pink = Soft & smart\n'
            '• Navy + Yellow = Bright & fresh\n'
            '• Navy + Grey = Corporate ready';
      case 'blue':
        return '• Blue + White = Clean & fresh\n'
            '• Blue + Brown = Earthy vibes\n'
            '• Blue + Grey = Cool tones\n'
            '• Blue + Orange = Bold contrast\n'
            '• Blue + Yellow = Cheerful combo';
      case 'red':
        return '• Red + Black = Power look\n'
            '• Red + White = Bold & clean\n'
            '• Red + Grey = Balanced\n'
            '• Red + Denim = Casual cool\n'
            '• Red + Beige = Warm tones';
      case 'pink':
        return '• Pink + Black = Edgy feminine\n'
            '• Pink + Grey = Soft & modern\n'
            '• Pink + Navy = Sophisticated\n'
            '• Pink + White = Fresh & girly\n'
            '• Pink + Denim = Casual cute';
      case 'green':
        return '• Green + White = Fresh & clean\n'
            '• Green + Brown = Forest vibes\n'
            '• Green + Beige = Earthy tones\n'
            '• Green + Grey = Modern\n'
            '• Green + Pink = Complementary pop';
      case 'yellow':
        return '• Yellow + Navy = Bold contrast\n'
            '• Yellow + Grey = Urban chic\n'
            '• Yellow + White = Sunny fresh\n'
            '• Yellow + Brown = Warm & cozy\n'
            '• Yellow + Purple = Triadic bold';
      case 'brown':
        return '• Brown + Cream = Warm classic\n'
            '• Brown + White = Clean & earthy\n'
            '• Brown + Navy = Smart casual\n'
            '• Brown + Orange = Autumn vibes\n'
            '• Brown + Green = Nature inspired';
      case 'grey':
        return '• Grey + White = Minimalist\n'
            '• Grey + Black = Monochrome\n'
            '• Grey + Pink = Soft contrast\n'
            '• Grey + Yellow = Modern pop\n'
            '• Grey + Blue = Cool professional';
      case 'beige':
        return '• Beige + Navy = Classic smart\n'
            '• Beige + Black = Elegant\n'
            '• Beige + Brown = Tonal dressing\n'
            '• Beige + White = Summer fresh\n'
            '• Beige + Red = Warm accent';
      default:
        return '• Neutral colors ke saath almost koi bhi color match hota hai\n'
            '• Bold colors ke saath neutral base best hai';
    }
  }

  // ==================== SMART OUTFIT SUGGESTION ====================

  String _smartOutfitSuggestion(List<ClothingItem> wardrobe, String msg) {
    if (wardrobe.length < 2) {
      return '**Outfit suggest karne ke liye kam se kam 2 kapde chahiye!** 👗\n\n'
          'Abhi tumhare wardrobe mein ${wardrobe.length} item hai.\n'
          'Pehle kuch kapde add karo phir main outfit suggest karunga!\n\n'
          'Tip: Scan tab se jaldi se kapde add karo 📸';
    }

    // Detect occasion from message
    String occasion = 'casual';
    if (msg.contains('formal') || msg.contains('office') || msg.contains('business')) occasion = 'formal';
    if (msg.contains('party') || msg.contains('night')) occasion = 'party';
    if (msg.contains('date') || msg.contains('romantic')) occasion = 'date';
    if (msg.contains('sport') || msg.contains('gym') || msg.contains('workout')) occasion = 'sporty';
    if (msg.contains('wedding') || msg.contains('shadi')) occasion = 'formal';
    if (msg.contains('casual') || msg.contains('daily') || msg.contains('ghar')) occasion = 'casual';

    final tops = wardrobe.where((i) => i.category == ClothingCategory.tops).toList();
    final bottoms = wardrobe.where((i) => i.category == ClothingCategory.bottoms).toList();
    final footwear = wardrobe.where((i) => i.category == ClothingCategory.footwear).toList();
    final outerwear = wardrobe.where((i) => i.category == ClothingCategory.outerwear).toList();
    final dresses = wardrobe.where((i) => i.category == ClothingCategory.dresses).toList();

    // Try to find color-matched combinations
    if (tops.isNotEmpty && bottoms.isNotEmpty) {
      // Find best color match
      ClothingItem? bestTop;
      ClothingItem? bestBottom;
      int bestScore = -1;

      for (var top in tops) {
        for (var bottom in bottoms) {
          int score = _calculateColorMatchScore(top.primaryColor, bottom.primaryColor);
          if (occasion != 'casual') {
            // For formal, prefer darker colors
            if (top.primaryColor == 'black' || top.primaryColor == 'navy') score += 2;
            if (bottom.primaryColor == 'black' || bottom.primaryColor == 'navy') score += 2;
          }
          if (score > bestScore) {
            bestScore = score;
            bestTop = top;
            bestBottom = bottom;
          }
        }
      }

      if (bestTop != null && bestBottom != null) {
        String shoeText = '';
        if (footwear.isNotEmpty) {
          final bestShoe = footwear.firstWhere(
            (s) => s.primaryColor == 'black' || s.primaryColor == 'brown' || s.primaryColor == 'white',
            orElse: () => footwear.first,
          );
          shoeText = '\n👟 **Footwear:** ${bestShoe.name} (${bestShoe.primaryColor})';
        }

        String outerwearText = '';
        if (outerwear.isNotEmpty && (occasion == 'formal' || occasion == 'party')) {
          final jacket = outerwear.first;
          outerwearText = '\n🧥 **Layer:** ${jacket.name} (${jacket.primaryColor})';
        }

        return '**${occasion.toUpperCase()} Outfit - Color Matched:** 👌\n\n'
            '👕 **Top:** ${bestTop.name} (${bestTop.primaryColor})\n'
            '👖 **Bottom:** ${bestBottom.name} (${bestBottom.primaryColor})'
            '$shoeText'
            '$outerwearText\n\n'
            '**Why this works:** ${_explainColorMatch(bestTop.primaryColor, bestBottom.primaryColor)}\n\n'
            '💡 **Tip:** ${_getOccasionTip(occasion)}';
      }
    }

    // Fallback - random suggestion
    if (tops.isNotEmpty && bottoms.isNotEmpty) {
      final top = tops[_random.nextInt(tops.length)];
      final bottom = bottoms[_random.nextInt(bottoms.length)];
      return '**Aaj ye outfit try karo:** 👌\n\n'
          '👕 **Top:** ${top.name} (${top.primaryColor})\n'
          '👖 **Bottom:** ${bottom.name} (${bottom.primaryColor})\n\n'
          'Ye combination achha lagega!';
    }

    return '**Wardrobe mein diverse items add karo!** 💡\n\n'
        'Tops aur bottoms mix karke achhe outfits ban sakte hain.\n'
        'Abhi tumhare paas ${tops.length} tops aur ${bottoms.length} bottoms hain.';
  }

  int _calculateColorMatchScore(String color1, String color2) {
    final matches = _colorMatches[color1.toLowerCase()];
    if (matches == null) return 0;

    final c2 = color2.toLowerCase();
    if (c2 == color1.toLowerCase()) return -1; // Same color = bad

    for (final match in matches) {
      if (c2.contains(match) || match.contains(c2)) return 3;
    }

    // Neutral + neutral = okay
    final neutrals = ['white', 'black', 'grey', 'beige', 'cream', 'tan'];
    if (neutrals.contains(color1.toLowerCase()) && neutrals.contains(c2)) return 2;

    return 0;
  }

  String _explainColorMatch(String top, String bottom) {
    final matches = _colorMatches[top.toLowerCase()];
    if (matches != null && matches.any((m) => bottom.toLowerCase().contains(m))) {
      return '$top aur $bottom complementary colors hain jo ek doosre ko enhance karte hain!';
    }
    return 'Ye classic color combination hai jo hamesha kaam karta hai!';
  }

  String _getOccasionTip(String occasion) {
    switch (occasion) {
      case 'formal':
        return 'Formal mein hamesha well-fitted kapde pehno aur minimal accessories rakho.';
      case 'party':
        return 'Party mein bold colors ya statement piece add karo outfit mein.';
      case 'date':
        return 'Date ke liye clean aur well-groomed look best hai.';
      case 'sporty':
        return 'Sporty look mein comfort priority hai, breathable fabrics choose karo.';
      default:
        return 'Casual mein comfortable aur relaxed fit best hai.';
    }
  }

  // ==================== WARDROBE GAPS ====================

  String _wardrobeGaps(List<ClothingItem> wardrobe) {
    if (wardrobe.isEmpty) {
      return '**Wardrobe abhi khali hai!** 📭\n\n'
          'Pehle kuch basics add karo:\n'
          '1. White t-shirt\n'
          '2. Blue jeans\n'
          '3. Black trousers\n'
          '4. White shirt\n'
          '5. Sneakers\n\n'
          'Ye 5 cheezein har wardrobe ki foundation hain!';
    }

    final categories = <String, int>{};
    for (var item in wardrobe) {
      final cat = item.category.name;
      categories[cat] = (categories[cat] ?? 0) + 1;
    }

    final missing = <String>[];
    if ((categories['tops'] ?? 0) < 3) missing.add('Tops (kam se kam 3 chahiye)');
    if ((categories['bottoms'] ?? 0) < 2) missing.add('Bottoms (kam se kam 2 chahiye)');
    if ((categories['footwear'] ?? 0) < 1) missing.add('Footwear (kam se kam 1 pair)');
    if ((categories['outerwear'] ?? 0) < 1) missing.add('Outerwear (jacket/hoodie)');
    if ((categories['accessories'] ?? 0) < 1) missing.add('Accessories (watch/belt/sunglasses)');

    // Check colors
    final colors = wardrobe.map((i) => i.primaryColor.toLowerCase()).toSet();
    if (!colors.contains('black') && !colors.contains('navy')) missing.add('Dark colored item (black/navy)');
    if (!colors.contains('white')) missing.add('White item (versatile basic)');

    if (missing.isEmpty) {
      return '**Tumhara wardrobe kaafi achha hai!** ✅\n\n'
          'Basic categories covered hain.\n'
          'Ab variety add karo - different colors aur occasions ke liye!\n\n'
          'Aur suggestions ke liye "outfit suggest karo" type karo.';
    }

    final missingList = missing.map((m) => '• $m').join('\n');
    return '**Tumhare Wardrobe mein ye missing hai:** 📋\n\n'
        '$missingList\n\n'
        '**Priority Order:**\n'
        '1. Pehle basics complete karo\n'
        '2. Phir occasion-specific add karo\n'
        '3. Last mein accessories aur layers\n\n'
        'Tip: "Capsule wardrobe" type karo minimal approach ke liye!';
  }

  // ==================== MIX & MATCH ====================

  String _mixAndMatch(List<ClothingItem> wardrobe) {
    if (wardrobe.length < 3) {
      return '**Mix & Match ke liye kam se kam 3 kapde chahiye!** 👗\n\n'
          'Abhi tumhare paas ${wardrobe.length} items hain.\n'
          'Pehle aur add karo phir mix & match karunga!';
    }

    final tops = wardrobe.where((i) => i.category == ClothingCategory.tops).toList();
    final bottoms = wardrobe.where((i) => i.category == ClothingCategory.bottoms).toList();

    if (tops.isEmpty || bottoms.isEmpty) {
      return '**Mix & Match ke liye tops aur bottoms dono chahiye!** 👕👖';
    }

    final combinations = <String>[];
    final usedPairs = <String>{};

    for (var top in tops.take(3)) {
      for (var bottom in bottoms.take(2)) {
        final pairKey = '${top.id}_${bottom.id}';
        if (!usedPairs.contains(pairKey)) {
          final score = _calculateColorMatchScore(top.primaryColor, bottom.primaryColor);
          if (score >= 0) {
            combinations.add('👕 ${top.name} (${top.primaryColor}) + 👖 ${bottom.name} (${bottom.primaryColor}) ${score > 0 ? "⭐" : ""}');
            usedPairs.add(pairKey);
          }
        }
      }
      if (combinations.length >= 5) break;
    }

    if (combinations.isEmpty) {
      return '**Color matched combinations nahi mile.** 🤔\n\n'
          'Try karo different colors add karna wardrobe mein!\n'
          'Neutral colors (white, black, grey) sabke saath match hote hain.';
    }

    return '**Mix & Match Combinations:** 🔄\n\n'
        '${combinations.join("\n\n")}\n\n'
        '⭐ = Best color match\n\n'
        'Aur combinations ke liye naye colors add karo wardrobe mein!';
  }

  // ==================== CAPSULE WARDROBE ====================

  String _capsuleWardrobe() {
    return '**Capsule Wardrobe Guide:** 👔\n\n'
        'Kam kapdon mein zyada outfits banao!\n\n'
        '**Essential Items (20-30 pieces):**\n\n'
        '👕 **Tops (7-8):**\n'
        '• 2 White t-shirts\n'
        '• 1 Black t-shirt\n'
        '• 1 White formal shirt\n'
        '• 1 Blue/Oxford shirt\n'
        '• 1 Polo shirt\n'
        '• 1 Breton stripe\n\n'
        '👖 **Bottoms (4-5):**\n'
        '• 1 Blue jeans\n'
        '• 1 Black trousers\n'
        '• 1 Chinos (beige/khaki)\n'
        '• 1 Shorts\n\n'
        '🧥 **Layers (3-4):**\n'
        '• 1 Blazer (navy/black)\n'
        '• 1 Casual jacket\n'
        '• 1 Hoodie/Sweater\n\n'
        '👟 **Footwear (3):**\n'
        '• 1 White sneakers\n'
        '• 1 Formal shoes\n'
        '• 1 Sandals/Slides\n\n'
        '💡 **Rule:** Har piece kisi aur piece ke saath match hona chahiye!';
  }

  // ==================== COLOR THEORY ====================

  String _colorTheory() {
    return '**Color Theory for Fashion:** 🎨\n\n'
        '1️⃣ **Complementary (Opposite colors):**\n'
        '   • Blue + Orange\n'
        '   • Red + Green\n'
        '   • Yellow + Purple\n'
        '   → Bold, eye-catching look\n\n'
        '2️⃣ **Analogous (Neighboring colors):**\n'
        '   • Blue + Green + Teal\n'
        '   • Red + Orange + Yellow\n'
        '   • Pink + Purple + Blue\n'
        '   → Harmonious, calming look\n\n'
        '3️⃣ **Monochromatic (Same color, different shades):**\n'
        '   • Light blue + Navy blue\n'
        '   • Pastel pink + Hot pink\n'
        '   • Beige + Brown + Chocolate\n'
        '   → Elegant, sophisticated look\n\n'
        '4️⃣ **Triadic (120° apart on wheel):**\n'
        '   • Red + Yellow + Blue\n'
        '   • Green + Orange + Purple\n'
        '   → Vibrant, playful look\n\n'
        '5️⃣ **Neutral Base + Pop Color:**\n'
        '   • Black/White/Grey base + 1 bright color\n'
        '   → Safe but stylish\n\n'
        '💡 **Rule:** Max 3 colors ek outfit mein!';
  }

  // ==================== MATERIAL & FABRIC ====================

  String _materialTip() {
    return '**Fabrics & Materials Guide:** 🧵\n\n'
        '☀️ **Summer Fabrics:**\n'
        '• Cotton - Breathable, comfortable\n'
        '• Linen - Light, airy (wrinkles ok!)\n'
        '• Chambray - Lightweight denim look\n\n'
        '❄️ **Winter Fabrics:**\n'
        '• Wool - Warm, durable\n'
        '• Fleece - Soft, lightweight warmth\n'
        '• Cashmere - Luxury warmth\n\n'
        '🌧️ **All Season:**\n'
        '• Polyester - Wrinkle-resistant\n'
        '• Jersey - Stretchy, comfortable\n'
        '• Denim - Durable, versatile\n\n'
        '💡 **Tip:** Fabric choice occasion ke hisaab se karo!';
  }

  String _fabricDetail(String msg) {
    if (msg.contains('cotton')) {
      return '**Cotton:** 🌿\n\n'
          '✅ Pros: Breathable, soft, easy to wash\n'
          '❌ Cons: Wrinkles easily, shrinkage\n'
          '👔 Best for: T-shirts, shirts, casual wear\n'
          '🧺 Care: Normal wash, cold water\n'
          '💡 Tip: Pre-shrunk cotton kharido';
    }
    if (msg.contains('silk')) {
      return '**Silk:** ✨\n\n'
          '✅ Pros: Luxurious, smooth, temperature regulating\n'
          '❌ Cons: Expensive, delicate\n'
          '👔 Best for: Formal shirts, dresses, blouses\n'
          '🧺 Care: Dry clean ya hand wash\n'
          '💡 Tip: Silk ke saath hanger use karo';
    }
    if (msg.contains('denim')) {
      return '**Denim:** 👖\n\n'
          '✅ Pros: Durable, versatile, gets better with age\n'
          '❌ Cons: Heavy, slow to dry\n'
          '👔 Best for: Jeans, jackets, shirts\n'
          '🧺 Care: Andar se dhoye, kam dhoye\n'
          '💡 Tip: Raw denim pehle wash mat karo';
    }
    if (msg.contains('wool')) {
      return '**Wool:** 🧶\n\n'
          '✅ Pros: Warm, natural, moisture-wicking\n'
          '❌ Cons: Itchy, needs special care\n'
          '👔 Best for: Sweaters, coats, suits\n'
          '🧺 Care: Hand wash cold, dry flat\n'
          '💡 Tip: Cedar balls se moth protection';
    }
    if (msg.contains('linen')) {
      return '**Linen:** 🌾\n\n'
          '✅ Pros: Super breathable, lightweight, sustainable\n'
          '❌ Cons: Wrinkles a lot\n'
          '👔 Best for: Summer shirts, pants, dresses\n'
        '🧺 Care: Gentle wash, hang dry\n'
          '💡 Tip: Linen wrinkles are stylish!';
    }
    if (msg.contains('leather')) {
      return '**Leather:** 🧥\n\n'
          '✅ Pros: Durable, ages beautifully, weather-resistant\n'
          '❌ Cons: Expensive, needs maintenance\n'
          '👔 Best for: Jackets, shoes, belts, bags\n'
          '🧺 Care: Condition regularly, waterproof\n'
          '💡 Tip: Real leather patina develop karta hai';
    }
    return '**Fabrics Guide:** 🧵\n\n'
        'Kis fabric ke baare mein jaanna hai?\n'
        'Try karo: "Cotton", "Silk", "Denim", "Wool", "Linen", "Leather"';
  }

  // ==================== BODY TYPE ====================

  String _bodyTypeTip() {
    return '**Dressing for Your Body Type:** 👤\n\n'
        '📏 **Petite (Short height):**\n'
        '• Vertical stripes lagao\n'
        '• High-waisted pants pehno\n'
        '• Monochrome outfit try karo\n'
        '• Avoid oversized clothes\n\n'
        '📏 **Tall:**\n'
        '• Horizontal stripes theek hain\n'
        '• Layering achhi lagti hai\n'
        '• Cropped jackets try karo\n'
        '• Avoid overly long tops\n\n'
        '📏 **Plus Size:**\n'
        '• Dark colors slimming hain\n'
        '• Structured fabrics choose karo\n'
        '• V-neckline flattering hai\n'
        '• Avoid clingy fabrics\n\n'
        '📏 **Athletic:**\n'
        '• Curves dikhane ke liye fitted clothes\n'
        '• Ruching/detailing add karo\n'
        '• A-line skirts/dresses try karo\n\n'
        '💡 **Rule:** Confidence sabse important hai!';
  }

  // ==================== IRONING ====================

  String _ironingTip() {
    return '**Ironing Guide:** 🔥\n\n'
        '🌡️ **Temperature Settings:**\n'
        '• Low (110°C): Silk, Synthetics, Nylon\n'
        '• Medium (150°C): Wool, Polyester, Spandex\n'
        '• High (200°C): Cotton, Linen, Denim\n\n'
        '✅ **Tips:**\n'
        '• Hamesha inside out iron karo\n'
        '• Steam use karo for stubborn wrinkles\n'
        '• Ironing board clean rakho\n'
        '• Starch spray for crisp look\n\n'
        '❌ **Avoid:**\n'
        '• Direct iron on prints/embroidery\n'
        '•太高 temperature on delicate fabrics\n'
        '• Ironing wet clothes (pehle sukhao)';
  }

  // ==================== LAUNDRY TIPS ====================

  String _laundryTips() {
    return '**Laundry Tips:** 🧺\n\n'
        '✅ **Sorting:**\n'
        '• Colors alag karo (whites, darks, lights)\n'
        '• Heavy items alag (jeans, towels)\n'
        '• Delicates alag (silk, lace)\n\n'
        '✅ **Washing:**\n'
        '• Cold water for colors (fading kam)\n'
        '• Hot water for whites/bedsheets\n'
        '• Gentle cycle for delicates\n'
        '• Don\'t overload machine\n\n'
        '✅ **Drying:**\n'
        '• Dark colors shade mein sukhao\n'
        '• Tumble dry low for delicates\n'
        '• Hang dry for knitwear\n\n'
        '✅ **Folding:**\n'
        '• T-shirts konFold method se fold karo\n'
        '• Jeans hang karo ya fold karo\n'
        '• Sweaters fold karo (hanger se shape bigadti hai)';
  }

  // ==================== STAIN REMOVAL ====================

  String _stainRemoval() {
    return '**Stain Removal Guide:** 🧹\n\n'
        '🔴 **Coffee/Tea:**\n'
        '• Cold water se rinse karo\n'
        '• Dish soap lagao, 5 min wait\n'
        '• Phir wash karo\n\n'
        '🟡 **Oil/Grease:**\n'
        '• Cornstarch lagao, 30 min wait\n'
        '• Brush karo, phir wash\n\n'
        '🔵 **Ink:**\n'
        '• Hand sanitizer lagao\n'
        '• Cold water se dho\n\n'
        '🟢 **Grass:**\n'
        '• White vinegar lagao\n'
        '• Cold water se rinse\n\n'
        '🔴 **Blood:**\n'
        '• HAMESHA cold water use karo\n'
        '• Hydrogen peroxide for stubborn stains\n\n'
        '⚠️ **Rule:** Stain foran treat karo, sukhne mat do!';
  }

  // ==================== PACKING TIPS ====================

  String _packingTips() {
    return '**Travel Packing Tips:** ✈️\n\n'
        '📋 **Rule of 3-4-5:**\n'
        '• 3 tops\n'
        '• 4 bottoms (including shorts)\n'
        '• 5 accessories\n\n'
        '✅ **Color Strategy:**\n'
        '• Neutral base colors pack karo\n'
        '• 1-2 bright accent pieces\n'
        '• Har piece kisi na kisi ke saath match ho\n\n'
        '✅ **Essentials:**\n'
        '• 1 Formal outfit (emergency ke liye)\n'
        '• Comfortable walking shoes\n'
        '• Layering pieces (jacket/sweater)\n'
        '• Undergarments (days + 1 extra)\n\n'
        '✅ **Packing Method:**\n'
        '• Rolling method se space bache\n'
        '• Shoes plastic bags mein rakho\n'
        '• Heavy items bottom mein\n'
        '• Toiletries waterproof bag mein\n\n'
        '💡 **Tip:** Camera ready outfit hand luggage mein rakho!';
  }

  // ==================== WEAR STATS ====================

  String _wearStats(List<ClothingItem> wardrobe) {
    if (wardrobe.isEmpty) {
      return '**Wardrobe khali hai!** 📭\n\n'
          'Pehle kapde add karo phir wear stats dikhaunga.';
    }

    final totalWears = wardrobe.fold(0, (sum, i) => sum + i.wearCount);
    final mostWorn = wardrobe.where((i) => i.wearCount > 0).toList()
      ..sort((a, b) => b.wearCount.compareTo(a.wearCount));
    final neverWorn = wardrobe.where((i) => i.wearCount == 0).toList();
    final favorites = wardrobe.where((i) => i.isFavorite).toList();

    String result = '**Wardrobe Stats:** 📊\n\n';
    result += '📊 **Total Wears:** $totalWears\n';
    result += '📦 **Total Items:** ${wardrobe.length}\n';
    result += '❤️ **Favorites:** ${favorites.length}\n\n';

    if (mostWorn.isNotEmpty) {
      result += '👑 **Most Worn:**\n';
      for (var item in mostWorn.take(3)) {
        result += '• ${item.name} (${item.wearCount} times)\n';
      }
      result += '\n';
    }

    if (neverWorn.isNotEmpty) {
      result += '😴 **Never Worn (${neverWorn.length} items):**\n';
      for (var item in neverWorn.take(3)) {
        result += '• ${item.name}\n';
      }
      result += '\n💡 Inhe kabhi toh pehno ya sell/do dena!';
    }

    return result;
  }

  // ==================== LAYERING ====================

  String _layeringGuide() {
    return '**Layering Guide:** 🧥\n\n'
        '**Layer 1 - Base Layer:**\n'
        '• T-shirts, shirts, tank tops\n'
        '• Fit: Comfortable, tucked in\n'
        '• Colors: Neutral (white, black, grey)\n\n'
        '**Layer 2 - Mid Layer:**\n'
        '• Sweaters, cardigans, hoodies\n'
        '• Adds warmth & style\n'
        '• Colors: Complementary to base\n\n'
        '**Layer 3 - Outer Layer:**\n'
        '• Jackets, coats, blazers\n'
        '• Statement piece\n'
        '• Colors: Can be bold\n\n'
        '**Layering Rules:**\n'
        '• Thin to thick (andar patla, bahar mota)\n'
        '• Short under long\n'
        '• Max 3 layers rakho\n'
        '• Fit important hai - loose base + fitted outer\n\n'
        '**Season Combinations:**\n'
        '☀️ Summer: T-shirt + Light shirt (open)\n'
        '🍂 Autumn: T-shirt + Sweater + Jacket\n'
        '❄️ Winter: Thermal + Sweater + Coat\n'
        '🌧️ Rain: T-shirt + Hoodie + Rain jacket\n\n'
        '💡 Tip: Collar dikhna chahiye base layer ka!';
  }

  // ==================== ACCESSORIES ====================

  String _accessoriesGuide() {
    return '**Accessories Guide:** 💎\n\n'
        '⌚ **Watch:**\n'
        '• Formal: Leather strap, metal dial\n'
        '• Casual: Digital, NATO strap\n'
        '• Rule: Size wrist ke proportion mein\n\n'
        '👔 **Belt:**\n'
        '• Rule: Shoes ke color se match karo\n'
        '• Formal: Thin, leather\n'
        '• Casual: Canvas, woven\n\n'
        '🕶️ **Sunglasses:**\n'
        '• Face shape ke according choose karo\n'
        '• Round face: Angular frames\n'
        '• Square face: Round frames\n'
        '• Oval: Koi bhi chalega\n\n'
        '💍 **Rings & Jewelry:**\n'
        '• Men: Max 2-3 rings\n'
        '• Women: Stack kar sakte ho\n'
        '• Metal match karo (silver ya gold)\n\n'
        '🧣 **Scarves & Beanies:**\n'
        '• Winter mein style + warmth\n'
        '• Bright colors = outfit pop\n\n'
        '🎒 **Bags:**\n'
        '• Formal: Briefcase, clutch\n'
        '• Casual: Backpack, crossbody\n'
        '• Color: Neutral best hai\n\n'
        '💡 **Rule:** Max 3-4 accessories ek outfit mein!';
  }

  // ==================== MONOCHROME ====================

  String _monochromeGuide() {
    return '**Monochrome Dressing:** 🖤🤍\n\n'
        'Ek hi color ke different shades use karo!\n\n'
        '⬛ **All Black:**\n'
        '• Timeless, slimming, chic\n'
        '• Texture mix karo (cotton + leather)\n'
        '• Pop of color: Red shoes ya bag\n\n'
        '⬜ **All White:**\n'
        '• Fresh, clean, elegant\n'
        '• Summer perfect\n'
        '• Off-white + cream mix karo\n\n'
        '🩶 **All Grey:**\n'
        '• Sophisticated, modern\n'
        '• Light grey + charcoal combo\n'
        '• Professional look\n\n'
        '🩵 **All Blue:**\n'
        '• Navy + light blue\n'
        '• Denim on denim (Canadian tuxedo)\n'
        '• Smart casual perfect\n\n'
        '✅ **Rules:**\n'
        '• 2-3 shades mein rakho\n'
        '• Texture important hai (smooth + rough)\n'
        '• Accessories se break do\n'
        '• Metals silver best hain monochrome mein';
  }

  // ==================== SMART CASUAL ====================

  String _smartCasualGuide() {
    return '**Smart Casual Guide:** 👔\n\n'
        'Formal aur casual ka perfect mix!\n\n'
        '✅ **Winning Combos:**\n'
        '• Blazer + T-shirt + Jeans\n'
        '• Chinos + Oxford shirt (no tie)\n'
        '• Dress pants + Polo shirt\n'
        '• Blazer + Hoodie + Slim pants\n\n'
        '✅ **Key Pieces:**\n'
        '• Navy blazer (sabse versatile)\n'
        '• Well-fitted chinos\n'
        '• Oxford/Breton shirt\n'
        '• Clean sneakers ya loafers\n'
        '• Leather belt\n\n'
        '❌ **Avoid:**\n'
        '• Ripped jeans\n'
        '• Graphic tees\n'
        '• Flip flops\n'
        '• Overly formal pieces\n\n'
        '💡 **Rule:** Jab doubt ho, slightly overdressed better hai!';
  }

  // ==================== STREET STYLE ====================

  String _streetStyleGuide() {
    return '**Street Style Guide:** 🛹\n\n'
        ' trendy aur comfortable!\n\n'
        '✅ **Essential Pieces:**\n'
        '• Oversized t-shirts/hoodies\n'
        '• Cargo pants/joggers\n'
        '• Chunky sneakers\n'
        '• Bucket hat/cap\n'
        '• Crossbody bag\n\n'
        '✅ **Color Palette:**\n'
        '• Earth tones (olive, brown, beige)\n'
        '• All black\n'
        '• Bold primary colors\n'
        '• Monochrome\n\n'
        '✅ **Styling Tips:**\n'
        '• Oversized top + slim bottom\n'
        '• Layers important hain\n'
        '• Statement sneakers\n'
        '• Mix high & low fashion\n\n'
        '❌ **Avoid:**\n'
        '• Too many logos\n'
        '• Overly matched outfits\n'
        '• Formal shoes\n\n'
        '💡 Brands: Nike, Adidas, Stussy, Off-White';
  }

  // ==================== MINIMALIST ====================

  String _minimalistGuide() {
    return '**Minimalist Style Guide:** ✨\n\n'
        'Kam cheezein, zyada impact!\n\n'
        '✅ **Color Palette:**\n'
        '• White, Black, Grey\n'
        '• Beige, Navy, Olive\n'
        '• Max 2-3 colors per outfit\n\n'
        '✅ **Essential Pieces (15-20):**\n'
        '• White t-shirt (2-3)\n'
        '• Black jeans\n'
        '• Blue jeans\n'
        '• White shirt\n'
        '• Navy blazer\n'
        '• White sneakers\n'
        '• Black boots\n\n'
        '✅ **Rules:**\n'
        '• No logos/print\n'
        '• Clean lines\n'
        '• Perfect fit zaroori hai\n'
        '• Quality over quantity\n'
        '• Neutral accessories\n\n'
        '✅ **Benefits:**\n'
        '• Decision fatigue kam\n'
        '• Kam kapde, zyada outfits\n'
        '• Timeless look\n'
        '• Sustainable fashion';
  }

  // ==================== PRINTS & PATTERNS ====================

  String _printsGuide() {
    return '**Prints & Patterns Guide:** 🎨\n\n'
        '✅ **Types:**\n'
        '• **Stripes:** Vertical = slimming, Horizontal = broad\n'
        '• **Checks/Plaid:** Classic, casual\n'
        '• **Floral:** Summer, feminine\n'
        '• **Polka Dots:** Retro, fun\n'
        '• **Geometric:** Modern, bold\n\n'
        '✅ **Mixing Rules:**\n'
        '• Same color family mein mix karo\n'
        '• Ek bold + ek subtle print\n'
        '• Size vary karo (big + small)\n'
        '• Solid color se balance karo\n\n'
        '✅ **Best Combos:**\n'
        '• Striped shirt + Solid pants\n'
        '• Printed skirt + Plain top\n'
        '• Check blazer + Solid tee\n\n'
        '❌ **Avoid:**\n'
        '• 3+ prints ek saath\n'
        '• Same size prints mix\n'
        '• Clashing colors\n\n'
        '💡 Beginner: Pehle accessories mein prints try karo!';
  }

  // ==================== FOOTWEAR ====================

  String _footwearGuide() {
    return '**Footwear Guide:** 👟\n\n'
        '✅ **Must-Have Pairs:**\n'
        '• White sneakers (sabse versatile)\n'
        '• Black formal shoes\n'
        '• Brown loafers\n'
        '• Boots (casual/formal)\n'
        '• Sandals/Slides\n\n'
        '✅ **Match Rules:**\n'
        '• Formal outfit = Formal shoes\n'
        '• Casual = Sneakers/sandals\n'
        '• Belt = Shoes ka color\n'
        '• Socks = Pants ya shoes se match\n\n'
        '✅ **Occasion Guide:**\n'
        '💼 Office: Oxfords, loafers\n'
        '🎉 Party: Clean sneakers,Chelsea boots\n'
        '🏃 Casual: Sneakers, slides\n'
        '💑 Date: Loafers, clean sneakers\n'
        '🏔️ Outdoor: Boots, chunky sneakers\n\n'
        '✅ **Color Matching:**\n'
        '• Black shoes: Black, grey, navy outfits\n'
        '• Brown shoes: Beige, olive, tan outfits\n'
        '• White sneakers: Koi bhi outfit\n\n'
        '💡 Rule: Shoes hamesha saaf aur maintained honi chahiye!';
  }

  // ==================== JEANS ====================

  String _jeansGuide() {
    return '**Jeans Guide:** 👖\n\n'
        '✅ **Fit Types:**\n'
        '• **Slim Fit:** Modern, versatile\n'
        '• **Straight Fit:** Classic, comfortable\n'
        '• **Skinny:** Trendy, fitted\n'
        '• **Relaxed/Loose:** Comfort, streetwear\n'
        '• **Bootcut:** Retro, balanced\n\n'
        '✅ **Wash Guide:**\n'
        '• Dark wash: Formal, date night\n'
        '• Medium wash: Everyday casual\n'
        '• Light wash: Summer, casual\n'
        '• Black: Night out, smart casual\n\n'
        '✅ **Color Matching:**\n'
        '• Dark blue jeans: White, grey, black tops\n'
        '• Black jeans: Koi bhi color\n'
        '• Light blue: Navy, white, pastels\n\n'
        '✅ **Tuck Guide:**\n'
        '• Full tuck: Formal/blazer ke saath\n'
        '• Half tuck: Casual, relaxed\n'
        '• No tuck: T-shirt, hoodie\n\n'
        '💡 Buy 2-3 washes: Dark, medium, black';
  }

  // ==================== BAGS ====================

  String _bagsGuide() {
    return '**Bags Guide:** 👜\n\n'
        '✅ **Types:**\n'
        '• **Backpack:** Casual, practical\n'
        '• **Messenger/Crossbody:** Urban, stylish\n'
        '• **Briefcase:** Formal, professional\n'
        '• **Tote:** Versatile, everyday\n'
        '• **Clutch:** Party, minimal\n\n'
        '✅ **Color Rules:**\n'
        '• Neutral colors (black, brown, navy) = Safe\n'
        '• Bold colors = Statement piece\n'
        '• Match bag with shoes ya belt\n\n'
        '✅ **Size Guide:**\n'
        '• Small (clutch): Parties, evenings\n'
        '• Medium (crossbody): Daily use\n'
        '• Large (backpack): Travel, work\n\n'
        '✅ **Style Matching:**\n'
        '• Formal = Structured bag\n'
        '• Casual = Canvas/soft bags\n'
        '• Streetwear = Backpack/crossbody\n\n'
        '💡 Quality leather bag = Long-term investment!';
  }

  // ==================== PERFUME ====================

  String _perfumeGuide() {
    return '**Fragrance Guide:** 🌸\n\n'
        '✅ **Notes Explained:**\n'
        '• **Top Notes:** First 15 min (citrus, light)\n'
        '• **Heart Notes:** 15 min - 2 hours (floral, spicy)\n'
        '• **Base Notes:** 2+ hours (woody, musky)\n\n'
        '✅ **Occasion Guide:**\n'
        '☀️ Summer: Citrus, aquatic, light floral\n'
        '❄️ Winter: Woody, oriental, vanilla\n'
        '💼 Office: Light, fresh, not overpowering\n'
        '🎉 Party: Bold, spicy, oud\n'
        '💑 Date: Warm, sensual, vanilla\n\n'
        '✅ **Application Tips:**\n'
        '• Pulse points: Wrists, neck, behind ears\n'
        '• 2-3 sprays sufficient\n'
        '• 6-8 inches distance se spray karo\n'
        '• Shower ke baad lagao (skin absorb karti hai)\n\n'
        '✅ **Popular Fragrances:**\n'
        '• Men: Bleu de Chanel, Dior Sauvage, Versace Eros\n'
        '• Women: Chanel No 5, J\'adore, Miss Dior\n\n'
        '💡 Fragrance memory banata hai - signature scent choose karo!';
  }

  // ==================== GROOMING ====================

  String _groomingTips() {
    return '**Grooming Essentials:** 🧴\n\n'
        '✅ **Daily Routine:**\n'
        '• Face wash (morning + night)\n'
        '• Moisturizer with SPF\n'
        '• Lip balm\n'
        '• Deodorant/antiperspirant\n\n'
        '✅ **Hair Care:**\n'
        '• Shampoo 2-3 times/week\n'
        '• Conditioner every wash\n'
        '• Hair product: Matte clay (men), serum (women)\n'
        '• Regular trims (every 4-6 weeks)\n\n'
        '✅ **Skin Care:**\n'
        '• Sunscreen daily (SPF 30+)\n'
        '• Exfoliate 2x/week\n'
        '• Hydrate (water + moisturizer)\n'
        '• Night cream\n\n'
        '✅ **Nail Care:**\n'
        '• Trim weekly\n'
        '• Clean under nails\n'
        '• Moisturize cuticles\n\n'
        '✅ **Quick Wins:**\n'
        '• Fresh haircut = instant upgrade\n'
        '• Clean shoes = put-together look\n'
        '• Ironed clothes = polished appearance\n\n'
        '💡 Look good = Feel good = Do good!';
  }

  // ==================== BASIC RESPONSES ====================

  String _greeting() {
    switch (_lastDetectedLanguage) {
      case DetectedLanguage.urdu:
        return 'السلام علیکم! میں StyleMate ہوں، آپ کا AI فیشن اسٹنٹ! 👋\n\n'
            'بتائیں، آج کیا مدد چاہیے؟\n\n'
            'میں رنگ میل، لباس تجاویز، wardrobe مینجمنٹ - سب بتا سکتا ہوں!';
      case DetectedLanguage.hindi:
        return 'नमस्ते! मैं StyleMate हूँ, आपका AI fashion assistant! 👋\n\n'
            'बताइए, आज क्या मदद चाहिए?\n\n'
            'मैं color matching, outfit suggestions, wardrobe management - सब बता सकता हूँ!';
      case DetectedLanguage.punjabi:
        return 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ! ਮੈਂ StyleMate ਹਾਂ, ਤੁਹਾਡਾ AI fashion assistant! 👋\n\n'
            'ਦੱਸੋ, ਅੱਜ ਕੀ ਮਦਦ ਚਾਹੀਦੀ ਹੈ?\n\n'
            'ਮੈਂ ਰੰਗ ਮਿਲਾਉਣਾ, ਲਿਬਾਸ ਸੁਝਾਅ, wardrobe management - ਸਭ ਦੱਸ ਸਕਦਾ ਹਾਂ!';
      case DetectedLanguage.english:
        return 'Hello! I\'m StyleMate, your AI fashion assistant! 👋\n\n'
            'How can I help you today?\n\n'
            'I can help with color matching, outfit suggestions, wardrobe management - ask me anything!';
      case DetectedLanguage.romanUrdu:
        return _greetingRomanUrdu();
      case DetectedLanguage.romanHindi:
        return _greetingRomanUrdu();
    }
  }

  String _greetingRomanUrdu() {
    final greetings = [
      'Assalam-o-Alaikum! Main StyleMate hun 👋\n\n'
          'Batao, aaj kya madad chahiye?\n\n'
          'Main color matching, outfit suggestions, wardrobe management - sab bata sakta hun!',
      'Hey there! Kaise ho? 😊\n\n'
          'Main tumhara StyleMate assistant hun.\n'
          'Aaj fashion ke baare mein kya jaanna hai?\n\n'
          'Try karo: "White ke sath kya pehnu" ya "Outfit suggest karo"',
      'Hi! Welcome! 🌟\n\n'
          'Main offline hun, koi internet nahi chahiye.\n'
          'Kapde, color, outfit - jo poochna ho poochho!',
    ];
    return greetings[_random.nextInt(greetings.length)];
  }

  String _iamFine() {
    return _localize(
      'میں بالکل ٹھیک ہوں! 😄\n\nآج کیا کام ہے؟ فیشن سے متعلق کچھ پوچھو!\n\n'
          'مثالیں:\n• "نیلے کے ساتھ کیا پہنnoop"\n• "لباس تجویز کرو"\n• "Wardrobe کیا ہے"',
      'मैं बिल्कुल ठीक हूँ! 😄\n\nआज क्या काम है? Fashion से related कुछ पूछो!\n\n'
          'उदाहरण:\n• "नीले के साथ क्या पहनूं?"\n• "Outfit suggest करो"\n• "Wardrobe क्या है"',
      'ਮੈਂ ਬਿਲਕੁਲ ਠੀਕ ਹਾਂ! 😄\n\nਅੱਜ ਕੀ ਕੰਮ ਹੈ? Fashion ਤੋਂ ਸੰਬੰਧਿਤ ਕੁਝ ਪੁੱਛੋ!\n\n'
          'ਉਦਾਹਰਣ:\n• "ਨੀਲੇ ਨਾਲ ਕੀ ਪਹਿਨਾਂ?"\n• "Outfit ਸੁਝਾਓ"\n• "Wardrobe ਕੀ ਹੈ"',
      'I\'m doing great! 😄\n\nWhat can I help you with today?\n\n'
          'Try asking:\n• "What goes with blue?"\n• "Suggest an outfit"\n• "What\'s in my wardrobe"',
      'Main bilkul theek hun! 😄\n\n'
          'Aaj kya kaam hai? Fashion se related kuch poochho!\n\n'
          'Examples:\n• "Blue ke sath kya pehnu?"\n• "Outfit suggest karo"\n• "Wardrobe kya hai"',
    );
  }

  String _myName() {
    final storage = StorageService();
    final userName = storage.getUserName();
    final firstName = userName.split(' ').first;
    final wardrobe = storage.getWardrobe();
    final itemCount = wardrobe.length;
    
    final tops = wardrobe.where((i) => i.category == ClothingCategory.tops).length;
    final bottoms = wardrobe.where((i) => i.category == ClothingCategory.bottoms).length;
    
    return 'Mera naam **StyleMate** hai! 🌟\n\n'
        'Main **$firstName** tumhara personal AI fashion assistant hun.\n'
        'Main offline kaam karta hun - koi internet nahi chahiye.\n\n'
        '**Tumhara Wardrobe:**\n'
        '• Total: $itemCount items\n'
        '• Tops: $tops\n'
        '• Bottoms: $bottoms\n\n'
        '**Main kya kar sakta hun:**\n'
        '• 🎨 Color matching rules\n'
        '• 👔 Smart outfit suggestions\n'
        '• 📋 Wardrobe gap analysis\n'
        '• 🔄 Mix & match combinations\n'
        '• 🧵 Fabric & material guide\n'
        '• 🧺 Care & laundry tips\n'
        '• ✈️ Packing tips\n'
        '• 📊 Wear statistics';
  }

  String _youWelcome() {
    return 'Koi baat nahi! 😊 Hamesha khush raho aur stylish kapde pehno! ✨';
  }

  String _goodbye() {
    return 'Allah Hafiz! 👋 Phir milte hain.\n'
        'Apna khayal rakhna aur stylish raho! ✨';
  }

  String _helpText() {
    return _localize(
      'میں یہ سب کر سکتا ہوں: 🎯\n\n'
          '🎨 **رنگ میل:** • "سفید کے ساتھ کیا پہنnoop؟"\n'
          '• "سیاہ کے ساتھ کونسا رنگ؟"\n\n'
          '👔 **لباس تجاویز:** • "لباس تجویز کرو"\n'
          '• "رسمی کیا پہنnoop؟"\n\n'
          '📋 **Wardrobe مینجمنٹ:** • "Wardrobe کیا ہے"\n'
          '• "کیا missing ہے؟"\n\n'
          '🧵 **FLICT & دیکھ بھال:** • "Material guide"\n'
          '• "داغ کیسے ہٹائیں؟"\n\n'
          '✈️ **سفر:** • "Packing tips"\n'
          '• "Capsule wardrobe"\n\n'
          'بس کچھ بھی پوچھو! 😊',
      'मैं यह सब कर सकता हूँ: 🎯\n\n'
          '🎨 **Color Matching:** • "सफ़ेद के साथ क्या पहनूं?"\n'
          '• "काले के साथ कौन सा रंग?"\n\n'
          '👔 **Outfit Suggestions:** • "Outfit suggest करो"\n'
          '• "Formal क्या पहनूं?"\n\n'
          '📋 **Wardrobe Management:** • "Wardrobe क्या है"\n'
          '• "क्या missing है?"\n\n'
          '🧵 **Fabric & Care:** • "Material guide"\n'
          '• "दाग कैसे हटाएं?"\n\n'
          '✈️ **Travel:** • "Packing tips"\n'
          '• "Capsule wardrobe"\n\n'
          'बस कुछ भी पूछो! 😊',
      'ਮੈਂ ਇਹ ਸਭ ਕਰ ਸਕਦਾ ਹਾਂ: 🎯\n\n'
          '🎨 **ਰੰਗ ਮਿਲਾਉਣਾ:** • "ਚਿੱਟੇ ਨਾਲ ਕੀ ਪਹਿਨਾਂ?"\n'
          '• "ਕਾਲੇ ਨਾਲ ਕਿਹੜਾ ਰੰਗ?"\n\n'
          '👔 **ਲਿਬਾਸ ਸੁਝਾਅ:** • "ਲਿਬਾਸ ਸੁਝਾਓ"\n'
          '• "ਰਸਮੀ ਕੀ ਪਹਿਨਾਂ?"\n\n'
          '📋 **Wardrobe ਪ੍ਰਬੰਧਨ:** • "Wardrobe ਕੀ ਹੈ"\n'
          '• "ਕੀ missing ਹੈ?"\n\n'
          '🧵 **ਕੱਪੜਾ & ਦੇਖਭਾਲ:** • "Material guide"\n'
          '• "ਦਾਗ ਕਿਵੇਂ ਹਟਾਈਏ?"\n\n'
          '✈️ **ਯਾਤਰਾ:** • "Packing tips"\n'
          '• "Capsule wardrobe"\n\n'
          'ਬਸ ਕੁਝ ਵੀ ਪੁੱਛੋ! 😊',
      'I can help with all of this: 🎯\n\n'
          '🎨 **Color Matching:** • "What goes with white?"\n'
          '• "What color with black?"\n\n'
          '👔 **Outfit Suggestions:** • "Suggest an outfit"\n'
          '• "What to wear formal?"\n\n'
          '📋 **Wardrobe Management:** • "What\'s in my wardrobe?"\n'
          '• "What am I missing?"\n\n'
          '🧵 **Fabric & Care:** • "Material guide"\n'
          '• "How to remove stains?"\n\n'
          '✈️ **Travel:** • "Packing tips"\n'
          '• "Capsule wardrobe"\n\n'
          'Just ask anything! 😊',
      'Main ye sab kar sakta hun: 🎯\n\n'
          '🎨 **Color Matching:** • "White ke sath kya pehnu?"\n'
          '• "Black ke sath konsa color?"\n\n'
          '👔 **Outfit Suggestions:** • "Outfit suggest karo"\n'
          '• "Formal kya pehnu?"\n\n'
          '📋 **Wardrobe Management:** • "Wardrobe kya hai"\n'
          '• "Kya missing hai?"\n\n'
          '🧵 **Fabric & Care:** • "Material guide"\n'
          '• "Stain kaise hataye?"\n\n'
          '✈️ **Travel:** • "Packing tips"\n'
          '• "Capsule wardrobe"\n\n'
          'Bas kuch bhi poochho! 😊',
    );
  }

  String _wardrobeInfo(List<ClothingItem> wardrobe) {
    if (wardrobe.isEmpty) {
      return '**Tumhara wardrobe abhi khali hai!** 📭\n\n'
          'Kapde add karne ke liye:\n'
          '1. **Scan** tab pe jao (camera icon)\n'
          '2. Camera ya gallery se photo lo\n'
          '3. App automatically kapde analyze kar lega\n\n'
          'Ya manually bhi add kar sakte ho!';
    }

    final tops = wardrobe.where((i) => i.category == ClothingCategory.tops).length;
    final bottoms = wardrobe.where((i) => i.category == ClothingCategory.bottoms).length;
    final dresses = wardrobe.where((i) => i.category == ClothingCategory.dresses).length;
    final footwear = wardrobe.where((i) => i.category == ClothingCategory.footwear).length;
    final outerwear = wardrobe.where((i) => i.category == ClothingCategory.outerwear).length;
    final accessories = wardrobe.where((i) => i.category == ClothingCategory.accessories).length;
    final favorites = wardrobe.where((i) => i.isFavorite).length;
    final totalWears = wardrobe.fold(0, (sum, i) => sum + i.wearCount);

    // Color distribution
    final colorCounts = <String, int>{};
    for (var item in wardrobe) {
      colorCounts[item.primaryColor] = (colorCounts[item.primaryColor] ?? 0) + 1;
    }
    final topColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colorsStr = topColors.take(4).map((e) => '${e.key}(${e.value})').join(', ');

    return '**Tumhara Wardrobe:** 👗👔\n\n'
        '📦 **Total Items:** ${wardrobe.length}\n'
        '👕 **Tops:** $tops\n'
        '👖 **Bottoms:** $bottoms\n'
        '👗 **Dresses:** $dresses\n'
        '👟 **Footwear:** $footwear\n'
        '🧥 **Outerwear:** $outerwear\n'
        '💎 **Accessories:** $accessories\n'
        '❤️ **Favorites:** $favorites\n'
        '📊 **Total Wears:** $totalWears\n\n'
        '🎨 **Top Colors:** $colorsStr\n\n'
        'Aur kuch jaanna hai?';
  }

  String _howToAdd() {
    return '**Kapda Add Kaise Kare:** 📸\n\n'
        '**Step 1:** Bottom nav mein **Scan** tab pe jao\n\n'
        '**Step 2:** Choose karo:\n'
        '• 📷 Camera - Naya photo lo\n'
        '• 🖼️ Gallery - Existing photo select karo\n\n'
        '**Step 3:** App detect karega:\n'
        '• Kapde ka type\n'
        '• Color\n'
        '• Material\n'
        '• Season & Occasion\n\n'
        '**Step 4:** Edit karo aur **Add** karo!\n\n'
        'Bas ho gaya! 🎉';
  }

  String _howToDelete() {
    return '**Kapda Delete Kaise Kare:** 🗑️\n\n'
        '1. **Wardrobe** tab pe jao\n'
        '2. Kapde pe long press karo\n'
        '3. **Delete** icon pe tap karo\n\n'
        'Ya:\n'
        '1. Kapde ki detail screen pe jao\n'
        '2. **Delete** button dabao\n\n'
        '⚠️ Delete baad wapas nahi aayega!';
  }

  String _weatherTip() {
    return '**Weather ke Hisaab se Kapde:** 🌤️\n\n'
        '☀️ **Garmi (Summer):**\n'
        '• Light colors (white, beige, pastel)\n'
        '• Cotton & linen fabric\n'
        '• Shorts, t-shirts, sandals\n\n'
        '❄️ **Thand (Winter):**\n'
        '• Dark colors (black, navy, maroon)\n'
        '• Wool, fleece fabric\n'
        '• Jackets, sweaters, boots\n\n'
        '🌧️ **Barish (Rainy):**\n'
        '• Waterproof jackets\n'
        '• Dark colors (stains nahi dikhte)\n'
        '• Closed shoes';
  }

  String _seasonTip() {
    return '**Season Based Dressing:** 🗓️\n\n'
        '🌸 **Spring:** Light layers, floral prints, pastels\n'
        '☀️ **Summer:** Cotton, linen, light colors\n'
        '🍂 **Autumn:** Earth tones, layered looks, boots\n'
        '❄️ **Winter:** Wool, fleece, dark colors, layers';
  }

  String _occasionTip() {
    return '**Occasion Based Outfits:** 🎭\n\n'
        '💼 **Formal:** Blazers, dress shirts, leather shoes\n'
        '🎉 **Party:** Bold colors, statement pieces\n'
        '🏃 **Casual:** Jeans, t-shirts, sneakers\n'
        '💑 **Date:** Smart casual, well-fitted\n\n'
        'Try karo: "Formal kya pehnu" ya "Party outfit"';
  }

  String _careTip() {
    return '**Kapdon ki Care Guide:** 🧺\n\n'
        '👕 **Cotton:** Normal wash, cold water\n'
        '👖 **Denim:** Andar se dhoye, kam dhoye\n'
        '🧥 **Wool:** Hand wash, dry flat\n'
        '👗 **Silk:** Dry clean, cold water\n'
        '👟 **Shoes:** Regular cleaning, waterproof\n\n'
        '💡 Care label zaroor padho!';
  }

  String _styleTip() {
    return '**Top 5 Style Tips:** ✨\n\n'
        '1. **Fit is King** - Achhi fitting sabse important\n'
        '2. **Wardrobe Basics** - White shirt, blue jeans, black blazer\n'
        '3. **Accessorize Smart** - Watch, belt, sunglasses\n'
        '4. **Color Coordination** - Max 3 colors per outfit\n'
        '5. **Confidence** - Jo bhi pehno, confidence ke saath!';
  }

  String _brandTip() {
    return '**Brand Tips:** 🏷️\n\n'
        '💰 **Budget:** Zara, H&M, Uniqlo\n'
        '💎 **Mid:** Nike, Adidas, Levi\'s\n'
        '👑 **Premium:** Armani, Gucci\n\n'
        '💡 Brand se zyada fit aur quality dekho!';
  }

  String _priceTip() {
    return '**Smart Shopping:** 💰\n\n'
        '• End of season sales\n'
        '• Basics mein quality kharido\n'
        '• Trendy items sasti le lo\n'
        '• Capsule wardrobe banao';
  }

  String _favoriteTip(List<ClothingItem> wardrobe) {
    final favs = wardrobe.where((i) => i.isFavorite).toList();
    if (favs.isEmpty) {
      return '**Abhi koi favorite nahi hai!** ❤️\n\n'
          'Wardrobe mein jo pasand aaye uspe ❤️ icon dabao.';
    }
    final names = favs.take(5).map((i) => '• ${i.name} (${i.primaryColor})').join('\n');
    return '**Tumhare Favorites:** ❤️\n\n'
        '$names\n\nTotal: ${favs.length} items';
  }

  String _profileTip() {
    return '**Profile Screen:** 👤\n\n'
        'Profile tab pe dekh sakte ho:\n'
        '• Wardrobe statistics\n'
        '• Color distribution\n'
        '• Category breakdown\n'
        '• Settings';
  }

  String _settingsTip() {
    return '**Settings:** ⚙️\n\n'
        'Profile > Settings:\n'
        '• Notifications\n'
        '• Language\n'
        '• Appearance\n'
        '• Data backup\n'
        '• Help & About';
  }

  String _virtualTryOnTip() {
    return '**Virtual Try-On:** 👗✨\n\n'
        '1. Wardrobe tab pe jao\n'
        '2. Kapda select karo\n'
        '3. "Virtual Try-On" pe click karo\n\n'
        'Features: 360° rotation, Zoom, Flip';
  }

  String _photoTip() {
    return '**Photo Tips:** 📸\n\n'
        '1. Natural light use karo\n'
        '2. Clean background rakho\n'
        '3. Full outfit dikhao\n'
        '4. 1080p+ resolution\n\n'
        '💡 Achhi photo = Achhi AI analysis!';
  }

  String _fitTip() {
    return '**Fit Guide:** 📏\n\n'
        '👔 **Shirt:** Shoulder seams shoulder pe\n'
        '👖 **Pants:** Comfortable waist, ankle length\n'
        '👗 **Dress:** Comfortable fit, occasion-appropriate\n\n'
        '💡 Har brand ka size alag hai!';
  }

  String _fallback(String msg) {
    final fallbacks = [
      'Interesting sawaal hai! 🤔\n\n'
          'Main fashion expert hun. Try karo:\n'
          '• "White ke sath kya pehnu?"\n'
          '• "Outfit suggest karo"\n'
          '• "Color matching"\n'
          '• "Help" - sab dekho',
      'Hmm, ye samajh nahi aaya 🤷\n\n'
          'Kuch specific poochho jaise:\n'
          '• "Black ke sath konsa color?"\n'
          '• "Formal outfit"\n'
          '• "Wardrobe gaps"',
      'Fashion ke baare mein kuch poochho! 💡\n\n'
          'Main help kar sakta hun:\n'
          '• Color matching\n'
          '• Outfit suggestions\n'
          '• Fabric guide\n'
          '• Care tips',
    ];
    return fallbacks[_random.nextInt(fallbacks.length)];
  }

  String greetingMessage() {
    final storage = StorageService();
    final userName = storage.getUserName();
    final firstName = userName.split(' ').first;
    final wardrobe = storage.getWardrobe();
    final itemCount = wardrobe.length;
    
    final greetings = [
      'Hello **$firstName**! 👋\n\n'
          'Main tumhara **StyleMate AI** hun.\n'
          'Tumhare wardrobe mein **$itemCount items** hain.\n\n'
          '**Kuch bhi poochho:**\n'
          '• "White ke sath kya pehnu?"\n'
          '• "Outfit suggest karo"\n'
          '• "Kya missing hai?"\n\n'
          'Bas type karo aur main jawab dunga! 😊',
      
      'Hey **$firstName**! 🌟\n\n'
          'Kaise ho? Main ready hun tumhari help karne ke liye!\n'
          'Tumhare paas **$itemCount items** hain wardrobe mein.\n\n'
          '**Try karo:**\n'
          '• "Color match karo"\n'
          '• "Style tips do"\n'
          '• "Wardrobe kya hai"\n\n'
          'Main hamesha available hun! 💪',
      
      'Assalam-o-Alaikum **$firstName**! 🙏\n\n'
          'Main tumhara personal fashion assistant hun.\n'
          'Abhi tumhare wardrobe mein $itemCount items hain.\n\n'
          '**Pooch sakte ho:**\n'
          '• "Outfit suggest karo"\n'
          '• "Layering tips do"\n'
          '• "Packing tips"\n\n'
          'Kya jaanna hai? 😊',
    ];
    
    return greetings[_random.nextInt(greetings.length)];
  }

  List<String> getQuickReplies() {
    return [
      'Wardrobe le jao',
      'Color match karo',
      'Outfit suggest karo',
      'Settings kholo',
      'Help',
    ];
  }

  // ==================== CHAT HISTORY ====================

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    try {
      final box = await Hive.openBox(_chatHistoryBox);
      final today = DateTime.now().toIso8601String().split('T')[0];
      final history = messages.map((m) => m.toJson()).toList();
      await box.put('history_$today', history);
      
      // Clean old history (older than 30 days)
      final keys = box.keys.where((k) => k.toString().startsWith('history_')).toList();
      for (final key in keys) {
        final dateStr = key.toString().replaceFirst('history_', '');
        try {
          final date = DateTime.parse(dateStr);
          if (DateTime.now().difference(date).inDays > _maxHistoryDays) {
            await box.delete(key);
          }
        } catch (e) {}
      }
    } catch (e) {}
  }

  Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final box = await Hive.openBox(_chatHistoryBox);
      final today = DateTime.now().toIso8601String().split('T')[0];
      final data = box.get('history_$today');
      if (data != null && data is List) {
        return data.map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m))).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getRecentHistory({int days = 7}) async {
    try {
      final box = await Hive.openBox(_chatHistoryBox);
      final result = <Map<String, dynamic>>[];
      
      for (int i = 0; i < days; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        final data = box.get('history_$dateStr');
        if (data != null && data is List) {
          result.add({
            'date': dateStr,
            'messages': data.length,
          });
        }
      }
      return result;
    } catch (e) {}
    return [];
  }

  String getChatSummary() {
    final storage = StorageService();
    final name = storage.getUserName();
    final firstName = name.split(' ').first;
    return _localize(
      '**$firstName**, tumhari aaj ki chat history:\n'
          'Tumne kal bhi fashion tips li thi. Keep going! 🌟',
      '**$firstName**, आपकी आज की chat history:\n'
          'आपने कल भी fashion tips ली थीं। Keep going! 🌟',
      '**$firstName**, ਤੁਹਾਡੀ ਅੱਜ ਦੀ chat history:\n'
          'ਤੁਸੀਂ ਕੱਲ੍ਹ ਵੀ fashion tips ਲਈ ਸੀ। Keep going! 🌟',
      '**$firstName**, here\'s your chat summary:\n'
          'You got fashion tips yesterday too. Keep going! 🌟',
      '**$firstName**, tumhari aaj ki chat history:\n'
          'Tumne kal bhi fashion tips li thi. Keep going! 🌟',
    );
  }
}
