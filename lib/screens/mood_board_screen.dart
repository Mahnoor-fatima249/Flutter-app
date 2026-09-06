import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class MoodBoardScreen extends StatefulWidget {
  const MoodBoardScreen({super.key});

  @override
  State<MoodBoardScreen> createState() => _MoodBoardScreenState();
}

class _MoodBoardScreenState extends State<MoodBoardScreen> {
  List<String> _selectedColors = [];
  List<String> _selectedFabrics = [];
  List<String> _selectedOccasions = [];
  List<String> _selectedSeasons = [];
  List<String> _selectedStyles = [];
  bool _isLoading = true;

  static const List<Map<String, dynamic>> _moodCategories = [
    {'title': 'Colors', 'icon': Icons.palette, 'color': Color(0xFFE91E63)},
    {'title': 'Fabrics', 'icon': Icons.texture, 'color': Color(0xFF6C63FF)},
    {'title': 'Occasions', 'icon': Icons.celebration, 'color': Color(0xFFFF6584)},
    {'title': 'Seasons', 'icon': Icons.wb_sunny, 'color': Color(0xFFFF9800)},
    {'title': 'Styles', 'icon': Icons.style, 'color': Color(0xFF10B981)},
  ];

  static const List<Color> _colorSwatches = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
  ];

  static const List<String> _colorNames = [
    'Black', 'White', 'Red', 'Pink', 'Purple',
    'Deep Purple', 'Indigo', 'Blue', 'Light Blue', 'Cyan',
    'Teal', 'Green', 'Light Green', 'Lime', 'Yellow',
    'Amber', 'Orange', 'Deep Orange', 'Brown', 'Grey',
  ];

  static const List<Map<String, dynamic>> _fabrics = [
    {'name': 'Cotton', 'icon': Icons.grass},
    {'name': 'Silk', 'icon': Icons.auto_awesome},
    {'name': 'Denim', 'icon': Icons.layers},
    {'name': 'Linen', 'icon': Icons.eco},
    {'name': 'Wool', 'icon': Icons.grass},
    {'name': 'Leather', 'icon': Icons.water_drop},
    {'name': 'Velvet', 'icon': Icons.diamond},
    {'name': 'Chiffon', 'icon': Icons.air},
    {'name': 'Satin', 'icon': Icons.auto_awesome},
    {'name': 'Jersey', 'icon': Icons.sports_basketball},
    {'name': 'Tweed', 'icon': Icons.grid_on},
    {'name': 'Corduroy', 'icon': Icons.line_style},
  ];

  static const List<Map<String, dynamic>> _occasions = [
    {'name': 'Formal', 'icon': Icons.business_center, 'color': Color(0xFF1E3A5F)},
    {'name': 'Casual', 'icon': Icons.weekend, 'color': Color(0xFF10B981)},
    {'name': 'Party', 'icon': Icons.celebration, 'color': Color(0xFFE91E63)},
    {'name': 'Wedding', 'icon': Icons.favorite, 'color': Color(0xFFFF6584)},
    {'name': 'Office', 'icon': Icons.work, 'color': Color(0xFF6C63FF)},
    {'name': 'Sport', 'icon': Icons.sports, 'color': Color(0xFFFF9800)},
    {'name': 'Travel', 'icon': Icons.flight, 'color': Color(0xFF00BCD4)},
    {'name': 'Date Night', 'icon': Icons.nights_stay, 'color': Color(0xFF9C27B0)},
  ];

  static const List<Map<String, dynamic>> _seasons = [
    {'name': 'Summer', 'icon': Icons.wb_sunny, 'color': Color(0xFFFF9800)},
    {'name': 'Winter', 'icon': Icons.ac_unit, 'color': Color(0xFF2196F3)},
    {'name': 'Monsoon', 'icon': Icons.umbrella, 'color': Color(0xFF4CAF50)},
    {'name': 'Spring', 'icon': Icons.local_florist, 'color': Color(0xFFE91E63)},
  ];

  static const List<Map<String, dynamic>> _styles = [
    {'name': 'Minimal', 'icon': Icons.remove, 'color': Color(0xFF757575)},
    {'name': 'Bold', 'icon': Icons.whatshot, 'color': Color(0xFFE91E63)},
    {'name': 'Classic', 'icon': Icons.history, 'color': Color(0xFF1E3A5F)},
    {'name': 'Trendy', 'icon': Icons.trending_up, 'color': Color(0xFF6C63FF)},
    {'name': 'Traditional', 'icon': Icons.auto_stories, 'color': Color(0xFF8D6E63)},
    {'name': 'Bohemian', 'icon': Icons.local_florist, 'color': Color(0xFF9C27B0)},
    {'name': 'Streetwear', 'icon': Icons.location_city, 'color': Color(0xFF424242)},
    {'name': 'Preppy', 'icon': Icons.school, 'color': Color(0xFF0288D1)},
  ];

  @override
  void initState() {
    super.initState();
    _loadSelections();
  }

  Future<void> _loadSelections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedColors = prefs.getStringList('mood_colors') ?? [];
      _selectedFabrics = prefs.getStringList('mood_fabrics') ?? [];
      _selectedOccasions = prefs.getStringList('mood_occasions') ?? [];
      _selectedSeasons = prefs.getStringList('mood_seasons') ?? [];
      _selectedStyles = prefs.getStringList('mood_styles') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _saveSelections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('mood_colors', _selectedColors);
    await prefs.setStringList('mood_fabrics', _selectedFabrics);
    await prefs.setStringList('mood_occasions', _selectedOccasions);
    await prefs.setStringList('mood_seasons', _selectedSeasons);
    await prefs.setStringList('mood_styles', _selectedStyles);
  }

  void _openColorSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Your Colors',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${_selectedColors.length}/20',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _colorSwatches.length,
                  itemBuilder: (context, index) {
                    final color = _colorSwatches[index];
                    final colorName = _colorNames[index];
                    final isSelected = _selectedColors.contains(colorName);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedColors.remove(colorName);
                          } else {
                            _selectedColors.add(colorName);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : color == Colors.white
                                    ? Colors.grey[300]!
                                    : Colors.transparent,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveSelections();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMultiSelectSelector(String title, List<Map<String, dynamic>> items, List<String> selectedList, String prefKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select $title',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${selectedList.length} selected',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = selectedList.contains(item['name']);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedList.remove(item['name']);
                              } else {
                                selectedList.add(item['name']);
                              }
                            });
                            setState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (item['color'] as Color? ?? AppTheme.primaryColor).withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? (item['color'] as Color? ?? AppTheme.primaryColor)
                                    : AppTheme.dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (item['color'] as Color? ?? AppTheme.primaryColor)
                                            .withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (item['color'] as Color? ?? AppTheme.primaryColor)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: item['color'] as Color? ?? AppTheme.primaryColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item['name'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: item['color'] as Color? ?? AppTheme.primaryColor,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _saveSelections();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Mood Board',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mood Board',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCategoriesGrid(),
            const SizedBox(height: 24),
            _buildStyleProfile(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Style Mood Board',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Define your personal style preferences',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: _moodCategories.length,
      itemBuilder: (context, index) {
        final category = _moodCategories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final title = category['title'] as String;
    final icon = category['icon'] as IconData;
    final color = category['color'] as Color;

    String subtitle;
    List<String> selected;

    switch (title) {
      case 'Colors':
        subtitle = _selectedColors.isEmpty
            ? 'Tap to select'
            : '${_selectedColors.length} colors';
        selected = _selectedColors;
        break;
      case 'Fabrics':
        subtitle = _selectedFabrics.isEmpty
            ? 'Tap to select'
            : '${_selectedFabrics.length} fabrics';
        selected = _selectedFabrics;
        break;
      case 'Occasions':
        subtitle = _selectedOccasions.isEmpty
            ? 'Tap to select'
            : '${_selectedOccasions.length} occasions';
        selected = _selectedOccasions;
        break;
      case 'Seasons':
        subtitle = _selectedSeasons.isEmpty
            ? 'Tap to select'
            : '${_selectedSeasons.length} seasons';
        selected = _selectedSeasons;
        break;
      case 'Styles':
        subtitle = _selectedStyles.isEmpty
            ? 'Tap to select'
            : '${_selectedStyles.length} styles';
        selected = _selectedStyles;
        break;
      default:
        subtitle = 'Tap to select';
        selected = [];
    }

    return GestureDetector(
      onTap: () => _openSelector(title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSelector(String title) {
    switch (title) {
      case 'Colors':
        _openColorSelector();
        break;
      case 'Fabrics':
        _openMultiSelectSelector('Fabrics', _fabrics, _selectedFabrics, 'mood_fabrics');
        break;
      case 'Occasions':
        _openMultiSelectSelector('Occasions', _occasions, _selectedOccasions, 'mood_occasions');
        break;
      case 'Seasons':
        _openMultiSelectSelector('Seasons', _seasons, _selectedSeasons, 'mood_seasons');
        break;
      case 'Styles':
        _openMultiSelectSelector('Styles', _styles, _selectedStyles, 'mood_styles');
        break;
    }
  }

  Widget _buildStyleProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Style Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildProfileSection('Colors', _selectedColors, const Color(0xFFE91E63)),
        _buildProfileSection('Fabrics', _selectedFabrics, const Color(0xFF6C63FF)),
        _buildProfileSection('Occasions', _selectedOccasions, const Color(0xFFFF6584)),
        _buildProfileSection('Seasons', _selectedSeasons, const Color(0xFFFF9800)),
        _buildProfileSection('Styles', _selectedStyles, const Color(0xFF10B981)),
        const SizedBox(height: 16),
        if (_selectedColors.isEmpty &&
            _selectedFabrics.isEmpty &&
            _selectedOccasions.isEmpty &&
            _selectedSeasons.isEmpty &&
            _selectedStyles.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap categories above to define your style',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileSection(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                if (title == 'Colors') {
                  final colorValue = AppTheme.getColorFromName(item);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorValue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorValue == Colors.white
                            ? Colors.grey[300]!
                            : colorValue,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: colorValue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorValue == Colors.white
                                  ? Colors.grey[300]!
                                  : colorValue,
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Chip(
                  label: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  backgroundColor: color.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
