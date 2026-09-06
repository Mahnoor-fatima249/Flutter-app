import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ColorPaletteScreen extends StatefulWidget {
  const ColorPaletteScreen({super.key});

  @override
  State<ColorPaletteScreen> createState() => _ColorPaletteScreenState();
}

class _ColorPaletteScreenState extends State<ColorPaletteScreen> {
  final StorageService _storage = StorageService();
  String? _selectedColor1;
  String? _selectedColor2;
  String _selectedOccasion = 'Casual';

  @override
  Widget build(BuildContext context) {
    final colorDistribution = _storage.getColorDistribution();
    final trendingColors = _getTrendingColors(colorDistribution);
    final missingColors = _getMissingColors(colorDistribution);
    final outfitCombos = _generateOutfitCombos(colorDistribution);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Color Palette',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorMixerSection(),
            const SizedBox(height: 24),
            _buildTrendingSection(trendingColors),
            const SizedBox(height: 24),
            _buildSuggestedSection(missingColors),
            const SizedBox(height: 24),
            _buildCombosSection(outfitCombos),
            const SizedBox(height: 24),
            _buildTryTheseCombos(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorMixerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.colorize, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color Mixer',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'See how two colors look together',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Color 1',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showColorPicker(1),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: _selectedColor1 != null
                                  ? AppTheme.getColorFromName(_selectedColor1!)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedColor1 != null
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: _selectedColor1 != null
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.getColorFromName(_selectedColor1!).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: _selectedColor1 == null
                                  ? const Icon(Icons.add, color: Colors.grey, size: 28)
                                  : Text(
                                      _selectedColor1![0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: _textColorForBg(AppTheme.getColorFromName(_selectedColor1!)),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedColor1 ?? 'Select',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Color 2',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showColorPicker(2),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: _selectedColor2 != null
                                  ? AppTheme.getColorFromName(_selectedColor2!)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedColor2 != null
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: _selectedColor2 != null
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.getColorFromName(_selectedColor2!).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: _selectedColor2 == null
                                  ? const Icon(Icons.add, color: Colors.grey, size: 28)
                                  : Text(
                                      _selectedColor2![0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: _textColorForBg(AppTheme.getColorFromName(_selectedColor2!)),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedColor2 ?? 'Select',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_selectedColor1 != null && _selectedColor2 != null) ...[
                const SizedBox(height: 20),
                _buildMixPreview(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMixPreview() {
    final color1 = AppTheme.getColorFromName(_selectedColor1!);
    final color2 = AppTheme.getColorFromName(_selectedColor2!);
    final matchScore = _calculateMatchScore(_selectedColor1!, _selectedColor2!, _selectedOccasion);
    final matchText = _getMatchText(matchScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1.withOpacity(0.1), color2.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Occasion Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Occasion: ',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              ...['Formal', 'Casual', 'Party', 'Office'].map((occ) {
                final isSelected = _selectedOccasion == occ;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(occ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedOccasion = occ;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.3),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.add_circle, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color1, color2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: matchScore >= 70
                  ? Colors.green.withOpacity(0.1)
                  : matchScore >= 40
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              matchText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: matchScore >= 70
                    ? Colors.green
                    : matchScore >= 40
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _getColorAdvice(_selectedColor1!, _selectedColor2!, matchScore),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _calculateMatchScore(String color1, String color2, [String? occasion]) {
    final c1 = color1.toLowerCase();
    final c2 = color2.toLowerCase();
    final occ = (occasion ?? _selectedOccasion).toLowerCase();

    final neutrals = ['black', 'white', 'grey', 'beige', 'cream', 'tan', 'navy'];
    final boldColors = ['red', 'orange', 'royal blue', 'emerald', 'fuchsia', 'purple', 'hot pink'];
    final metallics = ['gold', 'silver', 'bronze'];
    final brightColors = ['red', 'orange', 'yellow', 'pink', 'coral', 'hot pink', 'royal blue', 'emerald'];

    // Perfect matches - classic combinations
    final perfectMatches = {
      'black': ['white', 'red', 'gold', 'silver'],
      'white': ['black', 'navy', 'red', 'royal blue'],
      'navy': ['white', 'cream', 'pink', 'camel'],
      'beige': ['navy', 'burgundy', 'forest green'],
      'brown': ['cream', 'sky blue', 'coral'],
      'grey': ['pink', 'lavender', 'yellow'],
      'camel': ['navy', 'white', 'black', 'burgundy'],
      'burgundy': ['navy', 'cream', 'grey', 'camel'],
      'forest green': ['cream', 'brown', 'beige', 'gold'],
      'coral': ['navy', 'white', 'grey', 'tan'],
      'lavender': ['grey', 'white', 'navy'],
      'mint': ['navy', 'white', 'brown', 'coral'],
      'rust': ['navy', 'cream', 'grey', 'denim blue'],
      'mustard': ['navy', 'grey', 'black', 'white'],
    };

    // Good matches - work well together
    final goodMatches = {
      'black': ['grey', 'beige', 'maroon', 'olive', 'pink', 'purple', 'blue'],
      'white': ['grey', 'beige', 'light blue', 'blush', 'olive'],
      'navy': ['grey', 'tan', 'olive', 'light blue', 'rust'],
      'blue': ['white', 'grey', 'tan', 'coral', 'yellow'],
      'red': ['grey', 'denim blue', 'black', 'white', 'navy'],
      'green': ['white', 'cream', 'tan', 'brown', 'grey'],
      'yellow': ['grey', 'white', 'navy', 'denim blue', 'brown'],
      'grey': ['white', 'black', 'blue', 'red', 'green', 'yellow', 'pink'],
      'brown': ['white', 'beige', 'light blue', 'orange', 'green'],
      'beige': ['black', 'white', 'brown', 'red', 'green'],
      'pink': ['grey', 'navy', 'white', 'denim blue', 'black'],
      'orange': ['navy', 'white', 'grey', 'denim blue', 'teal'],
      'purple': ['white', 'grey', 'lavender', 'yellow', 'beige'],
      'cream': ['navy', 'black', 'brown', 'forest green', 'rust'],
      'maroon': ['white', 'grey', 'beige', 'cream', 'gold'],
      'olive': ['white', 'cream', 'brown', 'black', 'rust'],
    };

    // Bad matches - clash
    final badMatches = {
      'red': ['orange', 'pink', 'purple', 'brown'],
      'orange': ['red', 'pink', 'purple', 'yellow'],
      'pink': ['red', 'orange', 'brown', 'maroon'],
      'purple': ['red', 'orange', 'brown'],
      'yellow': ['orange', 'brown', 'olive'],
      'green': ['blue', 'purple', 'black'],
      'brown': ['black', 'maroon', 'olive'],
    };

    // Formal specific pairs
    final formalPerfect = {
      'navy': ['white', 'cream', 'silver', 'grey'],
      'black': ['white', 'grey', 'silver'],
      'grey': ['navy', 'black', 'white'],
      'charcoal': ['white', 'light grey'],
    };

    // Office specific pairs
    final officePerfect = {
      'navy': ['white', 'cream', 'grey', 'beige'],
      'grey': ['white', 'navy', 'black', 'light blue'],
      'black': ['white', 'grey', 'beige'],
      'charcoal': ['white', 'light blue', 'cream'],
      'beige': ['navy', 'black', 'brown'],
    };

    // Same color - boring
    if (c1 == c2) return 30;

    int baseScore = 35;

    // Check perfect matches
    if (perfectMatches[c1]?.contains(c2) == true) baseScore = 95;
    else if (perfectMatches[c2]?.contains(c1) == true) baseScore = 95;
    // Check bad matches
    else if (badMatches[c1]?.contains(c2) == true) baseScore = 20;
    else if (badMatches[c2]?.contains(c1) == true) baseScore = 20;
    // Check good matches
    else if (goodMatches[c1]?.contains(c2) == true) baseScore = 75;
    else if (goodMatches[c2]?.contains(c1) == true) baseScore = 75;
    // Neutral + neutral = okay
    else if (neutrals.contains(c1) && neutrals.contains(c2)) baseScore = 65;
    // Neutral + any color = generally okay
    else if (neutrals.contains(c1) || neutrals.contains(c2)) baseScore = 55;

    // === Context-based adjustments ===
    int bonus = 0;

    switch (occ) {
      case 'formal':
        if (formalPerfect[c1]?.contains(c2) == true || formalPerfect[c2]?.contains(c1) == true) {
          bonus = 10;
        }
        if (c1 == 'navy' && c2 == 'white' || c2 == 'navy' && c1 == 'white') bonus = 10;
        if (c1 == 'black' && c2 == 'white' || c2 == 'black' && c1 == 'white') bonus = 10;
        if (c1 == 'grey' && c2 == 'navy' || c2 == 'grey' && c1 == 'navy') bonus = 5;
        // Penalize too-bright combos for formal
        if (brightColors.contains(c1) && brightColors.contains(c2)) bonus -= 15;
        break;

      case 'casual':
        // Bright combos get bonus
        if (brightColors.contains(c1) || brightColors.contains(c2)) {
          bonus += 8;
        }
        // Complementary bright combos get extra
        if (brightColors.contains(c1) && brightColors.contains(c2) && c1 != c2) {
          bonus += 5;
        }
        break;

      case 'party':
        // Bold + Metallic gets bonus
        if ((boldColors.contains(c1) && metallics.contains(c2)) ||
            (boldColors.contains(c2) && metallics.contains(c1))) {
          bonus += 15;
        }
        // Metallic with any bold is great
        if (metallics.contains(c1) || metallics.contains(c2)) {
          bonus += 5;
        }
        // Bold combos look good at parties
        if (boldColors.contains(c1) && boldColors.contains(c2)) {
          bonus += 10;
        }
        break;

      case 'office':
        if (officePerfect[c1]?.contains(c2) == true || officePerfect[c2]?.contains(c1) == true) {
          bonus += 10;
        }
        // Neutral combos score higher for office
        if (neutrals.contains(c1) && neutrals.contains(c2)) {
          bonus += 10;
        }
        // Penalize loud colors for office
        if (brightColors.contains(c1) && brightColors.contains(c2)) {
          bonus -= 10;
        }
        break;
    }

    return (baseScore + bonus).clamp(0, 100);
  }

  String _getMatchText(int score) {
    if (score >= 90) return 'Perfect Match! Classy combo! 🔥';
    if (score >= 75) return 'Great Match! Both colors complement each other ✨';
    if (score >= 60) return 'Good Match! Looks decent together 👍';
    if (score >= 40) return 'Average Match. Can work with right outfit 🤔';
    if (score >= 25) return 'Not Ideal. These colors may clash ⚠️';
    return 'Bad Match! Avoid this combo ❌';
  }

  String _getColorAdvice(String color1, String color2, int score) {
    final occ = _selectedOccasion.toLowerCase();
    final c1 = color1;
    final c2 = color2;

    String occasionPrefix = '';
    switch (occ) {
      case 'formal':
        occasionPrefix = 'Formal event ke liye: ';
        break;
      case 'casual':
        occasionPrefix = 'Casual look ke liye: ';
        break;
      case 'party':
        occasionPrefix = 'Party look ke liye: ';
        break;
      case 'office':
        occasionPrefix = 'Office ke liye: ';
        break;
    }

    if (score >= 85) {
      switch (occ) {
        case 'formal':
          return 'Ye formal event ke liye perfect hai! $c1 aur $c2 ka combo '
              'bohot elegant lagta hai. Shadi, ya kisi bhi formal gathering mein '
              'confident hokar pehno. Sab tarif karenge!';
        case 'casual':
          return 'Casual look ke liye best combo hai! $c1 aur $c2 saath mein '
              'bohot cool lagte hain. College, shopping ya friend gathering '
              'ke liye bilkul sahi choice hai.';
        case 'party':
          return 'Party mein sabki nazar aayegi is combo pe! $c1 aur $c2 ka mix '
              'bohot dashing lagta hai. Dance floor pe king ban jao!';
        case 'office':
          return 'Office ja ke liye professional look hai! $c1 aur $c2 ka combo '
              'bohot sophisticated lagta hai. Meeting mein impress karo!';
      }
    }

    if (score >= 70) {
      switch (occ) {
        case 'formal':
          return '$c1 aur $c2 formal look ke liye achha hai. Thoda sa '
              'accessories add karo jaise watch ya cufflinks aur look '
              'bohot polished lagega.';
        case 'casual':
          return '$c1 aur $c2 casual outfit ke liye sahi hai. Sneakers ya '
              'loafers ke saath pair karo, mast lagoge!';
        case 'party':
          return '$c1 aur $c2 party ke liye theek hai. Ek chain ya bracelet '
              'add karo aur look complete ho jayega.';
        case 'office':
          return '$c1 aur $c2 office ke liye decent hai. Proper fitting '
              'rakhoge toh bohot professional lagega.';
      }
    }

    if (score >= 50) {
      switch (occ) {
        case 'formal':
          return '$c1 aur $color2 thoda risky hai formal ke liye. Ek neutral '
              'color ka pocket square ya tie add karo toh balance ho jayega.';
        case 'casual':
          return '$c1 aur $c2 casual mein chal jayega. Ek white ya grey piece '
              'add karo beech mein, aur look achha ho jayega.';
        case 'party':
          return '$c1 aur $c2 party ke liye average hai. Thoda bold accessories '
              'try karo isko elevate karne ke liye.';
        case 'office':
          return '$c1 aur $c2 office ke liye thoda bold hai. Ek blazer ya '
              'cardigan add karo toh professional lagega.';
      }
    }

    // Low score advice
    switch (occ) {
      case 'formal':
        return '$c1 aur $c2 formal event ke liye suit nahi karta. Better hai '
            '${_getAlternativeColor(color1)} try karo $c2 ke saath. '
            'Formal mein classic combos hamesha kaam karte hain.';
      case 'casual':
        return '$c1 aur $c2 casual mein bhi achha nahi lagta. '
            'Try karo ${_getAlternativeColor(color1)} ke saath $c2. '
            'Casual mein bhi colors ka match zaroori hai!';
      case 'party':
        return '$c1 aur $c2 party ke liye flop hai. Bold jao - '
            '${_getAlternativeColor(color1)} ya $c2 ke saath gold/silver '
            'accessories try karo!';
      case 'office':
        return '$c1 aur $c2 office ke liye appropriate nahi hai. '
            'Navy, grey, ya black ke saath ${_getAlternativeColor(color1)} '
            'try karo professional look ke liye.';
    }

    // Fallback
    if (score >= 80) {
      return '$c1 aur $c2 saath mein bahut achhe lagte hain! '
          'Ye classic combination hai jo hamesha kaam karta hai. '
          'Confidence se pehno!';
    }
    if (score >= 60) {
      return '$c1 aur $c2 theek lagenge. '
          'Thoda accessories se balance karo aur achha lagega.';
    }
    return '$c1 aur $c2 saath mein achhe nahi lagte. '
        'Better hai ki ${_getAlternativeColor(color1)} try karo.';
  }

  String _getAlternativeColor(String color) {
    switch (color) {
      case 'red': return 'black ya navy';
      case 'orange': return 'navy ya white';
      case 'pink': return 'grey ya navy';
      case 'purple': return 'white ya grey';
      case 'yellow': return 'navy ya grey';
      case 'green': return 'white ya cream';
      case 'brown': return 'cream ya light blue';
      case 'black': return 'white ya red';
      case 'white': return 'black ya navy';
      case 'navy': return 'white ya cream';
      case 'grey': return 'pink ya yellow';
      default: return 'white ya black';
    }
  }

  void _showColorPicker(int colorNumber) {
    final allColors = [
      'black', 'white', 'red', 'blue', 'green', 'yellow',
      'navy', 'grey', 'brown', 'beige', 'pink', 'orange',
      'purple', 'cream', 'maroon', 'olive',
    ];

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
              'Select Color $colorNumber',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allColors.map((color) {
                final colorObj = AppTheme.getColorFromName(color);
                final isSelected = colorNumber == 1
                    ? _selectedColor1 == color
                    : _selectedColor2 == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (colorNumber == 1) {
                        _selectedColor1 = color;
                      } else {
                        _selectedColor2 = color;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colorObj,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorObj.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        color[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColorForBg(colorObj),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(List<String> trendingColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Trending Colors',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your wardrobe',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (trendingColors.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: AppTheme.cardDecoration,
            child: Center(
              child: Text(
                'Add items to see color trends',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: trendingColors.take(8).map((color) {
                    return _buildColorTile(color, showName: true);
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  '${trendingColors.length} colors in your wardrobe',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildColorTile(String colorName, {bool showName = false}) {
    final color = AppTheme.getColorFromName(colorName);

    return Container(
      width: showName ? 70 : 56,
      child: Column(
        children: [
          Container(
            width: showName ? 60 : 48,
            height: showName ? 60 : 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                colorName.substring(0, 1).toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: showName ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: _textColorForBg(color),
                ),
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 6),
            Text(
              colorName,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestedSection(List<String> missingColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Colors to Buy',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Colors that would complement your wardrobe',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (missingColors.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: AppTheme.cardDecoration,
            child: Center(
              child: Text(
                'Great variety! No missing colors.',
                style: GoogleFonts.poppins(color: AppTheme.successColor),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: missingColors.map((color) {
                return _buildColorTile(color, showName: true);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCombosSection(List<List<String>> combos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outfit Color Combos',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Try these color combinations',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (combos.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: AppTheme.cardDecoration,
            child: Center(
              child: Text(
                'Add more colors to see combos',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...combos.map((combo) => _buildComboCard(combo)),
      ],
    );
  }

  Widget _buildComboCard(List<String> colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          ...colors.map((color) => Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.getColorFromName(color),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              colors.map((c) => c.toUpperCase()).join(' + '),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTrendingColors(List<String> allColors) {
    final colorCount = <String, int>{};
    for (final color in allColors) {
      colorCount[color] = (colorCount[color] ?? 0) + 1;
    }
    final sorted = colorCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  List<String> _getMissingColors(List<String> existingColors) {
    final existing = existingColors.toSet();
    final suggestions = <String>[];

    final complementaryMap = {
      'black': ['white', 'red'],
      'white': ['black', 'navy'],
      'blue': ['orange', 'white', 'brown'],
      'red': ['black', 'white'],
      'green': ['brown', 'white'],
      'brown': ['blue', 'cream'],
      'navy': ['white', 'beige'],
      'grey': ['pink', 'red'],
      'beige': ['navy', 'brown'],
    };

    for (final color in existing) {
      final complements = complementaryMap[color] ?? [];
      for (final comp in complements) {
        if (!existing.contains(comp) && !suggestions.contains(comp)) {
          suggestions.add(comp);
        }
      }
    }

    return suggestions.take(6).toList();
  }

  List<List<String>> _generateOutfitCombos(List<String> colors) {
    final combos = <List<String>>[];
    final colorSet = colors.toSet().toList();

    final classicCombos = [
      ['black', 'white'],
      ['navy', 'white'],
      ['brown', 'beige'],
      ['blue', 'white'],
      ['grey', 'black'],
      ['red', 'black'],
      ['green', 'brown'],
      ['navy', 'beige'],
    ];

    for (final combo in classicCombos) {
      if (colorSet.contains(combo[0]) && colorSet.contains(combo[1]) && combos.length < 5) {
        if (!combos.any((c) => c[0] == combo[0] && c[1] == combo[1])) {
          combos.add(combo);
        }
      }
    }

    if (combos.length < 3 && colorSet.length >= 2) {
      for (int i = 0; i < colorSet.length && combos.length < 5; i++) {
        for (int j = i + 1; j < colorSet.length && combos.length < 5; j++) {
          if (!combos.any((c) =>
              (c[0] == colorSet[i] && c[1] == colorSet[j]) ||
              (c[0] == colorSet[j] && c[1] == colorSet[i]))) {
            combos.add([colorSet[i], colorSet[j]]);
          }
        }
      }
    }

    return combos.take(5).toList();
  }

  Widget _buildTryTheseCombos() {
    final curatedCombos = [
      {'name': 'Classic Navy + White', 'colors': ['navy', 'white'], 'occasion': 'Formal'},
      {'name': 'Bold Red + Black', 'colors': ['red', 'black'], 'occasion': 'Party'},
      {'name': 'Earthy Olive + Beige', 'colors': ['olive', 'beige'], 'occasion': 'Casual'},
      {'name': 'Royal Blue + Cream', 'colors': ['royal blue', 'cream'], 'occasion': 'Formal'},
      {'name': 'Burgundy + Camel', 'colors': ['burgundy', 'camel'], 'occasion': 'Office'},
      {'name': 'Forest Green + Gold', 'colors': ['forest green', 'gold'], 'occasion': 'Party'},
      {'name': 'Grey + Lavender', 'colors': ['grey', 'lavender'], 'occasion': 'Casual'},
      {'name': 'Black + Silver', 'colors': ['black', 'silver'], 'occasion': 'Party'},
      {'name': 'Mustard + Navy', 'colors': ['mustard', 'navy'], 'occasion': 'Office'},
      {'name': 'Coral + White', 'colors': ['coral', 'white'], 'occasion': 'Casual'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Try These Combos',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Curated color combos that always work',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...curatedCombos.map((combo) {
          final colors = combo['colors'] as List<String>;
          final c1 = colors[0];
          final c2 = colors[1];
          final color1 = AppTheme.getColorFromName(c1);
          final color2 = AppTheme.getColorFromName(c2);
          final occasion = combo['occasion'] as String;
          final name = combo['name'] as String;
          final score = _calculateMatchScore(c1, c2, occasion);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor1 = c1;
                _selectedColor2 = c2;
                _selectedOccasion = occasion;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Color swatches
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color1, color2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name and occasion
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          occasion,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: score >= 85
                          ? Colors.green.withOpacity(0.1)
                          : score >= 70
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$score%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: score >= 85
                            ? Colors.green[700]
                            : score >= 70
                                ? Colors.blue[700]
                                : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _textColorForBg(Color bg) {
    final luminance = (0.299 * bg.red + 0.587 * bg.green + 0.114 * bg.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
