import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class StyleDnaScreen extends StatefulWidget {
  const StyleDnaScreen({super.key});

  @override
  State<StyleDnaScreen> createState() => _StyleDnaScreenState();
}

class _StyleDnaScreenState extends State<StyleDnaScreen> with TickerProviderStateMixin {
  int _currentQuestion = 0;
  final List<int?> _answers = List.filled(8, null);
  bool _showResult = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _quizStarted = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _loadSavedResult();
  }

  Future<void> _loadSavedResult() async {
    final prefs = await SharedPreferences.getInstance();
    final hasResult = prefs.getBool('style_dna_completed') ?? false;
    if (hasResult) {
      setState(() {
        _showResult = true;
        _quizStarted = true;
        _answers[0] = prefs.getInt('q0') ?? 0;
        _answers[1] = prefs.getInt('q1') ?? 0;
        _answers[2] = prefs.getInt('q2') ?? 0;
        _answers[3] = prefs.getInt('q3') ?? 0;
        _answers[4] = prefs.getInt('q4') ?? 0;
        _answers[5] = prefs.getInt('q5') ?? 0;
        _answers[6] = prefs.getInt('q6') ?? 0;
        _answers[7] = prefs.getInt('q7') ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onOptionSelected(int optionIndex) {
    setState(() {
      _answers[_currentQuestion] = optionIndex;
    });
    _slideController.reset();
    _fadeController.forward(from: 0.0);
    _slideController.forward();

    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        if (_currentQuestion < 7) {
          setState(() => _currentQuestion++);
        } else {
          _saveAndShowResult();
        }
      }
    });
  }

  Future<void> _saveAndShowResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('style_dna_completed', true);
    for (int i = 0; i < 8; i++) {
      await prefs.setInt('q$i', _answers[i]!);
    }
    setState(() => _showResult = true);
  }

  void _retakeQuiz() {
    setState(() {
      _showResult = false;
      _quizStarted = false;
      _currentQuestion = 0;
      for (int i = 0; i < 8; i++) {
        _answers[i] = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Style DNA Quiz',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_showResult)
            TextButton(
              onPressed: _retakeQuiz,
              child: Text(
                'Retake',
                style: GoogleFonts.poppins(color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
      body: _showResult
          ? _buildResultScreen()
          : _quizStarted
              ? _buildQuizScreen()
              : _buildIntroScreen(),
    );
  }

  Widget _buildIntroScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 32),
              Text(
              'Apna Style DNA Discover Karein',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '8 quick questions se apni perfect fashion identity discover karein!',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _quizStarted = true);
                  _fadeController.forward();
                  _slideController.forward();
                },
                child: Text(
                  'Start Quiz',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final progress = (_currentQuestion + 1) / 8;
    final question = _questions[_currentQuestion];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestion + 1} of 8',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                question['title'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemCount: (question['options'] as List).length,
                  itemBuilder: (context, index) {
                    final option = (question['options'] as List)[index];
                    return _buildOptionCard(
                      label: option['label'] as String,
                      icon: option['icon'] as IconData,
                      color: option['color'] as Color,
                      index: index,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => _onOptionSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateResult() {
    final scores = <String, int>{
      'Minimal Classic': 0,
      'Bold Trendy': 0,
      'Earthy Natural': 0,
      'Glamorous': 0,
      'Street Smart': 0,
      'Traditional Elegance': 0,
    };

    // Q0: Minimal vs Bold
    switch (_answers[0]) {
      case 0: scores['Minimal Classic'] = scores['Minimal Classic']! + 3; break;
      case 1: scores['Bold Trendy'] = scores['Bold Trendy']! + 3; break;
      case 2: scores['Minimal Classic'] = scores['Minimal Classic']! + 2; scores['Earthy Natural'] = scores['Earthy Natural']! + 1; break;
      case 3: scores['Glamorous'] = scores['Glamorous']! + 3; break;
    }

    // Q1: Color preference
    switch (_answers[1]) {
      case 0: scores['Minimal Classic'] = scores['Minimal Classic']! + 2; scores['Street Smart'] = scores['Street Smart']! + 1; break;
      case 1: scores['Earthy Natural'] = scores['Earthy Natural']! + 3; break;
      case 2: scores['Bold Trendy'] = scores['Bold Trendy']! + 3; break;
      case 3: scores['Glamorous'] = scores['Glamorous']! + 2; scores['Traditional Elegance'] = scores['Traditional Elegance']! + 1; break;
    }

    // Q2: Event
    switch (_answers[2]) {
      case 0: scores['Minimal Classic'] = scores['Minimal Classic']! + 2; scores['Street Smart'] = scores['Street Smart']! + 1; break;
      case 1: scores['Street Smart'] = scores['Street Smart']! + 2; scores['Earthy Natural'] = scores['Earthy Natural']! + 1; break;
      case 2: scores['Bold Trendy'] = scores['Bold Trendy']! + 2; scores['Glamorous'] = scores['Glamorous']! + 1; break;
      case 3: scores['Traditional Elegance'] = scores['Traditional Elegance']! + 3; break;
    }

    // Q3: Season
    switch (_answers[3]) {
      case 0: scores['Earthy Natural'] = scores['Earthy Natural']! + 2; scores['Street Smart'] = scores['Street Smart']! + 1; break;
      case 1: scores['Minimal Classic'] = scores['Minimal Classic']! + 1; scores['Glamorous'] = scores['Glamorous']! + 2; break;
      case 2: scores['Traditional Elegance'] = scores['Traditional Elegance']! + 2; scores['Earthy Natural'] = scores['Earthy Natural']! + 1; break;
    }

    // Q4: Budget
    switch (_answers[4]) {
      case 0: scores['Street Smart'] = scores['Street Smart']! + 2; scores['Earthy Natural'] = scores['Earthy Natural']! + 1; break;
      case 1: scores['Minimal Classic'] = scores['Minimal Classic']! + 2; scores['Bold Trendy'] = scores['Bold Trendy']! + 1; break;
      case 2: scores['Glamorous'] = scores['Glamorous']! + 2; scores['Traditional Elegance'] = scores['Traditional Elegance']! + 1; break;
    }

    // Q5: Body type
    switch (_answers[5]) {
      case 0: scores['Minimal Classic'] = scores['Minimal Classic']! + 2; scores['Street Smart'] = scores['Street Smart']! + 1; break;
      case 1: scores['Bold Trendy'] = scores['Bold Trendy']! + 2; scores['Glamorous'] = scores['Glamorous']! + 1; break;
      case 2: scores['Glamorous'] = scores['Glamorous']! + 2; scores['Traditional Elegance'] = scores['Traditional Elegance']! + 1; break;
      case 3: scores['Earthy Natural'] = scores['Earthy Natural']! + 2; scores['Minimal Classic'] = scores['Minimal Classic']! + 1; break;
    }

    // Q6: Fabric
    switch (_answers[6]) {
      case 0: scores['Earthy Natural'] = scores['Earthy Natural']! + 2; scores['Minimal Classic'] = scores['Minimal Classic']! + 1; break;
      case 1: scores['Traditional Elegance'] = scores['Traditional Elegance']! + 2; scores['Glamorous'] = scores['Glamorous']! + 1; break;
      case 2: scores['Street Smart'] = scores['Street Smart']! + 3; break;
      case 3: scores['Bold Trendy'] = scores['Bold Trendy']! + 2; scores['Minimal Classic'] = scores['Minimal Classic']! + 1; break;
    }

    // Q7: Style inspiration
    switch (_answers[7]) {
      case 0: scores['Bold Trendy'] = scores['Bold Trendy']! + 2; scores['Traditional Elegance'] = scores['Traditional Elegance']! + 1; break;
      case 1: scores['Glamorous'] = scores['Glamorous']! + 2; scores['Street Smart'] = scores['Street Smart']! + 1; break;
      case 2: scores['Street Smart'] = scores['Street Smart']! + 2; scores['Bold Trendy'] = scores['Bold Trendy']! + 1; break;
      case 3: scores['Minimal Classic'] = scores['Minimal Classic']! + 2; scores['Traditional Elegance'] = scores['Traditional Elegance']! + 1; break;
    }

    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {
      'name': sorted.first.key,
      'scores': scores,
    };
  }

  Widget _buildResultScreen() {
    final result = _calculateResult();
    final name = result['name'] as String;
    final data = _styleData[name]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Style DNA Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [data['color'] as Color, (data['color'] as Color).withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (data['color'] as Color).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(data['icon'] as IconData, size: 56, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Aapka Style DNA',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description
          _buildInfoCard(
            title: 'About Your Style',
            child: Text(
              data['description'] as String,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ),

          // Top 5 Must-Haves
          _buildInfoCard(
            title: 'Top 5 Wardrobe Must-Haves',
            child: Column(
              children: (data['mustHaves'] as List<String>).asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: (data['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: data['color'] as Color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Best Colors
          _buildInfoCard(
            title: 'Best Colors for You',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: (data['bestColors'] as List<Map<String, dynamic>>).map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: c['color'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c['name'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textColorForBg(c['color'] as Color),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Best Occasions
          _buildInfoCard(
            title: 'Best Occasions',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (data['occasions'] as List<String>).map((occasion) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                  ),
                  child: Text(
                    occasion,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _retakeQuiz,
              child: Text(
                'Retake Quiz',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Color _textColorForBg(Color bg) {
    final luminance = (0.299 * bg.red + 0.587 * bg.green + 0.114 * bg.blue) / 255;
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  static final List<Map<String, dynamic>> _questions = [
    {
      'title': 'Tumhe kya zyada pasand hai?',
      'options': [
        {'label': 'Minimal', 'icon': Icons.minimize, 'color': Color(0xFF6B7280)},
        {'label': 'Bold', 'icon': Icons.auto_awesome, 'color': Color(0xFFEF4444)},
        {'label': 'Classic', 'icon': Icons.diamond_outlined, 'color': Color(0xFF1E3A5F)},
        {'label': 'Glamorous', 'icon': Icons.star_outline, 'color': Color(0xFFF59E0B)},
      ],
    },
    {
      'title': 'Kaunsa color zyada pasand hai?',
      'options': [
        {'label': 'Neutral', 'icon': Icons.circle, 'color': Color(0xFF9CA3AF)},
        {'label': 'Bright', 'icon': Icons.wb_sunny_outlined, 'color': Color(0xFFF97316)},
        {'label': 'Earth Tones', 'icon': Icons.eco_outlined, 'color': Color(0xFF22C55E)},
        {'label': 'Pastels', 'icon': Icons.water_drop_outlined, 'color': Color(0xFFEC4899)},
      ],
    },
    {
      'title': 'Event kya hai?',
      'options': [
        {'label': 'Office', 'icon': Icons.business_center_outlined, 'color': Color(0xFF3B82F6)},
        {'label': 'Casual', 'icon': Icons.weekend_outlined, 'color': Color(0xFF10B981)},
        {'label': 'Party', 'icon': Icons.celebration_outlined, 'color': Color(0xFF8B5CF6)},
        {'label': 'Wedding', 'icon': Icons.favorite_outline, 'color': Color(0xFFEC4899)},
      ],
    },
    {
      'title': 'Season kya hai?',
      'options': [
        {'label': 'Summer', 'icon': Icons.wb_sunny, 'color': Color(0xFFF59E0B)},
        {'label': 'Winter', 'icon': Icons.ac_unit, 'color': Color(0xFF3B82F6)},
        {'label': 'Monsoon', 'icon': Icons.water_drop, 'color': Color(0xFF6366F1)},
      ],
    },
    {
      'title': 'Tumhara budget?',
      'options': [
        {'label': 'Low', 'icon': Icons.savings_outlined, 'color': Color(0xFF10B981)},
        {'label': 'Medium', 'icon': Icons.account_balance_wallet_outlined, 'color': Color(0xFF3B82F6)},
        {'label': 'High', 'icon': Icons.diamond, 'color': Color(0xFFF59E0B)},
      ],
    },
    {
      'title': 'Body type?',
      'options': [
        {'label': 'Slim', 'icon': Icons.accessibility_new, 'color': Color(0xFF6366F1)},
        {'label': 'Athletic', 'icon': Icons.fitness_center, 'color': Color(0xFFEF4444)},
        {'label': 'Curvy', 'icon': Icons.self_improvement, 'color': Color(0xFFEC4899)},
        {'label': 'Average', 'icon': Icons.person_outline, 'color': Color(0xFF6B7280)},
      ],
    },
    {
      'title': 'Kaunsa fabric?',
      'options': [
        {'label': 'Cotton', 'icon': Icons.grass_outlined, 'color': Color(0xFF22C55E)},
        {'label': 'Silk', 'icon': Icons.auto_awesome, 'color': Color(0xFFF59E0B)},
        {'label': 'Denim', 'icon': Icons.checkroom_outlined, 'color': Color(0xFF3B82F6)},
        {'label': 'Mixed', 'icon': Icons.palette_outlined, 'color': Color(0xFF8B5CF6)},
      ],
    },
    {
      'title': 'Style inspiration?',
      'options': [
        {'label': 'Bollywood', 'icon': Icons.movie_outlined, 'color': Color(0xFFEF4444)},
        {'label': 'Hollywood', 'icon': Icons.theater_comedy_outlined, 'color': Color(0xFF3B82F6)},
        {'label': 'Korean', 'icon': Icons.face_outlined, 'color': Color(0xFFEC4899)},
        {'label': 'Classic', 'icon': Icons.history_edu_outlined, 'color': Color(0xFF1E3A5F)},
      ],
    },
  ];

  static final Map<String, dynamic> _styleData = {
    'Minimal Classic': {
      'icon': Icons.minimize,
      'color': Color(0xFF6B7280),
      'description': 'You believe in the power of simplicity. Your wardrobe is a curated collection of timeless pieces that always look effortless. Clean lines, neutral tones, and quality fabrics define your style. You look elegant without trying too hard.',
      'mustHaves': [
        'White crisp shirt',
        'Well-fitted blazer in navy/black',
        'Classic leather watch',
        'Tailored trousers in neutral tones',
        'Quality leather loafers or pumps',
      ],
      'bestColors': [
        {'name': 'Black', 'color': Color(0xFF000000)},
        {'name': 'White', 'color': Color(0xFFFFFFFF)},
        {'name': 'Navy', 'color': Color(0xFF1E3A5F)},
        {'name': 'Grey', 'color': Color(0xFF6B7280)},
        {'name': 'Beige', 'color': Color(0xFFF5F5DC)},
      ],
      'occasions': ['Office', 'Formal Events', 'Date Night', 'Business Meetings', 'Brunch'],
    },
    'Bold Trendy': {
      'icon': Icons.auto_awesome,
      'color': Color(0xFFEF4444),
      'description': 'You are a fashion risk-taker! Your style is all about making statements and turning heads. You love experimenting with colors, patterns, and the latest trends. Your confidence shines through every outfit you wear.',
      'mustHaves': [
        'Statement blazer in bright color',
        'Graphic or printed tops',
        'Trendy chunky sneakers',
        'Oversized sunglasses',
        'Bold accessories & layered jewelry',
      ],
      'bestColors': [
        {'name': 'Red', 'color': Color(0xFFEF4444)},
        {'name': 'Electric Blue', 'color': Color(0xFF3B82F6)},
        {'name': 'Hot Pink', 'color': Color(0xFFEC4899)},
        {'name': 'Neon Green', 'color': Color(0xFF22C55E)},
        {'name': 'Purple', 'color': Color(0xFF8B5CF6)},
      ],
      'occasions': ['Parties', 'Fashion Events', 'Girls Night Out', 'Concerts', 'Festivals'],
    },
    'Earthy Natural': {
      'icon': Icons.eco_outlined,
      'color': Color(0xFF22C55E),
      'description': 'Your style is grounded in nature and comfort. You prefer organic fabrics, earthy tones, and relaxed silhouettes. You love breathable materials and sustainable fashion that feels as good as it looks.',
      'mustHaves': [
        'Linen trousers or wide-leg pants',
        'Cotton kurta or tunic',
        'Jute or woven sandals',
        'Oversized tote bag',
        'Handcrafted jewelry',
      ],
      'bestColors': [
        {'name': 'Olive', 'color': Color(0xFF808000)},
        {'name': 'Rust', 'color': Color(0xFFB7410E)},
        {'name': 'Cream', 'color': Color(0xFFFFFDD0)},
        {'name': 'Terracotta', 'color': Color(0xFFE2725B)},
        {'name': 'Brown', 'color': Color(0xFF8B4513)},
      ],
      'occasions': ['Weekend Outings', 'Beach Trips', 'Cafes', 'College', 'Art Galleries'],
    },
    'Glamorous': {
      'icon': Icons.star_outline,
      'color': Color(0xFFF59E0B),
      'description': 'You are the queen of elegance and luxury! Your style exudes sophistication with a touch of drama. You love rich fabrics, statement pieces, and accessories that sparkle. Every outfit is an opportunity to make an impression.',
      'mustHaves': [
        'Silk or satin blouse',
        'Statement heels or stilettos',
        'Gold or silver jewelry',
        'Structured handbag or clutch',
        'Well-tailored dress or saree',
      ],
      'bestColors': [
        {'name': 'Gold', 'color': Color(0xFFFFD700)},
        {'name': 'Black', 'color': Color(0xFF000000)},
        {'name': 'Burgundy', 'color': Color(0xFF800020)},
        {'name': 'Silver', 'color': Color(0xFFC0C0C0)},
        {'name': 'Deep Purple', 'color': Color(0xFF800080)},
      ],
      'occasions': ['Weddings', 'Gala Events', 'Cocktail Parties', 'Anniversary Dinners', 'Red Carpet'],
    },
    'Street Smart': {
      'icon': Icons.directions_walk,
      'color': Color(0xFF6366F1),
      'description': 'Your style is urban, cool, and effortlessly hip. You master the art of looking put-together while keeping it casual. Denim, sneakers, and versatile layers are the backbone of your wardrobe.',
      'mustHaves': [
        'Perfect-fit denim jeans',
        'White sneakers',
        'Oversized hoodie or bomber jacket',
        'Crossbody bag',
        'Layerable basics (tees, tanks)',
      ],
      'bestColors': [
        {'name': 'Denim Blue', 'color': Color(0xFF1565C0)},
        {'name': 'Black', 'color': Color(0xFF000000)},
        {'name': 'White', 'color': Color(0xFFFFFFFF)},
        {'name': 'Grey', 'color': Color(0xFF9E9E9E)},
        {'name': 'Olive', 'color': Color(0xFF689F38)},
      ],
      'occasions': ['College', 'Weekend Hangouts', 'Travel', 'Shopping', 'Casual Dinners'],
    },
    'Traditional Elegance': {
      'icon': Icons.auto_awesome_outlined,
      'color': Color(0xFF8B5CF6),
      'description': 'You carry the grace of tradition with a modern twist. You love ethnic wear, intricate patterns, and timeless silhouettes that celebrate cultural heritage. Your style is regal, polished, and deeply personal.',
      'mustHaves': [
        'Embroidered or printed saree/salwar suit',
        'Traditional juttis or kolhapuris',
        'Gold or silver jewelry set',
        'Clutch with ethnic detailing',
        'Silk dupatta or stole',
      ],
      'bestColors': [
        {'name': 'Maroon', 'color': Color(0xFF800000)},
        {'name': 'Royal Blue', 'color': Color(0xFF4169E1)},
        {'name': 'Gold', 'color': Color(0xFFDAA520)},
        {'name': 'Emerald', 'color': Color(0xFF046A38)},
        {'name': 'Ivory', 'color': Color(0xFFFFFFF0)},
      ],
      'occasions': ['Weddings', 'Festivals', 'Pooja Ceremonies', 'Family Gatherings', 'Cultural Events'],
    },
  };
}
