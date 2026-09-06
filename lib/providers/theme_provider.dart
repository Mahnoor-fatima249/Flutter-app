import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _assistantBgKey = 'assistant_bg';
  static const String _darkModeKey = 'dark_mode';

  late Box _settings;
  String _currentTheme = 'default';
  String _assistantBackground = 'default';
  bool _isDarkMode = false;

  String get currentTheme => _currentTheme;
  String get assistantBackground => _assistantBackground;
  bool get isDarkMode => _isDarkMode;

  static const Map<String, Map<String, dynamic>> themes = {
    'default': {
      'name': 'Royal Purple',
      'primary': Color(0xFF6C63FF),
      'secondary': Color(0xFFFF6584),
      'gradient': [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
      'icon': '💜',
    },
    'ocean': {
      'name': 'Ocean',
      'primary': Color(0xFF0077B6),
      'secondary': Color(0xFF00B4D8),
      'gradient': [Color(0xFF023E8A), Color(0xFF0077B6), Color(0xFF0096C7)],
      'icon': '🌊',
    },
    'forest': {
      'name': 'Forest',
      'primary': Color(0xFF2D6A4F),
      'secondary': Color(0xFF52B788),
      'gradient': [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
      'icon': '🌲',
    },
    'sunset': {
      'name': 'Sunset',
      'primary': Color(0xFFE94560),
      'secondary': Color(0xFFFF6B6B),
      'gradient': [Color(0xFF533483), Color(0xFFE94560), Color(0xFFFF6B6B)],
      'icon': '🌅',
    },
    'royal': {
      'name': 'Royal Gold',
      'primary': Color(0xFFB8860B),
      'secondary': Color(0xFFFFD700),
      'gradient': [Color(0xFF1A1A2E), Color(0xFF3D1C02), Color(0xFF6B4423)],
      'icon': '👑',
    },
    'rose': {
      'name': 'Rose',
      'primary': Color(0xFFE63946),
      'secondary': Color(0xFFFFB4C2),
      'gradient': [Color(0xFF641220), Color(0xFFE63946), Color(0xFFFFB4C2)],
      'icon': '🌹',
    },
    'midnight': {
      'name': 'Midnight',
      'primary': Color(0xFF4A6FA5),
      'secondary': Color(0xFF7EC8E3),
      'gradient': [Color(0xFF000814), Color(0xFF001D3D), Color(0xFF003566)],
      'icon': '🌙',
    },
    'golden': {
      'name': 'Golden Hour',
      'primary': Color(0xFFD4A574),
      'secondary': Color(0xFFFFCBA4),
      'gradient': [Color(0xFF6B4423), Color(0xFFB8860B), Color(0xFFD4A574)],
      'icon': '✨',
    },
    'cherry': {
      'name': 'Cherry',
      'primary': Color(0xFFDC143C),
      'secondary': Color(0xFFFF6B81),
      'gradient': [Color(0xFF2C0010), Color(0xFF8B0000), Color(0xFFDC143C)],
      'icon': '🍒',
    },
    'mint': {
      'name': 'Mint',
      'primary': Color(0xFF00BFA6),
      'secondary': Color(0xFF64FFDA),
      'gradient': [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
      'icon': '🍃',
    },
    'lavender': {
      'name': 'Lavender',
      'primary': Color(0xFF9B59B6),
      'secondary': Color(0xFFD7BDE2),
      'gradient': [Color(0xFF2C003E), Color(0xFF6C3483), Color(0xFF9B59B6)],
      'icon': '💜',
    },
    'coral': {
      'name': 'Coral',
      'primary': Color(0xFFFF6F61),
      'secondary': Color(0xFFFFB3AB),
      'gradient': [Color(0xFF5C1A1B), Color(0xFFBC3B3A), Color(0xFFFF6F61)],
      'icon': '🪸',
    },
    'neon': {
      'name': 'Neon',
      'primary': Color(0xFF00FF87),
      'secondary': Color(0xFFFF00FF),
      'gradient': [Color(0xFF0D0D0D), Color(0xFF1A1A2E), Color(0xFF16213E)],
      'icon': '💚',
    },
    'peach': {
      'name': 'Peach',
      'primary': Color(0xFFFF9A76),
      'secondary': Color(0xFFFFDAC1),
      'gradient': [Color(0xFF5C3317), Color(0xFFCC7A3F), Color(0xFFFF9A76)],
      'icon': '🍑',
    },
    'sky': {
      'name': 'Sky Blue',
      'primary': Color(0xFF0096C7),
      'secondary': Color(0xFF90E0EF),
      'gradient': [Color(0xFF003049), Color(0xFF0077B6), Color(0xFF0096C7)],
      'icon': '☀️',
    },
    'slate': {
      'name': 'Slate',
      'primary': Color(0xFF475569),
      'secondary': Color(0xFF94A3B8),
      'gradient': [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
      'icon': '🪨',
    },
    'noir': {
      'name': 'Noir',
      'primary': Color(0xFF212121),
      'secondary': Color(0xFF616161),
      'gradient': [Color(0xFF000000), Color(0xFF212121), Color(0xFF424242)],
      'icon': '🖤',
    },
    'champagne': {
      'name': 'Champagne',
      'primary': Color(0xFFF7E7CE),
      'secondary': Color(0xFFD4A574),
      'gradient': [Color(0xFF3D2B1F), Color(0xFF6B4423), Color(0xFFD4A574)],
      'icon': '🥂',
    },
    'burgundy': {
      'name': 'Burgundy',
      'primary': Color(0xFF800020),
      'secondary': Color(0xFFC9A9A6),
      'gradient': [Color(0xFF2C0010), Color(0xFF5C0020), Color(0xFF800020)],
      'icon': '🍷',
    },
    'navy': {
      'name': 'Classic Navy',
      'primary': Color(0xFF001F3F),
      'secondary': Color(0xFF7FDBFF),
      'gradient': [Color(0xFF000814), Color(0xFF001F3F), Color(0xFF003566)],
      'icon': '⚓',
    },
    'olive': {
      'name': 'Olive',
      'primary': Color(0xFF808000),
      'secondary': Color(0xFFBBC34C),
      'gradient': [Color(0xFF3B3A00), Color(0xFF5C5A00), Color(0xFF808000)],
      'icon': '🫒',
    },
    'terracotta': {
      'name': 'Terracotta',
      'primary': Color(0xFFE2725B),
      'secondary': Color(0xFFFFCBA4),
      'gradient': [Color(0xFF5C2E1A), Color(0xFF9C4A2A), Color(0xFFE2725B)],
      'icon': '🏺',
    },
    'mauve': {
      'name': 'Mauve',
      'primary': Color(0xFFE0B0FF),
      'secondary': Color(0xFF9B59B6),
      'gradient': [Color(0xFF2C003E), Color(0xFF5B2C6F), Color(0xFF9B59B6)],
      'icon': '💟',
    },
    'steel': {
      'name': 'Steel',
      'primary': Color(0xFF71797E),
      'secondary': Color(0xFFACB2BF),
      'gradient': [Color(0xFF1B1B1B), Color(0xFF36454F), Color(0xFF71797E)],
      'icon': '⚙️',
    },
    'ivory': {
      'name': 'Ivory',
      'primary': Color(0xFFFFFFF0),
      'secondary': Color(0xFFD4C5A9),
      'gradient': [Color(0xFF5C5A4E), Color(0xFF8B8573), Color(0xFFD4C5A9)],
      'icon': '🦢',
    },
    'teal': {
      'name': 'Teal',
      'primary': Color(0xFF008080),
      'secondary': Color(0xFF80CBC4),
      'gradient': [Color(0xFF003333), Color(0xFF005F5F), Color(0xFF008080)],
      'icon': '🦚',
    },
    'blush': {
      'name': 'Blush',
      'primary': Color(0xFFDE5D83),
      'secondary': Color(0xFFFFC2D1),
      'gradient': [Color(0xFF5C1A2A), Color(0xFF9C3A5A), Color(0xFFDE5D83)],
      'icon': '🌸',
    },
    'charcoal': {
      'name': 'Charcoal',
      'primary': Color(0xFF36454F),
      'secondary': Color(0xFF8D99AE),
      'gradient': [Color(0xFF1B1B1B), Color(0xFF2D2D2D), Color(0xFF36454F)],
      'icon': '🖤',
    },
    'caramel': {
      'name': 'Caramel',
      'primary': Color(0xFFAF8E60),
      'secondary': Color(0xFFE6CBA8),
      'gradient': [Color(0xFF5C4A2A), Color(0xFF8B7340), Color(0xFFAF8E60)],
      'icon': '🍯',
    },
    'emerald': {
      'name': 'Emerald',
      'primary': Color(0xFF50C878),
      'secondary': Color(0xFF90EE90),
      'gradient': [Color(0xFF004D40), Color(0xFF1B5E20), Color(0xFF2E7D32)],
      'icon': '💎',
    },
    'platinum': {
      'name': 'Platinum',
      'primary': Color(0xFFE5E4E2),
      'secondary': Color(0xFFB0B0B0),
      'gradient': [Color(0xFF2C2C2C), Color(0xFF505050), Color(0xFF808080)],
      'icon': '💠',
    },
  };

  // AI Assistant Backgrounds
  static const Map<String, Map<String, dynamic>> assistantBackgrounds = {
    'default': {
      'name': 'Default',
      'colors': [Color(0xFFF8F9FE), Color(0xFFFFFFFF)],
      'icon': '🤍',
    },
    'dark': {
      'name': 'Dark',
      'colors': [Color(0xFF121212), Color(0xFF1E1E1E)],
      'icon': '🖤',
    },
    'ocean': {
      'name': 'Ocean',
      'colors': [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
      'icon': '🌊',
    },
    'sunset': {
      'name': 'Sunset',
      'colors': [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
      'icon': '🌅',
    },
    'forest': {
      'name': 'Forest',
      'colors': [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      'icon': '🌲',
    },
    'lavender': {
      'name': 'Lavender',
      'colors': [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
      'icon': '💜',
    },
    'rose': {
      'name': 'Rose',
      'colors': [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      'icon': '🌹',
    },
    'peach': {
      'name': 'Peach',
      'colors': [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      'icon': '🍑',
    },
    'mint': {
      'name': 'Mint',
      'colors': [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
      'icon': '🍃',
    },
    'midnight': {
      'name': 'Midnight',
      'colors': [Color(0xFF1A1A2E), Color(0xFF16213E)],
      'icon': '🌙',
    },
    'golden': {
      'name': 'Golden',
      'colors': [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
      'icon': '✨',
    },
    'cherry': {
      'name': 'Cherry',
      'colors': [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
      'icon': '🍒',
    },
  };

  Future<void> init() async {
    _settings = await Hive.openBox('theme_settings');
    _currentTheme = _settings.get(_themeKey, defaultValue: 'default');
    _assistantBackground = _settings.get(_assistantBgKey, defaultValue: 'default');
    _isDarkMode = _settings.get(_darkModeKey, defaultValue: false);
  }

  void setTheme(String themeName) {
    _currentTheme = themeName;
    _settings.put(_themeKey, themeName);
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _settings.put(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  void setAssistantBackground(String bgName) {
    _assistantBackground = bgName;
    _settings.put(_assistantBgKey, bgName);
    notifyListeners();
  }

  Color get primaryColor {
    return themes[_currentTheme]?['primary'] ?? const Color(0xFF6C63FF);
  }

  Color get secondaryColor {
    return themes[_currentTheme]?['secondary'] ?? const Color(0xFFFF6584);
  }

  List<Color> get gradientColors {
    final gradient = themes[_currentTheme]?['gradient'];
    if (gradient != null) return List<Color>.from(gradient);
    return const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)];
  }

  LinearGradient get primaryGradient {
    return LinearGradient(
      colors: gradientColors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  List<Color> get assistantColors {
    final colors = assistantBackgrounds[_assistantBackground]?['colors'];
    if (colors != null) return List<Color>.from(colors);
    return const [Color(0xFFF8F9FE), Color(0xFFFFFFFF)];
  }

  LinearGradient get assistantGradient {
    return LinearGradient(
      colors: assistantColors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}
