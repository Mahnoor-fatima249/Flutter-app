import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/clothing_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class WardrobeOptimizerScreen extends StatefulWidget {
  const WardrobeOptimizerScreen({super.key});

  @override
  State<WardrobeOptimizerScreen> createState() =>
      _WardrobeOptimizerScreenState();
}

class _WardrobeOptimizerScreenState extends State<WardrobeOptimizerScreen> {
  final StorageService _storage = StorageService();
  Map<String, Map<String, dynamic>> _wearData = {};
  List<ClothingItem> _allItems = [];
  bool _isLoading = true;

  List<ClothingItem> _keepItems = [];
  List<ClothingItem> _donateItems = [];
  List<ClothingItem> _repairItems = [];
  List<String> _buySuggestions = [];
  double _healthScore = 0;
  List<String> _tips = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('wear_log_data');
    if (data != null) {
      final Map<String, dynamic> decoded = json.decode(data);
      _wearData = decoded.map((key, value) =>
          MapEntry(key, Map<String, dynamic>.from(value)));
    }
    _allItems = _storage.getWardrobe();
    _analyzeWardrobe();
    setState(() => _isLoading = false);
  }

  int? _daysSinceWorn(String itemId) {
    final wearInfo = _wearData[itemId];
    if (wearInfo == null || wearInfo['lastWorn'] == null) return null;
    final lastWorn = DateTime.parse(wearInfo['lastWorn']);
    return DateTime.now().difference(lastWorn).inDays;
  }

  int _getWearCount(String itemId) {
    final wearInfo = _wearData[itemId];
    if (wearInfo == null) return 0;
    return wearInfo['wearCount'] ?? 0;
  }

  void _analyzeWardrobe() {
    _keepItems = [];
    _donateItems = [];
    _repairItems = [];
    _buySuggestions = [];
    _tips = [];

    for (final item in _allItems) {
      final days = _daysSinceWorn(item.id);
      final wearCount = _getWearCount(item.id);

      if (days == null || days >= 60) {
        _donateItems.add(item);
      } else if (wearCount > 20) {
        _repairItems.add(item);
      } else if (item.isFavorite || (days < 14 && wearCount > 0)) {
        _keepItems.add(item);
      }
    }

    final hasWornItems =
        _allItems.any((i) => _wearData.containsKey(i.id) && _getWearCount(i.id) > 0);
    if (!hasWornItems && _keepItems.isEmpty) {
      _keepItems = _allItems.where((i) => i.isFavorite).toList();
      if (_keepItems.isEmpty && _allItems.isNotEmpty) {
        _keepItems = _allItems.take(5).toList();
      }
    }

    _generateBuySuggestions();
    _calculateHealthScore();
    _generateTips();
  }

  void _generateBuySuggestions() {
    final categoryCount = <ClothingCategory, int>{};
    for (final item in _allItems) {
      categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
    }

    final essentialCategories = {
      ClothingCategory.tops: 'Basic T-shirts or shirts',
      ClothingCategory.bottoms: 'Pants or jeans',
      ClothingCategory.outerwear: 'A jacket or coat',
      ClothingCategory.footwear: 'Everyday shoes',
      ClothingCategory.accessories: 'A watch or bag',
    };

    for (final entry in essentialCategories.entries) {
      if ((categoryCount[entry.key] ?? 0) == 0) {
        _buySuggestions.add('Add ${entry.value}');
      }
    }

    final colorDiversity = _storage.getColorDistribution().length;
    if (colorDiversity < 5 && _allItems.length > 3) {
      _buySuggestions.add('Add more color variety');
    }

    final hasNavy = _allItems.any((i) =>
        i.primaryColor.toLowerCase() == 'navy' ||
        i.colors.any((c) => c.toLowerCase() == 'navy'));
    final hasBlack = _allItems.any((i) =>
        i.primaryColor.toLowerCase() == 'black' ||
        i.colors.any((c) => c.toLowerCase() == 'black'));
    final hasWhite = _allItems.any((i) =>
        i.primaryColor.toLowerCase() == 'white' ||
        i.colors.any((c) => c.toLowerCase() == 'white'));

    if (!hasNavy && _allItems.isNotEmpty) {
      _buySuggestions.add('Navy pants - versatile essential');
    }
    if (!hasBlack && _allItems.isNotEmpty) {
      _buySuggestions.add('Black bottom - goes with everything');
    }
    if (!hasWhite && _allItems.isNotEmpty) {
      _buySuggestions.add('White shirt - wardrobe staple');
    }

    final seasonCoverage = <ClothingSeason, int>{};
    for (final item in _allItems) {
      for (final season in item.seasons) {
        seasonCoverage[season] = (seasonCoverage[season] ?? 0) + 1;
      }
    }

    final currentMonth = DateTime.now().month;
    ClothingSeason? neededSeason;
    if (currentMonth >= 3 && currentMonth <= 5) {
      neededSeason = ClothingSeason.spring;
    } else if (currentMonth >= 6 && currentMonth <= 8) {
      neededSeason = ClothingSeason.summer;
    } else if (currentMonth >= 9 && currentMonth <= 11) {
      neededSeason = ClothingSeason.autumn;
    } else {
      neededSeason = ClothingSeason.winter;
    }

    if ((seasonCoverage[neededSeason] ?? 0) == 0 &&
        (seasonCoverage[ClothingSeason.allSeason] ?? 0) == 0 &&
        _allItems.isNotEmpty) {
      _buySuggestions.add('${neededSeason.name} clothing needed');
    }
  }

  void _calculateHealthScore() {
    if (_allItems.isEmpty) {
      _healthScore = 0;
      return;
    }

    double score = 0;

    // Category balance (25 pts)
    final categoryCount = <ClothingCategory, int>{};
    for (final item in _allItems) {
      categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
    }
    int categoriesPresent = 0;
    for (final cat in ClothingCategory.values) {
      if ((categoryCount[cat] ?? 0) > 0) categoriesPresent++;
    }
    score += (categoriesPresent / ClothingCategory.values.length) * 25;

    // Color diversity (25 pts)
    final uniqueColors = _storage.getColorDistribution().length;
    if (uniqueColors >= 8) {
      score += 25;
    } else {
      score += (uniqueColors / 8) * 25;
    }

    // Season coverage (25 pts)
    final seasonCoverage = <ClothingSeason, int>{};
    for (final item in _allItems) {
      for (final season in item.seasons) {
        seasonCoverage[season] = (seasonCoverage[season] ?? 0) + 1;
      }
    }
    int seasonsCovered = 0;
    for (final season in ClothingSeason.values) {
      if ((seasonCoverage[season] ?? 0) > 0) seasonsCovered++;
    }
    score += (seasonsCovered / ClothingSeason.values.length) * 25;

    // Wear frequency (25 pts)
    int totalWears = 0;
    for (final item in _allItems) {
      totalWears += _getWearCount(item.id);
    }
    final avgWears = _allItems.isNotEmpty ? totalWears / _allItems.length : 0;
    if (avgWears >= 5) {
      score += 25;
    } else {
      score += (avgWears / 5) * 25;
    }

    _healthScore = score.clamp(0, 100);
  }

  void _generateTips() {
    if (_allItems.isEmpty) {
      _tips.add('Start by adding items to your wardrobe');
      return;
    }

    if (_donateItems.length > _allItems.length * 0.3) {
      _tips.add('Many items unused - consider decluttering');
    }

    final categoryCount = <ClothingCategory, int>{};
    for (final item in _allItems) {
      categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
    }
    final topCount = categoryCount[ClothingCategory.tops] ?? 0;
    final bottomCount = categoryCount[ClothingCategory.bottoms] ?? 0;
    if (topCount > bottomCount * 3) {
      _tips.add('More tops than bottoms - balance your wardrobe');
    }
    if (bottomCount > topCount * 3) {
      _tips.add('More bottoms than tops - add more shirts');
    }

    final uniqueColors = _storage.getColorDistribution().length;
    if (uniqueColors < 4) {
      _tips.add('Limited colors - try adding neutral basics');
    }

    int totalWears = 0;
    for (final item in _allItems) {
      totalWears += _getWearCount(item.id);
    }
    if (_allItems.isNotEmpty && totalWears / _allItems.length < 2) {
      _tips.add('Low wear average - try wearing more variety');
    }

    final neutralColors = ['black', 'white', 'grey', 'gray', 'navy', 'beige', 'cream'];
    bool hasNeutrals = _allItems.any((i) =>
        neutralColors.contains(i.primaryColor.toLowerCase()));
    if (!hasNeutrals && _allItems.length > 3) {
      _tips.add('No neutral colors - add black/white basics');
    }

    final hasOuterwear =
        categoryCount[ClothingCategory.outerwear] != null &&
            categoryCount[ClothingCategory.outerwear]! > 0;
    if (!hasOuterwear && _allItems.length > 5) {
      _tips.add('No outerwear - consider a versatile jacket');
    }

    if (_tips.isEmpty) {
      _tips.add('Your wardrobe is well-balanced!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Wardrobe Optimizer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allItems.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHealthScoreCard(),
                      const SizedBox(height: 16),
                      _buildTipsSection(),
                      const SizedBox(height: 16),
                      _buildSection(
                        'What to Keep',
                        Icons.favorite,
                        AppTheme.successColor,
                        _keepItems,
                        'Items worn frequently or highly rated',
                      ),
                      const SizedBox(height: 16),
                      _buildDonateSection(),
                      const SizedBox(height: 16),
                      _buildRepairSection(),
                      const SizedBox(height: 16),
                      _buildBuySection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Items to Analyze',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your wardrobe first',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    final scoreColor = _healthScore >= 70
        ? AppTheme.successColor
        : _healthScore >= 40
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor, scoreColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _healthScore / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${_healthScore.round()}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wardrobe Health',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _healthScore >= 80
                      ? 'Excellent! Your wardrobe is thriving'
                      : _healthScore >= 60
                          ? 'Good - room for improvement'
                          : _healthScore >= 40
                              ? 'Fair - consider the tips below'
                              : 'Needs attention - see suggestions',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildScoreBadge('${_allItems.length} items', Colors.white),
                    const SizedBox(width: 8),
                    _buildScoreBadge(
                        '${_storage.getColorDistribution().length} colors',
                        Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Improvement Tips',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._tips.map((tip) => _buildTipItem(tip)),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<ClothingItem> items,
    String subtitle,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title (${items.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
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
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No items in this category',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...items.take(5).map((item) => _buildItemCard(item, color)),
          if (items.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${items.length - 5} more items',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDonateSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warningColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What to Donate (${_donateItems.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Not worn in 60+ days',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_donateItems.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No items to donate - great job!',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ..._donateItems.take(5).map((item) {
              final days = _daysSinceWorn(item.id);
              return _buildDonateCard(item, days);
            }),
          if (_donateItems.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${_donateItems.length - 5} more items',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDonateCard(ClothingItem item, int? days) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForCategory(item.category),
              color: AppTheme.getColorFromName(item.primaryColor),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  days == null ? 'Never worn' : '$days days since worn',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppTheme.textLight,
          ),
        ],
      ),
    );
  }

  Widget _buildRepairSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.build_outlined,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What to Repair (${_repairItems.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Worn 20+ times - may need attention',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_repairItems.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No items need repair',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ..._repairItems.take(5).map((item) {
              final wearCount = _getWearCount(item.id);
              return _buildRepairCard(item, wearCount);
            }),
          if (_repairItems.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${_repairItems.length - 5} more items',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRepairCard(ClothingItem item, int wearCount) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForCategory(item.category),
              color: AppTheme.getColorFromName(item.primaryColor),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Worn $wearCount times',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Check',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What to Buy (${_buySuggestions.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Suggested additions for a balanced wardrobe',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_buySuggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Your wardrobe essentials are covered!',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ..._buySuggestions.map((suggestion) => _buildBuyItem(suggestion)),
        ],
      ),
    );
  }

  Widget _buildBuyItem(String suggestion) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suggestion,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppTheme.textLight,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ClothingItem item, Color color) {
    final wearCount = _getWearCount(item.id);
    final days = _daysSinceWorn(item.id);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForCategory(item.category),
              color: AppTheme.getColorFromName(item.primaryColor),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(Icons.repeat, size: 12, color: AppTheme.textLight),
                    const SizedBox(width: 4),
                    Text(
                      '$wearCount wears',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      days == null
                          ? 'Never worn'
                          : days == 0
                              ? 'Worn today'
                              : '$days days ago',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (item.isFavorite)
            const Icon(
              Icons.favorite,
              color: AppTheme.secondaryColor,
              size: 18,
            ),
        ],
      ),
    );
  }

  IconData _iconForCategory(ClothingCategory cat) {
    switch (cat) {
      case ClothingCategory.tops:
        return Icons.checkroom;
      case ClothingCategory.bottoms:
        return Icons.accessibility_new;
      case ClothingCategory.outerwear:
        return Icons.ac_unit;
      case ClothingCategory.dresses:
        return Icons.woman;
      case ClothingCategory.footwear:
        return Icons.directions_walk;
      case ClothingCategory.accessories:
        return Icons.watch;
      case ClothingCategory.activewear:
        return Icons.fitness_center;
      case ClothingCategory.formal:
        return Icons.business_center;
    }
  }
}
