import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/clothing_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class CapsuleWardrobeScreen extends StatefulWidget {
  const CapsuleWardrobeScreen({super.key});

  @override
  State<CapsuleWardrobeScreen> createState() => _CapsuleWardrobeScreenState();
}

class _CapsuleWardrobeScreenState extends State<CapsuleWardrobeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storage = StorageService();

  List<ClothingItem> _allItems = [];
  final Set<String> _selectedIds = {};

  static const _storageKey = 'capsule_wardrobe_ids';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allItems = _storage.getWardrobe();
    _loadCapsule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCapsule() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? [];
    setState(() {
      _selectedIds.clear();
      _selectedIds.addAll(ids);
    });
  }

  Future<void> _saveCapsule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _selectedIds.toList());
  }

  List<ClothingItem> _itemsFor(ClothingCategory cat) =>
      _allItems.where((i) => i.category == cat).toList();

  List<ClothingItem> _selectedFor(ClothingCategory cat) =>
      _allItems.where((i) => i.category == cat && _selectedIds.contains(i.id)).toList();

  int get _topCount => _selectedFor(ClothingCategory.tops).length;
  int get _bottomCount => _selectedFor(ClothingCategory.bottoms).length;
  int get _outerwearCount => _selectedFor(ClothingCategory.outerwear).length;
  int get _accessoryCount => _selectedFor(ClothingCategory.accessories).length;

  int get _totalItems => _selectedIds.length;

  int get _outfitCombinations {
    if (_topCount == 0 || _bottomCount == 0) return 0;
    return _topCount *
        _bottomCount *
        (_outerwearCount + 1) *
        (_accessoryCount + 1);
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
    _saveCapsule();
  }

  void _getRandomOutfit() {
    final tops = _selectedFor(ClothingCategory.tops);
    final bottoms = _selectedFor(ClothingCategory.bottoms);
    if (tops.isEmpty || bottoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select at least 1 top and 1 bottom!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final rng = Random();
    final randomTop = tops[rng.nextInt(tops.length)];
    final randomBottom = bottoms[rng.nextInt(bottoms.length)];

    final outerwears = _selectedFor(ClothingCategory.outerwear);
    final accessories = _selectedFor(ClothingCategory.accessories);

    final randomOuterwear =
        outerwears.isNotEmpty ? outerwears[rng.nextInt(outerwears.length)] : null;
    final randomAccessory =
        accessories.isNotEmpty ? accessories[rng.nextInt(accessories.length)] : null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Random Outfit',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildOutfitItem(randomTop),
            const SizedBox(height: 12),
            _buildOutfitItem(randomBottom),
            if (randomOuterwear != null) ...[
              const SizedBox(height: 12),
              _buildOutfitItem(randomOuterwear),
            ],
            if (randomAccessory != null) ...[
              const SizedBox(height: 12),
              _buildOutfitItem(randomAccessory),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitItem(ClothingItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForCategory(item.category),
              color: AppTheme.getColorFromName(item.primaryColor),
              size: 22,
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
                ),
                const SizedBox(height: 2),
                Text(
                  item.category.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Capsule Wardrobe',
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
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
          tabs: const [
            Tab(text: 'Build Capsule'),
            Tab(text: 'View My Capsule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuildTab(),
          _buildViewTab(),
        ],
      ),
    );
  }

  Widget _buildBuildTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildStatsBar(),
          const SizedBox(height: 16),
          _buildStep('Step 1: Choose 5-7 Tops', ClothingCategory.tops, 5, 7),
          const SizedBox(height: 16),
          _buildStep('Step 2: Choose 3-5 Bottoms', ClothingCategory.bottoms, 3, 5),
          const SizedBox(height: 16),
          _buildStep('Step 3: Choose 2-3 Outerwear', ClothingCategory.outerwear, 2, 3),
          const SizedBox(height: 16),
          _buildStep('Step 4: Choose 3-5 Accessories', ClothingCategory.accessories, 3, 5),
          const SizedBox(height: 16),
          _buildOutfitCalculation(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            blurRadius: 12,
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'What is a Capsule Wardrobe?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A capsule wardrobe is a small, curated collection of versatile clothing items that can be mixed and matched to create dozens of unique outfits. Less clutter, more style!',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Target: 30 items se 50+ outfits banao',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Items', '$_totalItems/30', AppTheme.primaryColor),
          Container(width: 1, height: 24, color: AppTheme.dividerColor),
          _buildStatItem('Outfits', '$_outfitCombinations', AppTheme.successColor),
          Container(width: 1, height: 24, color: AppTheme.dividerColor),
          _buildStatItem('Ratio', _outfitRatio, AppTheme.warningColor),
        ],
      ),
    );
  }

  String get _outfitRatio {
    if (_totalItems == 0) return '0:0';
    return '1:${(_outfitCombinations / _totalItems).toStringAsFixed(1)}';
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String title, ClothingCategory category, int min, int max) {
    final items = _itemsFor(category);
    final selected = _selectedFor(category);
    final count = selected.length;
    final isGood = count >= min && count <= max;
    final isOver = count > max;

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isGood
                        ? AppTheme.successColor
                        : isOver
                            ? AppTheme.warningColor
                            : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isGood
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${category.index + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isOver ? Colors.white : AppTheme.primaryColor,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGood
                        ? AppTheme.successColor.withOpacity(0.1)
                        : isOver
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count/$max',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isGood
                          ? AppTheme.successColor
                          : isOver
                              ? AppTheme.warningColor
                              : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No ${category.name} in your wardrobe yet.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...items.map((item) => _buildItemCheckbox(item)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildItemCheckbox(ClothingItem item) {
    final isSelected = _selectedIds.contains(item.id);
    return InkWell(
      onTap: () => _toggle(item.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
              size: 22,
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (item.brand != null)
                    Text(
                      item.brand!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              item.primaryColor.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.getColorFromName(item.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitCalculation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outfit Combinations Possible',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_topCount tops x $_bottomCount bottoms x (${_outerwearCount}+1) outerwear x (${_accessoryCount}+1) accessories',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successColor,
                  AppTheme.successColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$_outfitCombinations',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Unique Outfits',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: _totalItems > 0 ? _getRandomOutfit : null,
              icon: const Icon(Icons.casino_outlined, size: 18),
              label: Text(
                'Get Random Outfit',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: AppTheme.textLight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab() {
    if (_selectedIds.isEmpty) {
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
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Capsule Items Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Build Capsule tab and select\nyour favorite items!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Start Building',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final grouped = <ClothingCategory, List<ClothingItem>>{};
    for (final item in _allItems.where((i) => _selectedIds.contains(i.id))) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  '$_totalItems items  |  $_outfitCombinations outfits',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _getRandomOutfit,
            icon: const Icon(Icons.casino_outlined, size: 18),
            label: Text(
              'Get Random Outfit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...grouped.entries.map((entry) => _buildViewCategory(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildViewCategory(ClothingCategory category, List<ClothingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _buildViewCard(item)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildViewCard(ClothingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForCategory(item.category),
              color: AppTheme.getColorFromName(item.primaryColor),
              size: 20,
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
                ),
                if (item.brand != null)
                  Text(
                    item.brand!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _toggle(item.id);
            },
            icon: Icon(
              Icons.remove_circle_outline,
              color: AppTheme.errorColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
