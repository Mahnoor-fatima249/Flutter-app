import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clothing_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class MixMatchScreen extends StatefulWidget {
  const MixMatchScreen({super.key});

  @override
  State<MixMatchScreen> createState() => _MixMatchScreenState();
}

class _MixMatchScreenState extends State<MixMatchScreen> {
  final StorageService _storage = StorageService();
  final List<ClothingItem> _selectedItems = [];
  String? _compatibilityRating;
  String? _suggestion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mix & Match',
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
            Text(
              'Select 2-3 items to check compatibility',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSelectedItems(),
            const SizedBox(height: 16),
            _buildItemSelector(),
            if (_selectedItems.length >= 2) ...[
              const SizedBox(height: 20),
              _buildCompatibilityResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedItems() {
    if (_selectedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.add_shopping_cart, size: 48, color: AppTheme.textLight),
              const SizedBox(height: 12),
              Text(
                'Tap items below to select',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Items (${_selectedItems.length}/3)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              if (index < _selectedItems.length) {
                return _buildSelectedCard(_selectedItems[index]);
              }
              return _buildEmptySlot(index);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCard(ClothingItem item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedItems.remove(item);
          if (_selectedItems.length < 2) {
            _compatibilityRating = null;
            _suggestion = null;
          } else {
            _calculateCompatibility();
          }
        });
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.getColorFromName(item.primaryColor),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getCategoryIcon(item.category),
              color: AppTheme.getColorFromName(item.primaryColor),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Icon(Icons.close, size: 14, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot(int index) {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add,
            size: 24,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 4),
          Text(
            'Slot ${index + 1}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSelector() {
    final wardrobe = _storage.getWardrobe();
    final selectedIds = _selectedItems.map((i) => i.id).toSet();
    final available = wardrobe.where((item) => !selectedIds.contains(item.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Items',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        available.isEmpty
            ? Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.cardDecoration,
                child: Center(
                  child: Text(
                    'All items selected',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                  ),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: available.map((item) {
                  return GestureDetector(
                    onTap: _selectedItems.length < 3
                        ? () {
                            setState(() {
                              _selectedItems.add(item);
                              if (_selectedItems.length < 2) {
                                _compatibilityRating = null;
                                _suggestion = null;
                              } else {
                                _calculateCompatibility();
                              }
                            });
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedItems.length >= 3
                            ? AppTheme.dividerColor.withOpacity(0.3)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedItems.length >= 3
                              ? AppTheme.dividerColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.getColorFromName(item.primaryColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _selectedItems.length >= 3
                                  ? AppTheme.textLight
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildCompatibilityResult() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Compatibility Rating',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _compatibilityRating!,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _suggestion!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _calculateCompatibility() {
    if (_selectedItems.length < 2) return;

    int score = 0;
    final colors = _selectedItems.map((i) => i.primaryColor.toLowerCase()).toList();
    final categories = _selectedItems.map((i) => i.category).toSet();
    final occasions = _selectedItems.expand((i) => i.occasions).toSet();

    if (categories.length >= 2) score += 25;
    if (occasions.length >= 2) score += 15;

    final colorMatch = _checkColorCompatibility(colors);
    score += colorMatch;

    if (categories.contains(ClothingCategory.tops) &&
        categories.contains(ClothingCategory.bottoms)) {
      score += 20;
    }
    if (categories.contains(ClothingCategory.footwear)) {
      score += 10;
    }

    score = score.clamp(0, 100);

    String rating;
    String suggestion;

    if (score >= 80) {
      rating = 'Excellent';
      suggestion = 'Great combination! These pieces work perfectly together.';
    } else if (score >= 60) {
      rating = 'Good';
      suggestion = 'Solid pairing. Consider adding an accessory to complete the look.';
    } else if (score >= 40) {
      rating = 'Fair';
      suggestion = 'These can work with some styling adjustments. Try adding a neutral piece.';
    } else {
      rating = 'Poor';
      suggestion = 'These pieces clash. Try swapping one item for a more complementary piece.';
    }

    _compatibilityRating = rating;
    _suggestion = suggestion;
  }

  int _checkColorCompatibility(List<String> colors) {
    final complementaryPairs = {
      'blue': ['orange', 'brown', 'white'],
      'red': ['black', 'white', 'navy'],
      'green': ['brown', 'white', 'black'],
      'black': ['white', 'red', 'blue'],
      'white': ['black', 'blue', 'red', 'navy'],
      'navy': ['white', 'beige', 'pink'],
      'brown': ['blue', 'green', 'cream'],
      'grey': ['pink', 'white', 'black'],
      'pink': ['grey', 'navy', 'white'],
      'beige': ['navy', 'brown', 'white'],
    };

    int matches = 0;
    for (int i = 0; i < colors.length; i++) {
      for (int j = i + 1; j < colors.length; j++) {
        final complements = complementaryPairs[colors[i]] ?? [];
        if (complements.contains(colors[j])) {
          matches += 15;
        }
      }
    }

    return matches.clamp(0, 30);
  }

  IconData _getCategoryIcon(ClothingCategory category) {
    switch (category) {
      case ClothingCategory.tops:
        return Icons.checkroom;
      case ClothingCategory.bottoms:
        return Icons.water_drop_outlined;
      case ClothingCategory.outerwear:
        return Icons.ac_unit;
      case ClothingCategory.dresses:
        return Icons.woman;
      case ClothingCategory.footwear:
        return Icons.snowshoeing;
      case ClothingCategory.accessories:
        return Icons.watch;
      case ClothingCategory.activewear:
        return Icons.fitness_center;
      case ClothingCategory.formal:
        return Icons.business_center;
    }
  }
}
