import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clothing_item.dart';
import '../models/outfit_calendar.dart';
import '../services/storage_service.dart';
import '../services/features_service.dart';
import '../theme/app_theme.dart';

class OutfitCalendarScreen extends StatefulWidget {
  const OutfitCalendarScreen({super.key});

  @override
  State<OutfitCalendarScreen> createState() => _OutfitCalendarScreenState();
}

class _OutfitCalendarScreenState extends State<OutfitCalendarScreen> {
  final FeaturesService _features = FeaturesService();
  final StorageService _storage = StorageService();
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Outfit Calendar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildWeekNavigator(),
          Expanded(child: _buildCalendarBody()),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final startStr = '${_weekStart.day}/${_weekStart.month}';
    final endStr = '${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
            },
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
          ),
          Text(
            '$startStr - $endStr',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
            },
            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBody() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final date = _weekStart.add(Duration(days: index));
        final entry = _features.getCalendarEntry(date);
        final isToday = _isSameDay(date, DateTime.now());

        return _buildDayCard(date, entry, isToday);
      },
    );
  }

  Widget _buildDayCard(DateTime date, OutfitCalendar? entry, bool isToday) {
    final dayName = _getDayName(date.weekday);
    final hasItems = entry != null && entry.itemIds.isNotEmpty;

    return GestureDetector(
      onTap: () => _showDayOptions(date, entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isToday
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    dayName.substring(0, 3),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: hasItems
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              entry!.isCompleted ? Icons.check_circle : Icons.schedule,
                              size: 16,
                              color: entry.isCompleted
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.isCompleted ? 'Completed' : 'Planned',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: entry.isCompleted
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.itemIds.length} items',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (entry.occasion != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.occasion!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      'No outfit planned',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
            ),
            Icon(
              hasItems ? Icons.edit : Icons.add_circle_outline,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showDayOptions(DateTime date, OutfitCalendar? entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
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
                '${_getDayName(date.weekday)}, ${date.day}/${date.month}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.checkroom, color: AppTheme.primaryColor),
                title: Text(
                  entry != null ? 'Edit Outfit' : 'Plan Outfit',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showItemSelector(date, entry);
                },
              ),
              if (entry != null && entry.itemIds.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.check_circle, color: AppTheme.successColor),
                  title: Text(
                    entry.isCompleted ? 'Mark as Incomplete' : 'Mark as Completed',
                    style: GoogleFonts.poppins(),
                  ),
                  onTap: () {
                    final updated = OutfitCalendar(
                      id: entry.id,
                      date: entry.date,
                      itemIds: entry.itemIds,
                      notes: entry.notes,
                      isCompleted: !entry.isCompleted,
                      occasion: entry.occasion,
                    );
                    _features.updateCalendarEntry(updated);
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                  title: Text(
                    'Remove Plan',
                    style: GoogleFonts.poppins(color: AppTheme.errorColor),
                  ),
                  onTap: () {
                    _features.deleteCalendarEntry(date);
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showItemSelector(DateTime date, OutfitCalendar? existing) {
    final wardrobe = _storage.getWardrobe();
    final selectedIds = Set<String>.from(existing?.itemIds ?? []);
    final occasionController = TextEditingController(text: existing?.occasion ?? '');

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
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
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
                        'Select Items',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: occasionController,
                        decoration: InputDecoration(
                          hintText: 'Occasion (optional)',
                          hintStyle: GoogleFonts.poppins(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: wardrobe.isEmpty
                            ? Center(
                                child: Text(
                                  'No items in wardrobe',
                                  style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                                ),
                              )
                            : ListView.builder(
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
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item.category.name} - ${item.primaryColor}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    secondary: Container(
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
                                  final entry = OutfitCalendar(
                                    id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                    date: date,
                                    itemIds: selectedIds.toList(),
                                    occasion: occasionController.text.isNotEmpty
                                        ? occasionController.text
                                        : null,
                                    isCompleted: existing?.isCompleted ?? false,
                                  );
                                  _features.addCalendarEntry(entry);
                                  setState(() {});
                                  Navigator.pop(context);
                                }
                              : null,
                          child: Text(
                            'Save Plan',
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
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
