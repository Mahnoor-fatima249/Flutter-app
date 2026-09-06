import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/clothing_item.dart';

class SeasonalPlannerScreen extends StatefulWidget {
  const SeasonalPlannerScreen({super.key});

  @override
  State<SeasonalPlannerScreen> createState() => _SeasonalPlannerScreenState();
}

class _SeasonalPlannerScreenState extends State<SeasonalPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storage = StorageService();
  Map<String, Set<String>> _seasonReadyItems = {};

  final List<_SeasonData> _seasons = [
    _SeasonData(
      name: 'Summer',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFFF9800),
      season: ClothingSeason.summer,
      requiredCategories: [ClothingCategory.tops, ClothingCategory.bottoms],
      requiredKeywords: ['shorts', 'light', 'linen', 'cotton', 'tank'],
      suggestions: 'Summer mein ye zaroori hai: Cotton shirts, Light colored pants, Shorts, Linen kurtas',
    ),
    _SeasonData(
      name: 'Winter',
      icon: Icons.ac_unit_outlined,
      color: Color(0xFF2196F3),
      season: ClothingSeason.winter,
      requiredCategories: [ClothingCategory.outerwear, ClothingCategory.tops],
      requiredKeywords: ['jacket', 'sweater', 'layer', 'wool', 'hoodie'],
      suggestions: 'Winter essentials: Jackets, Sweaters, Hoodies, Thermal layers, Wool scarves',
    ),
    _SeasonData(
      name: 'Monsoon',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF009688),
      season: ClothingSeason.autumn,
      requiredCategories: [ClothingCategory.tops, ClothingCategory.footwear],
      requiredKeywords: ['waterproof', 'quick-dry', 'rain', 'water resistant'],
      suggestions: 'Monsoon must-haves: Waterproof jacket, Quick-dry pants, Rain boots, Water-resistant bag',
    ),
    _SeasonData(
      name: 'Spring',
      icon: Icons.eco_outlined,
      color: Color(0xFF4CAF50),
      season: ClothingSeason.spring,
      requiredCategories: [ClothingCategory.tops, ClothingCategory.outerwear],
      requiredKeywords: ['light', 'layer', 'transitional', 'cardigan', 'floral'],
      suggestions: 'Spring picks: Light cardigans, Floral prints, Transitional jackets, Breathable layers',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSeasonReadyItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSeasonReadyItems() {
    final settings = _storage.getSettings();
    final saved = settings['season_ready_items'];
    if (saved != null && saved is Map) {
      saved.forEach((key, value) {
        if (value is List) {
          _seasonReadyItems[key] = Set<String>.from(value.map((e) => e.toString()));
        }
      });
    }
  }

  Future<void> _saveSeasonReadyItems() async {
    final map = <String, List<String>>{};
    _seasonReadyItems.forEach((key, value) {
      map[key] = value.toList();
    });
    await _storage.saveSetting('season_ready_items', map);
  }

  void _toggleSeasonReady(String seasonName, String itemId) {
    setState(() {
      _seasonReadyItems.putIfAbsent(seasonName, () => {});
      if (_seasonReadyItems[seasonName]!.contains(itemId)) {
        _seasonReadyItems[seasonName]!.remove(itemId);
      } else {
        _seasonReadyItems[seasonName]!.add(itemId);
      }
    });
    _saveSeasonReadyItems();
  }

  bool _isSeasonReady(String seasonName, String itemId) {
    return _seasonReadyItems[seasonName]?.contains(itemId) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Season Planner',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _seasons.map((s) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s.icon, size: 18),
                const SizedBox(width: 4),
                Text(s.name),
              ],
            ),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _seasons.map((season) => _buildSeasonTab(season)).toList(),
      ),
    );
  }

  Widget _buildSeasonTab(_SeasonData season) {
    final allItems = _storage.getWardrobe();
    final matchingItems = allItems.where((item) =>
      item.seasons.contains(season.season) ||
      item.seasons.contains(ClothingSeason.allSeason)
    ).toList();
    final missingItems = allItems.where((item) =>
      !item.seasons.contains(season.season) &&
      !item.seasons.contains(ClothingSeason.allSeason)
    ).toList();

    final totalItems = allItems.length;
    final readyCount = matchingItems.where((item) =>
      _isSeasonReady(season.name, item.id)
    ).length;
    final score = totalItems > 0 ? ((readyCount / totalItems) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSeasonHeader(season, score, matchingItems.length, missingItems.length),
          const SizedBox(height: 16),
          if (matchingItems.isNotEmpty) ...[
            _buildSectionTitle('Your ${season.name} Wardrobe', matchingItems.length, isReady: true),
            const SizedBox(height: 8),
            ...matchingItems.map((item) => _buildItemCard(item, season, isMatching: true)),
            const SizedBox(height: 20),
          ],
          if (missingItems.isNotEmpty) ...[
            _buildSectionTitle('Missing Items', missingItems.length, isReady: false),
            const SizedBox(height: 8),
            ...missingItems.map((item) => _buildItemCard(item, season, isMatching: false)),
            const SizedBox(height: 20),
          ],
          if (allItems.isEmpty) _buildEmptyState(),
          _buildSuggestionsCard(season),
        ],
      ),
    );
  }

  Widget _buildSeasonHeader(_SeasonData season, int score, int matchingCount, int missingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            season.color,
            season.color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: season.color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(season.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${season.name} Season',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Wardrobe readiness check',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              _buildScoreBadge(score),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(Icons.check_circle_outline, '$matchingCount Items Ready'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.highlight_off, '$missingCount Missing'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
      ),
      child: Center(
        child: Text(
          '$score%',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count, {required bool isReady}) {
    return Row(
      children: [
        Icon(
          isReady ? Icons.check_circle : Icons.info_outline,
          color: isReady ? AppTheme.successColor : AppTheme.warningColor,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isReady ? AppTheme.successColor.withOpacity(0.1) : AppTheme.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isReady ? AppTheme.successColor : AppTheme.warningColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(ClothingItem item, _SeasonData season, {required bool isMatching}) {
    final isReady = _isSeasonReady(season.name, item.id);
    final File imageFile = File(item.imagePath);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isMatching
            ? Border.all(color: AppTheme.successColor.withOpacity(0.3), width: 1.5)
            : Border.all(color: AppTheme.warningColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: imageFile.existsSync()
                  ? Image.file(imageFile, fit: BoxFit.cover)
                  : Container(
                      color: AppTheme.backgroundColor,
                      child: Icon(
                        _getCategoryIcon(item.category),
                        color: AppTheme.textLight,
                        size: 24,
                      ),
                    ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.getColorFromName(item.primaryColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.category.name.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!isMatching) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MISSING',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.warningColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _toggleSeasonReady(season.name, item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isReady ? AppTheme.warningColor.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isReady ? Icons.star : Icons.star_border,
                color: isReady ? AppTheme.warningColor : AppTheme.textLight,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(_SeasonData season) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: season.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: season.color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: season.color, size: 20),
              const SizedBox(width: 6),
              Text(
                '${season.name} Shopping Guide',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: season.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            season.suggestions,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.checkroom_outlined, color: AppTheme.textLight, size: 48),
          const SizedBox(height: 12),
          Text(
            'No wardrobe items yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add clothes to see seasonal readiness',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ClothingCategory category) {
    switch (category) {
      case ClothingCategory.tops:
        return Icons.checkroom;
      case ClothingCategory.bottoms:
        return Icons.accessibility_new;
      case ClothingCategory.outerwear:
        return Icons.dry_cleaning;
      case ClothingCategory.dresses:
        return Icons.woman;
      case ClothingCategory.footwear:
        return Icons.store;
      case ClothingCategory.accessories:
        return Icons.watch;
      case ClothingCategory.activewear:
        return Icons.fitness_center;
      case ClothingCategory.formal:
        return Icons.business_center;
      default:
        return Icons.checkroom;
    }
  }
}

class _SeasonData {
  final String name;
  final IconData icon;
  final Color color;
  final ClothingSeason season;
  final List<ClothingCategory> requiredCategories;
  final List<String> requiredKeywords;
  final String suggestions;

  _SeasonData({
    required this.name,
    required this.icon,
    required this.color,
    required this.season,
    required this.requiredCategories,
    required this.requiredKeywords,
    required this.suggestions,
  });
}
