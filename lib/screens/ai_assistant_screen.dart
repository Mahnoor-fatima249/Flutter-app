import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/theme_provider.dart';
import '../services/ai_assistant_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'wardrobe_screen.dart';
import 'camera_screen.dart';
import 'profile_screen.dart';
import 'tools_screen.dart';
import 'color_palette_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'mix_match_screen.dart';
import 'outfit_suggestions_screen.dart';
import 'wishlist_screen.dart';
import 'budget_screen.dart';
import 'travel_planner_screen.dart';
import 'laundry_screen.dart';
import 'style_dna_screen.dart';
import 'virtual_tryon_screen.dart';

class AIAssistantScreen extends StatefulWidget {
  final String? initialQuery;

  const AIAssistantScreen({super.key, this.initialQuery});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final AIAssistantService _assistant = AIAssistantService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();

  bool _isDarkMode = false;
  bool _isSpeaking = false;
  bool _voiceEnabled = true;
  bool _voiceRequested = false;
  bool _isListening = false;
  bool _showQuickActions = true;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    _loadChatHistory();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery!);
      });
    }
  }

  void _loadChatHistory() async {
    final history = await _assistant.loadChatHistory();
    if (history.isNotEmpty && mounted) {
      setState(() {
        _messages.addAll(history);
      });
      _scrollToBottom();
    } else {
      _addBotMessage(_assistant.greetingMessage());
    }
  }

  void _initTts() async {
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    final engines = await _tts.getEngines;
    if (engines.isNotEmpty) {
      await _tts.setEngine(engines.first);
    }
  }

  void _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done' || status == 'cancelled') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
      );
    } catch (e) {
      // Speech not available on this device
    }
  }

  String _getSpeechLocale() {
    final storage = StorageService();
    final preferred = storage.getPreferredLanguage();
    switch (preferred) {
      case 'urdu':
        return 'ur-PK';
      case 'punjabi':
        return 'pa-IN';
      case 'hindi':
        return 'hi-IN';
      case 'english':
      default:
        return 'en-US';
    }
  }

  String _getTtsLocale() {
    final storage = StorageService();
    final preferred = storage.getPreferredLanguage();
    switch (preferred) {
      case 'urdu':
        return 'ur-PK';
      case 'punjabi':
        return 'pa-IN';
      case 'hindi':
        return 'hi-IN';
      case 'english':
      default:
        return 'en-US';
    }
  }

  void _startListening() async {
    try {
      if (!_speech.isAvailable) {
        await _speech.initialize();
      }
      
      if (!_speech.isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available on this device'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isListening = true;
        _voiceRequested = true;
        _lastWords = '';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
            _controller.text = _lastWords;
          });
          
          if (result.finalResult) {
            setState(() => _isListening = false);
            if (_lastWords.isNotEmpty) {
              _sendMessage(_lastWords);
            }
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: _getSpeechLocale(),
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      setState(() => _isListening = false);
    }
  }

  void _stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {}
    setState(() => _isListening = false);
  }

  void _speak(String text) async {
    if (!_voiceEnabled) return;
    
    final ttsLocale = _getTtsLocale();
    await _tts.setLanguage(ttsLocale);
    
    final cleanText = text
        .replaceAll(RegExp(r'\*\*.*?\*\*'), '')
        .replaceAll(RegExp(r'[^\w\s,.\n!?\u0600-\u06FF\u0750-\u077F\u0900-\u097F\u0A00-\u0A7F]'), '')
        .replaceAll('\n', ' ')
        .trim();
    if (cleanText.isNotEmpty) {
      await _tts.speak(cleanText);
      setState(() => _isSpeaking = true);
    }
  }

  void _stopSpeaking() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
      _showQuickActions = false;
    });
    _scrollToBottom();
    if (_voiceRequested) {
      _voiceRequested = false;
      Future.delayed(const Duration(milliseconds: 300), () => _speak(text));
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _stopSpeaking();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _showQuickActions = false;
    });
    _controller.clear();
    _scrollToBottom();

    final wardrobe = context.read<WardrobeProvider>().wardrobe;

    // Check for navigation commands first
    final navResult = _checkNavigationCommand(text);
    if (navResult != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _addBotMessage(navResult['message']);
        if (navResult['navigate'] == true) {
          Future.delayed(const Duration(milliseconds: 800), () {
            _navigateToScreen(navResult['screen']);
          });
        }
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      final response = _assistant.getResponse(text, wardrobe);
      _addBotMessage(response);
      _assistant.saveChatHistory(_messages);
    });
  }

  Map<String, dynamic>? _checkNavigationCommand(String text) {
    final msg = text.toLowerCase().trim();

    // Navigation patterns - "le jao", "open", "jao", "dikhao", etc.
    final navPatterns = {
      'settings': ['setting', 'settings', 'setting pa', 'settings pa'],
      'home': ['home', 'home pa', 'home page', 'ghar', 'main page'],
      'wardrobe': ['wardrobe', 'wardrobe pa', 'kapde', 'closet'],
      'scan': ['scan', 'scan pa', 'camera', 'photo', 'picture', 'capture'],
      'tools': ['tool', 'tools', 'tools pa', 'style tools'],
      'profile': ['profile', 'profile pa', 'mera profile'],
      'color_palette': ['color palette', 'color mixer', 'colour palette', 'rang'],
      'mix_match': ['mix match', 'mix & match', 'combine', 'jod', 'match'],
      'outfit': ['outfit', 'outfit suggest', 'outfit pa', 'suggestion'],
      'wishlist': ['wishlist', 'wish list', 'shopping', 'kharidna'],
      'budget': ['budget', 'budget pa', 'paisa', 'kharcha', 'expense'],
      'travel': ['travel', 'trip', 'safar', 'packing'],
      'laundry': ['laundry', 'dhobi', 'kapde dhoye', 'wash'],
      'style_dna': ['style dna', 'style analysis', 'mera style'],
      'virtual_tryon': ['virtual', 'try on', 'tryon', 'ar', 'virtual try'],
      'support': ['support', 'help page', 'contact', 'email'],
    };

    final navKeywords = {
      'le jao': null,
      'le chalo': null,
      'open': null,
      'jao': null,
      'dikhao': null,
      'kholo': null,
    };

    bool hasNavIntent = false;
    for (final keyword in navKeywords.keys) {
      if (msg.contains(keyword)) {
        hasNavIntent = true;
        break;
      }
    }

    if (!hasNavIntent) return null;

    for (final entry in navPatterns.entries) {
      for (final pattern in entry.value) {
        if (msg.contains(pattern)) {
          return {
            'screen': entry.key,
            'navigate': true,
            'message': _getNavMessage(entry.key),
          };
        }
      }
    }

    return null;
  }

  String _getNavMessage(String screen) {
    switch (screen) {
      case 'settings':
        return 'Settings khol raha hun... ⚙️';
      case 'home':
        return 'Home page pe le ja raha hun... 🏠';
      case 'wardrobe':
        return 'Wardrobe khol raha hun... 👗';
      case 'scan':
        return 'Camera/Scan khol raha hun... 📸';
      case 'tools':
        return 'Tools khol raha hun... 🛠️';
      case 'profile':
        return 'Profile khol raha hun... 👤';
      case 'color_palette':
        return 'Color Palette khol raha hun... 🎨';
      case 'mix_match':
        return 'Mix & Match khol raha hun... 🔄';
      case 'outfit':
        return 'Outfit Suggestions khol raha hun... 👔';
      case 'wishlist':
        return 'Wishlist khol raha hun... 🛍️';
      case 'budget':
        return 'Budget khol raha hun... 💰';
      case 'travel':
        return 'Travel Planner khol raha hun... ✈️';
      case 'laundry':
        return 'Laundry khol raha hun... 🧺';
      case 'style_dna':
        return 'Style DNA khol raha hun... 🧬';
      case 'virtual_tryon':
        return 'Virtual Try-On khol raha hun... 👗✨';
      case 'support':
        return 'Support khol raha hun... 📧';
      default:
        return 'Le ja raha hun...';
    }
  }

  void _navigateToScreen(String screen) {
    Widget? targetScreen;
    switch (screen) {
      case 'settings':
        targetScreen = const SettingsScreen();
        break;
      case 'home':
        Navigator.popUntil(context, (route) => route.isFirst);
        return;
      case 'wardrobe':
        Navigator.pop(context);
        // Switch to wardrobe tab
        return;
      case 'scan':
        Navigator.pop(context);
        return;
      case 'tools':
        targetScreen = const ToolsScreen();
        break;
      case 'profile':
        Navigator.pop(context);
        return;
      case 'color_palette':
        targetScreen = const ColorPaletteScreen();
        break;
      case 'mix_match':
        targetScreen = const MixMatchScreen();
        break;
      case 'outfit':
        targetScreen = const OutfitSuggestionsScreen();
        break;
      case 'wishlist':
        targetScreen = const WishlistScreen();
        break;
      case 'budget':
        targetScreen = const BudgetScreen();
        break;
      case 'travel':
        targetScreen = const TravelPlannerScreen();
        break;
      case 'laundry':
        targetScreen = const LaundryScreen();
        break;
      case 'style_dna':
        targetScreen = const StyleDnaScreen();
        break;
      case 'virtual_tryon':
        targetScreen = const VirtualTryOnScreen();
        break;
      case 'support':
        targetScreen = const SupportScreen();
        break;
    }
    if (targetScreen != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen!));
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color get _bgColor {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.assistantColors;
    return _isDarkMode ? const Color(0xFF121212) : colors[0];
  }

  Color get _cardColor {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.assistantColors;
    return _isDarkMode ? const Color(0xFF1E1E1E) : colors.length > 1 ? colors[1] : Colors.white;
  }
  Color get _textColor => _isDarkMode ? Colors.white : AppTheme.textPrimary;
  Color get _textSec => _isDarkMode ? Colors.grey[400]! : AppTheme.textSecondary;
  Color get _inputBg => _isDarkMode ? const Color(0xFF2A2A2A) : AppTheme.backgroundColor;

  void _showWallpaperPicker() {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat Wallpaper',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: ThemeProvider.assistantBackgrounds.length,
                itemBuilder: (context, index) {
                  final bg = ThemeProvider.assistantBackgrounds.entries.elementAt(index);
                  final isSelected = themeProvider.assistantBackground == bg.key;
                  final colors = bg.value['colors'] as List<Color>;
                  return GestureDetector(
                    onTap: () {
                      themeProvider.setAssistantBackground(bg.key);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppTheme.primaryColor, width: 3)
                            : Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            bg.value['icon'] as String,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bg.value['name'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StyleMate AI',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _voiceEnabled ? Icons.volume_up : Icons.volume_off,
              color: _voiceEnabled ? AppTheme.primaryColor : Colors.grey,
              size: 22,
            ),
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (!_voiceEnabled) _stopSpeaking();
            },
          ),
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: _isDarkMode ? Colors.yellow : AppTheme.primaryColor,
              size: 22,
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          IconButton(
            icon: Icon(Icons.wallpaper, color: AppTheme.primaryColor, size: 22),
            onPressed: _showWallpaperPicker,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor, size: 22),
            onPressed: () {
              _stopSpeaking();
              setState(() {
                _messages.clear();
                _showQuickActions = true;
              });
              _addBotMessage(_assistant.greetingMessage());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_messages.isEmpty) _buildQuickActionsHeader(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildChatList(),
          ),
          _buildQuickReplies(),
          _buildInputArea(),
        ],
      ),
    );
  }

  // ==================== QUICK ACTIONS HEADER ====================

  Widget _buildQuickActionsHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [const Color(0xFF1E3A5F), const Color(0xFF2A4A7F)]
              : [const Color(0xFF667eea), const Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.yellow, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Neeche buttons se turant poocho',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildActionCard(Icons.home, 'Home Page', 'Home page pe le jao', AppTheme.primaryColor, 'home le jao'),
          const SizedBox(height: 10),
          _buildActionCard(Icons.checkroom, 'Wardrobe', 'Wardrobe kholo', AppTheme.secondaryColor, 'wardrobe le jao'),
          const SizedBox(height: 10),
          _buildActionCard(Icons.camera_alt, 'Scan Clothes', 'Camera se kapde scan karo', AppTheme.accentColor, 'scan le jao'),
          const SizedBox(height: 10),
          _buildActionCard(Icons.palette, 'Color Mixer', 'Color palette kholo', const Color(0xFF667eea), 'color palette le jao'),
          const SizedBox(height: 10),
          _buildActionCard(Icons.palette, 'Color Matching', 'Kaunsa colour kiske saath?', AppTheme.primaryColor, 'color match karo'),
          const SizedBox(height: 10),
          _buildActionCard(Icons.checkroom, 'Outfit Suggest', 'Wardrobe se best outfit', AppTheme.secondaryColor, 'outfit suggest karo'),
          const SizedBox(height: 10),
          _buildActionCard(Icons.lightbulb_outline, 'Style Tips', 'Fashion advice lo', AppTheme.accentColor, 'style tips do'),
          const SizedBox(height: 10),
          _buildActionCard(Icons.settings, 'Settings', 'Settings kholo', Colors.grey, 'settings le jao'),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, Color color, String query) {
    return GestureDetector(
      onTap: () => _sendMessage(query),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _textSec,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  // ==================== CHAT ====================

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildChatBubble(_messages[index]),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) _buildBotAvatar(),
            if (!isUser) const SizedBox(width: 8),
            Flexible(
              child: GestureDetector(
                onLongPress: () {
                  if (!isUser) {
                    if (_isSpeaking) {
                      _stopSpeaking();
                    } else {
                      _speak(msg.text);
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryColor : _cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isUser ? Colors.white : _textColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 6),
            if (isUser)
              GestureDetector(
                onTap: () => _speak(msg.text),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.volume_up, size: 14, color: AppTheme.primaryColor.withOpacity(0.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _isSpeaking
          ? const Padding(
              padding: EdgeInsets.all(6),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.smart_toy, color: Colors.white, size: 18),
    );
  }

  // ==================== QUICK REPLIES ====================

  Widget _buildQuickReplies() {
    final quickReplies = _assistant.getQuickReplies();
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(
                quickReplies[index],
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.primaryColor,
                ),
              ),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => _sendMessage(quickReplies[index]),
            ),
          );
        },
      ),
    );
  }

  // ==================== INPUT AREA ====================

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  style: GoogleFonts.poppins(fontSize: 14, color: _textColor),
                  decoration: InputDecoration(
                    hintText: 'Message likho ya pucho...',
                    hintStyle: GoogleFonts.poppins(
                      color: _textSec,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [Colors.red, Colors.red.shade700]
                        : [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : AppTheme.primaryColor).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_isSpeaking)
              GestureDetector(
                onTap: _stopSpeaking,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stop_circle, color: Colors.white, size: 22),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
