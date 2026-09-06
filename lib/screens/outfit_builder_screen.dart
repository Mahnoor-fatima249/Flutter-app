import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/clothing_item.dart';
import '../models/outfit_calendar.dart';
import '../services/storage_service.dart';
import '../services/features_service.dart';
import '../theme/app_theme.dart';

class OutfitBuilderScreen extends StatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  final StorageService _storage = StorageService();
  final FeaturesService _features = FeaturesService();

  ClothingItem? _selectedTop;
  ClothingItem? _selectedBottom;
  ClothingItem? _selectedOuterwear;
  ClothingItem? _selectedAccessory;

  late List<ClothingItem> _allItems;

  @override
  void initState() {
    super.initState();
    _allItems = _storage.getWardrobe();
  }

  List<ClothingItem> _itemsForSlot(ClothingCategory category) {
    return _allItems.where((item) => item.category == category).toList();
  }

  bool get _hasTop => _selectedTop != null;
  bool get _hasBottom => _selectedBottom != null;
  bool get _canSave => _hasTop && _hasBottom;

  // ─── Color Harmony ───────────────────────────────────────

  int _calculateColorHarmony() {
    final selected = [_selectedTop, _selectedBottom, _selectedOuterwear, _selectedAccessory]
        .whereType<ClothingItem>()
        .toList();
    if (selected.length < 2) return 0;

    int score = 0;
    final allColors = selected.expand((i) => i.colors).toList();
    final uniqueColors = allColors.toSet().toList();

    // Neutral palette boost
    final neutrals = {'black', 'white', 'grey', 'gray', 'navy', 'beige', 'cream', 'brown'};
    final neutralCount = uniqueColors.where((c) => neutrals.contains(c.toLowerCase())).length;
    if (neutralCount >= 2) score += 30;

    // Monochromatic check (shades of same hue)
    final primaryColors = selected.map((i) => i.primaryColor.toLowerCase()).toSet();
    if (primaryColors.length == 1) score += 25;

    // Complementary check - basic complementary pairs
    final complementaryPairs = {
      'blue': 'orange',
      'red': 'green',
      'yellow': 'purple',
      'navy': 'beige',
    };
    final colorSet = uniqueColors.map((c) => c.toLowerCase()).toSet();
    for (final pair in complementaryPairs.entries) {
      if (colorSet.contains(pair.key) && colorSet.contains(pair.value)) {
        score += 20;
        break;
      }
    }

    // Analogous check (colors next to each other on color wheel)
    final analogousGroups = [
      {'red', 'orange', 'yellow'},
      {'green', 'teal', 'blue'},
      {'blue', 'purple', 'pink'},
      {'yellow', 'green', 'teal'},
    ];
    for (final group in analogousGroups) {
      final matches = colorSet.where((c) => group.contains(c)).length;
      if (matches >= 2) {
        score += 15;
        break;
      }
    }

    // Limited palette (2-3 colors is harmonious)
    if (uniqueColors.length <= 3) score += 10;

    return score.clamp(0, 100);
  }

  // ─── Occasion ────────────────────────────────────────────

  String _determineOccasion() {
    final selected = [_selectedTop, _selectedBottom, _selectedOuterwear, _selectedAccessory]
        .whereType<ClothingItem>()
        .toList();
    if (selected.isEmpty) return 'Casual';

    final allOccasions = selected.expand((i) => i.occasions).toList();
    final formalCount = allOccasions.where((o) => o == OccasionType.formal || o == OccasionType.work).length;
    final partyCount = allOccasions.where((o) => o == OccasionType.party || o == OccasionType.date).length;
    final casualCount = allOccasions.where((o) => o == OccasionType.casual || o == OccasionType.outdoor).length;

    if (formalCount > partyCount && formalCount > casualCount) return 'Formal';
    if (partyCount > formalCount && partyCount > casualCount) return 'Party';
    return 'Casual';
  }

  // ─── Season ──────────────────────────────────────────────

  String _determineSeasonMatch() {
    final selected = [_selectedTop, _selectedBottom, _selectedOuterwear, _selectedAccessory]
        .whereType<ClothingItem>()
        .toList();
    if (selected.isEmpty) return 'Any';

    final now = DateTime.now().month;
    ClothingSeason currentSeason;
    if (now >= 3 && now <= 5) {
      currentSeason = ClothingSeason.spring;
    } else if (now >= 6 && now <= 8) {
      currentSeason = ClothingSeason.summer;
    } else if (now >= 9 && now <= 11) {
      currentSeason = ClothingSeason.autumn;
    } else {
      currentSeason = ClothingSeason.winter;
    }

    final allSeasonMatch = selected.every((i) =>
        i.seasons.contains(ClothingSeason.allSeason) || i.seasons.contains(currentSeason));
    if (allSeasonMatch) return 'Perfect';

    final someMatch = selected.any((i) =>
        i.seasons.contains(ClothingSeason.allSeason) || i.seasons.contains(currentSeason));
    if (someMatch) return 'Partial';

    return 'Mismatch';
  }

  // ─── Style Tips ──────────────────────────────────────────

  List<String> _generateStyleTips() {
    final tips = <String>[];
    final selected = [_selectedTop, _selectedBottom, _selectedOuterwear, _selectedAccessory]
        .whereType<ClothingItem>()
        .toList();

    if (selected.isEmpty) return ['Add at least a top and bottom to get tips!'];

    final harmony = _calculateColorHarmony();
    if (harmony >= 70) {
      tips.add('Great color combo! This palette is well-coordinated.');
    } else if (harmony >= 40) {
      tips.add('Try adding a neutral piece to balance the colors.');
    } else {
      tips.add('Consider matching with a monochrome or neutral palette.');
    }

    if (selected.length == 2) {
      tips.add('Add an accessory or layer for more depth.');
    }

    final hasOuterwear = _selectedOuterwear != null;
    if (!hasOuterwear && _determineSeasonMatch() != 'Perfect') {
      tips.add('A jacket could help adapt this outfit to the weather.');
    }

    if (_selectedTop != null && _selectedBottom != null) {
      if (_selectedTop!.primaryColor.toLowerCase() == _selectedBottom!.primaryColor.toLowerCase()) {
        tips.add('Same-color top & bottom — add contrast with a belt or shoes.');
      }
    }

    final occasion = _determineOccasion();
    if (occasion == 'Formal') {
      tips.add('Complete the formal look with polished footwear.');
    } else if (occasion == 'Party') {
      tips.add('A bold accessory can elevate this party-ready outfit.');
    }

    return tips.isEmpty ? ['Looks good! Trust your style instincts.'] : tips;
  }

  // ─── Save ────────────────────────────────────────────────

  Future<void> _saveOutfit() async {
    final ids = [_selectedTop, _selectedBottom, _selectedOuterwear, _selectedAccessory]
        .whereType<ClothingItem>()
        .map((i) => i.id)
        .toList();

    final entry = OutfitCalendar(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      itemIds: ids,
      notes: 'Built with Outfit Builder',
      occasion: _determineOccasion(),
    );

    await _features.addCalendarEntry(entry);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Outfit saved!', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ─── Share Card ──────────────────────────────────────────

  void _showShareCard() {
    final items = [_selectedTop, _selectedBottom, _selectedOuterwear, _selectedAccessory]
        .whereType<ClothingItem>()
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pehle koi outfit select karo!', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShareCard(items),
    );
  }

  // ─── Bottom Sheet: Pick Item ─────────────────────────────

  void _showItemPicker(String title, ClothingCategory category, Function(ClothingItem) onSelect) {
    final available = _itemsForSlot(category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (available.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.checkroom_outlined, size: 56, color: AppTheme.textLight),
                          const SizedBox(height: 16),
                          Text(
                            'Pehle wardrobe mein kapde add karo',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Is category mein abhi koi item nahi hai.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: available.length + 1, // +1 for skip option
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close, color: AppTheme.textSecondary),
                          ),
                          title: Text(
                            'Skip this slot',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      }
                      final item = available[index - 1];
                      return _buildItemTile(item, () {
                        Navigator.pop(context);
                        onSelect(item);
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(ClothingItem item, VoidCallback onTap) {
    final hasImage = item.imagePath.isNotEmpty && File(item.imagePath).existsSync();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            color: AppTheme.backgroundColor,
            child: hasImage
                ? Image.file(File(item.imagePath), fit: BoxFit.cover)
                : Icon(
                    _iconForCategory(item.category),
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.getColorFromName(item.primaryColor),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.dividerColor, width: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.primaryColor[0].toUpperCase() + item.primaryColor.substring(1),
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
            ),
            const SizedBox(width: 8),
            Text(
              item.brand ?? 'No brand',
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight, size: 20),
        onTap: onTap,
      ),
    );
  }

  // ─── Slot Icon ───────────────────────────────────────────

  IconData _iconForCategory(ClothingCategory cat) {
    switch (cat) {
      case ClothingCategory.tops:
        return Icons.checkroom;
      case ClothingCategory.bottoms:
        return Icons.accessibility_new;
      case ClothingCategory.outerwear:
        return Icons.dry_cleaning;
      case ClothingCategory.accessories:
        return Icons.watch;
      case ClothingCategory.dresses:
        return Icons.woman;
      case ClothingCategory.footwear:
        return Icons.directions_walk;
      case ClothingCategory.activewear:
        return Icons.fitness_center;
      case ClothingCategory.formal:
        return Icons.business_center;
    }
  }

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final harmony = _calculateColorHarmony();
    final occasion = _determineOccasion();
    final seasonMatch = _determineSeasonMatch();
    final tips = _generateStyleTips();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Outfit Builder',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _allItems.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSlotGrid(),
                  const SizedBox(height: 20),
                  _buildAnalysisCard(harmony, occasion, seasonMatch, tips),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checkroom_outlined,
                size: 56,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pehle wardrobe mein kapde add karo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Wardrobe mein kapde hone pe yahan outfit build kar sakte ho.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Slot Grid ───────────────────────────────────────────

  Widget _buildSlotGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Build Your Outfit',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap each slot to pick from your wardrobe',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildSlot('Top', Icons.checkroom, ClothingCategory.tops, _selectedTop, (item) {
              setState(() => _selectedTop = item);
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildSlot('Bottom', Icons.accessibility_new, ClothingCategory.bottoms, _selectedBottom, (item) {
              setState(() => _selectedBottom = item);
            })),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSlot('Outerwear', Icons.dry_cleaning, ClothingCategory.outerwear, _selectedOuterwear, (item) {
              setState(() => _selectedOuterwear = item);
            }, optional: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildSlot('Accessory', Icons.watch, ClothingCategory.accessories, _selectedAccessory, (item) {
              setState(() => _selectedAccessory = item);
            }, optional: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildSlot(
    String label,
    IconData icon,
    ClothingCategory category,
    ClothingItem? selected,
    Function(ClothingItem) onSelect, {
    bool optional = false,
  }) {
    final hasImage = selected != null && selected.imagePath.isNotEmpty && File(selected.imagePath).existsSync();
    final categoryTitles = {
      ClothingCategory.tops: 'Pick a Top',
      ClothingCategory.bottoms: 'Pick a Bottom',
      ClothingCategory.outerwear: 'Pick Outerwear',
      ClothingCategory.accessories: 'Pick an Accessory',
    };

    return GestureDetector(
      onTap: () => _showItemPicker(categoryTitles[category]!, category, onSelect),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected != null ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: selected != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected != null ? AppTheme.primaryColor : Colors.black).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.file(File(selected!.imagePath), fit: BoxFit.cover),
                ),
              )
            else if (selected != null)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 28),
              )
            else
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.textLight, size: 28),
              ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected != null ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            if (selected != null)
              Text(
                selected.name,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                optional ? 'Optional' : 'Tap to pick',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textLight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Analysis Card ───────────────────────────────────────

  Widget _buildAnalysisCard(int harmony, String occasion, String seasonMatch, List<String> tips) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outfit Analysis',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildHarmonyBar(harmony),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Occasion',
                  occasion,
                  occasion == 'Formal'
                      ? Icons.business_center
                      : occasion == 'Party'
                          ? Icons.celebration
                          : Icons.wb_sunny_outlined,
                  _occasionColor(occasion),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Season',
                  seasonMatch,
                  seasonMatch == 'Perfect'
                      ? Icons.check_circle_outline
                      : seasonMatch == 'Partial'
                          ? Icons.warning_amber_outlined
                          : Icons.info_outline,
                  _seasonColor(seasonMatch),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppTheme.dividerColor, height: 1),
          const SizedBox(height: 14),
          Text(
            'Style Tips',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHarmonyBar(int score) {
    Color barColor;
    String label;
    if (score >= 70) {
      barColor = AppTheme.successColor;
      label = 'Excellent';
    } else if (score >= 40) {
      barColor = AppTheme.warningColor;
      label = 'Good';
    } else if (score > 0) {
      barColor = AppTheme.errorColor;
      label = 'Needs Work';
    } else {
      barColor = AppTheme.textLight;
      label = 'Select items';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Color Harmony',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$label · $score/100',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: barColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: AppTheme.backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _occasionColor(String occasion) {
    switch (occasion) {
      case 'Formal':
        return const Color(0xFF1E3A5F);
      case 'Party':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.warningColor;
    }
  }

  Color _seasonColor(String season) {
    switch (season) {
      case 'Perfect':
        return AppTheme.successColor;
      case 'Partial':
        return AppTheme.warningColor;
      default:
        return AppTheme.errorColor;
    }
  }

  // ─── Action Buttons ──────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _canSave ? _saveOutfit : null,
            icon: const Icon(Icons.bookmark_add_outlined, size: 20),
            label: Text(
              'Save Outfit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.textLight.withOpacity(0.3),
              disabledForegroundColor: AppTheme.textLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showShareCard,
            icon: const Icon(Icons.share_outlined, size: 20),
            label: Text(
              'Share Card',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Share Card Bottom Sheet ─────────────────────────────

  Widget _buildShareCard(List<ClothingItem> items) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Outfit Card',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Outfit',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final hasImage = item.imagePath.isNotEmpty && File(item.imagePath).existsSync();
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (hasImage)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: Image.file(File(item.imagePath), fit: BoxFit.cover),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _iconForCategory(item.category),
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  item.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  item.category.name[0].toUpperCase() + item.category.name.substring(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Color Harmony: ${_calculateColorHarmony()}/100',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
