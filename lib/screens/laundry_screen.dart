import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clothing_item.dart';
import '../models/laundry_item.dart';
import '../services/storage_service.dart';
import '../services/features_service.dart';
import '../theme/app_theme.dart';

class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> {
  final FeaturesService _features = FeaturesService();
  final StorageService _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Laundry Tracker',
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
    );
  }

  Widget _buildBody() {
    final laundryItems = _features.getAllLaundryItems();
    final needingWash = _features.getItemsNeedingWash();

    if (laundryItems.isEmpty) {
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
                Icons.local_laundry_service_outlined,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No laundry items tracked',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to track their wash status',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(laundryItems, needingWash),
          const SizedBox(height: 20),
          if (needingWash.isNotEmpty) ...[
            Text(
              'Needs Washing',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 12),
            ...needingWash.map((item) => _buildLaundryCard(item, urgent: true)),
            const SizedBox(height: 20),
          ],
          Text(
            'All Items',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...laundryItems.map((item) => _buildLaundryCard(item)),
          const SizedBox(height: 20),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<LaundryItem> all, List<LaundryItem> needingWash) {
    final fresh = all.where((l) => l.daysSinceLastWash < 3).length;
    final soon = all.where((l) => l.daysSinceLastWash >= 3 && l.daysSinceLastWash <= 5).length;
    final dirty = needingWash.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Fresh', '$fresh', Icons.check_circle, Colors.white),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildSummaryItem('Soon', '$soon', Icons.schedule, Colors.white),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildSummaryItem('Dirty', '$dirty', Icons.warning, Colors.white),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLaundryCard(LaundryItem laundry, {bool urgent = false}) {
    final clothingItem = _storage.getClothingItem(laundry.clothingItemId);
    final daysSince = laundry.daysSinceLastWash;

    Color statusColor;
    String statusLabel;
    if (daysSince <= 3) {
      statusColor = AppTheme.successColor;
      statusLabel = 'Fresh';
    } else if (daysSince <= 5) {
      statusColor = AppTheme.warningColor;
      statusLabel = 'Use Soon';
    } else {
      statusColor = AppTheme.errorColor;
      statusLabel = 'Needs Wash';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: urgent ? Border.all(color: AppTheme.errorColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: urgent
                ? AppTheme.errorColor.withOpacity(0.15)
                : AppTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              _getCategoryIcon(clothingItem?.category),
              color: statusColor,
              size: 24,
            ),
          ),
        ),
        title: Text(
          clothingItem?.name ?? 'Unknown Item',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${clothingItem?.category.name ?? ''} - ${clothingItem?.primaryColor ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  '$daysSince days ago',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'washed',
              child: Row(
                children: [
                  const Icon(Icons.check, color: AppTheme.successColor, size: 18),
                  const SizedBox(width: 8),
                  Text('Mark as Washed', style: GoogleFonts.poppins()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 8),
                  Text('Remove', style: GoogleFonts.poppins(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'washed') {
              _features.markAsWashed(laundry.clothingItemId);
              setState(() {});
            } else if (value == 'delete') {
              _features.deleteLaundryItem(laundry.clothingItemId);
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final wardrobe = _storage.getWardrobe();
    final trackedIds = _features.getAllLaundryItems().map((l) => l.clothingItemId).toSet();
    final untracked = wardrobe.where((item) => !trackedIds.contains(item.id)).toList();

    if (untracked.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddLaundryDialog(untracked),
        icon: const Icon(Icons.add),
        label: Text('Add Item to Track', style: GoogleFonts.poppins()),
      ),
    );
  }

  void _showAddLaundryDialog(List<ClothingItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add to Laundry Tracker',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.getColorFromName(item.primaryColor)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(item.category),
                              color: AppTheme.getColorFromName(item.primaryColor),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            item.category.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          onTap: () {
                            _features.addLaundryItem(LaundryItem(
                              clothingItemId: item.id,
                              lastWashed: DateTime.now(),
                              washCount: 0,
                              nextWashDate: DateTime.now().add(const Duration(days: 7)),
                            ));
                            setState(() {});
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(ClothingCategory? category) {
    if (category == null) return Icons.checkroom;
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
