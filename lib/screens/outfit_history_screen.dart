import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/clothing_item.dart';
import '../models/outfit_history.dart';
import '../services/storage_service.dart';
import '../services/features_service.dart';
import '../theme/app_theme.dart';

class OutfitHistoryScreen extends StatefulWidget {
  const OutfitHistoryScreen({super.key});

  @override
  State<OutfitHistoryScreen> createState() => _OutfitHistoryScreenState();
}

class _OutfitHistoryScreenState extends State<OutfitHistoryScreen> {
  final FeaturesService _features = FeaturesService();
  final StorageService _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Outfit History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    final history = _features.getAllHistory();

    if (history.isEmpty) {
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
                Icons.history,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No outfit history',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your outfits',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) => _buildHistoryCard(history[index]),
    );
  }

  Widget _buildHistoryCard(OutfitHistory entry) {
    final items = entry.itemIds
        .map((id) => _storage.getClothingItem(id))
        .where((item) => item != null)
        .toList();

    final ratingColor = entry.rating >= 4
        ? AppTheme.successColor
        : entry.rating >= 3
            ? AppTheme.primaryColor
            : entry.rating >= 2
                ? AppTheme.warningColor
                : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (entry.occasion != null)
                      Text(
                        entry.occasion!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    _buildRatingBadge(entry.rating, ratingColor),
                    const SizedBox(width: 8),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Rating', style: GoogleFonts.poppins()),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: GoogleFonts.poppins(color: AppTheme.errorColor)),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditRatingDialog(entry);
                        } else if (value == 'delete') {
                          _features.deleteHistoryEntry(entry.id);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Items no longer in wardrobe',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index]!;
                      return Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCategoryIcon(item.category),
                              color: AppTheme.getColorFromName(item.primaryColor),
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (entry.notes != null && entry.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                entry.notes!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(int rating, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (i) => Icon(
                i < rating ? Icons.star : Icons.star_border,
                size: 14,
                color: color,
              )),
          const SizedBox(width: 4),
          Text(
            _getRatingLabel(rating),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  void _showAddEntryDialog() {
    final wardrobe = _storage.getWardrobe();
    final selectedIds = <String>{};
    final occasionController = TextEditingController();
    final notesController = TextEditingController();
    int rating = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Outfit',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: occasionController,
                        decoration: InputDecoration(
                          hintText: 'Occasion (e.g., Work, Casual)',
                          hintStyle: GoogleFonts.poppins(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rate this outfit',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setModalState(() => rating = index + 1),
                            child: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              size: 36,
                              color: AppTheme.warningColor,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          hintText: 'Notes (optional)',
                          hintStyle: GoogleFonts.poppins(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select items worn',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: wardrobe.length,
                          itemBuilder: (context, index) {
                            final item = wardrobe[index];
                            final isSelected = selectedIds.contains(item.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setModalState(() {
                                  if (value == true) {
                                    selectedIds.add(item.id);
                                  } else {
                                    selectedIds.remove(item.id);
                                  }
                                });
                              },
                              title: Text(
                                item.name,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${item.category.name} - ${item.primaryColor}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              activeColor: AppTheme.primaryColor,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedIds.isNotEmpty
                              ? () {
                                  final entry = OutfitHistory(
                                    id: const Uuid().v4(),
                                    itemIds: selectedIds.toList(),
                                    date: DateTime.now(),
                                    rating: rating,
                                    occasion: occasionController.text.isNotEmpty
                                        ? occasionController.text
                                        : null,
                                    notes: notesController.text.isNotEmpty
                                        ? notesController.text
                                        : null,
                                  );
                                  _features.addHistoryEntry(entry);
                                  setState(() {});
                                  Navigator.pop(context);
                                }
                              : null,
                          child: Text(
                            'Save Entry',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditRatingDialog(OutfitHistory entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Rating',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            final updated = OutfitHistory(
                              id: entry.id,
                              itemIds: entry.itemIds,
                              date: entry.date,
                              rating: index + 1,
                              occasion: entry.occasion,
                              notes: entry.notes,
                            );
                            _features.updateHistoryEntry(updated);
                            setState(() {});
                            setModalState(() {});
                            Navigator.pop(context);
                          },
                          child: Icon(
                            index < entry.rating ? Icons.star : Icons.star_border,
                            size: 48,
                            color: AppTheme.warningColor,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
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
