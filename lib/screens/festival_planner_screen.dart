import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class FestivalPlannerScreen extends StatefulWidget {
  const FestivalPlannerScreen({super.key});

  @override
  State<FestivalPlannerScreen> createState() => _FestivalPlannerScreenState();
}

class _FestivalPlannerScreenState extends State<FestivalPlannerScreen> {
  final StorageService _storage = StorageService();
  List<ClothingItem> _wardrobe = [];
  List<_FestivalEvent> _festivals = [];
  Map<String, List<String>> _plannedOutfits = {};
  static const String _festivalsKey = 'festival_planner_festivals';
  static const String _outfitsKey = 'festival_planner_outfits';

  final List<_FestivalEvent> _defaultFestivals = [
    _FestivalEvent(
      name: 'New Year',
      date: DateTime(2026, 1, 1),
      colorTheme: ['Gold', 'Silver', 'Black'],
      icon: Icons.celebration,
      themeColors: [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFF1A1A2E)],
    ),
    _FestivalEvent(
      name: "Valentine's Day",
      date: DateTime(2026, 2, 14),
      colorTheme: ['Red', 'Pink', 'White'],
      icon: Icons.favorite,
      themeColors: [Color(0xFFFF0000), Color(0xFFE91E63), Color(0xFFFFFFFF)],
    ),
    _FestivalEvent(
      name: 'Holi',
      date: DateTime(2026, 3, 14),
      colorTheme: ['Pink', 'Yellow', 'Green', 'Purple'],
      icon: Icons.palette,
      themeColors: [Color(0xFFE91E63), Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF9C27B0)],
    ),
    _FestivalEvent(
      name: 'Eid ul Fitr',
      date: DateTime(2026, 3, 30),
      colorTheme: ['Green', 'White', 'Gold'],
      icon: Icons.star,
      themeColors: [Color(0xFF228B22), Color(0xFFFFFFFF), Color(0xFFFFD700)],
    ),
    _FestivalEvent(
      name: 'Eid ul Adha',
      date: DateTime(2026, 6, 6),
      colorTheme: ['Green', 'White', 'Gold'],
      icon: Icons.star,
      themeColors: [Color(0xFF228B22), Color(0xFFFFFFFF), Color(0xFFFFD700)],
    ),
    _FestivalEvent(
      name: 'Independence Day',
      date: DateTime(2026, 8, 14),
      colorTheme: ['Green', 'White', 'Saffron'],
      icon: Icons.flag,
      themeColors: [Color(0xFF138808), Color(0xFFFFFFFF), Color(0xFFFF9933)],
    ),
    _FestivalEvent(
      name: 'Back to School',
      date: DateTime(2026, 9, 1),
      colorTheme: ['Navy', 'Grey', 'White'],
      icon: Icons.school,
      themeColors: [Color(0xFF1E3A5F), Color(0xFF9E9E9E), Color(0xFFFFFFFF)],
    ),
    _FestivalEvent(
      name: 'Diwali',
      date: DateTime(2026, 10, 20),
      colorTheme: ['Red', 'Gold', 'Orange'],
      icon: Icons.lightbulb,
      themeColors: [Color(0xFFFF0000), Color(0xFFFFD700), Color(0xFFFF8C00)],
    ),
    _FestivalEvent(
      name: 'Wedding Season',
      date: DateTime(2026, 11, 1),
      colorTheme: ['Maroon', 'Gold', 'Royal Blue'],
      icon: Icons.diamond,
      themeColors: [Color(0xFF800000), Color(0xFFFFD700), Color(0xFF4169E1)],
    ),
    _FestivalEvent(
      name: 'Christmas',
      date: DateTime(2026, 12, 25),
      colorTheme: ['Red', 'Green', 'White', 'Gold'],
      icon: Icons.card_giftcard,
      themeColors: [Color(0xFFFF0000), Color(0xFF228B22), Color(0xFFFFFFFF), Color(0xFFFFD700)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _wardrobe = _storage.getWardrobe();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final festivalsData = prefs.getString(_festivalsKey);
    if (festivalsData != null) {
      final List<dynamic> json = jsonDecode(festivalsData);
      setState(() {
        _festivals = json.map((e) => _FestivalEvent.fromJson(e)).toList();
      });
    } else {
      setState(() {
        _festivals = List.from(_defaultFestivals);
      });
      _saveFestivals();
    }

    final outfitsData = prefs.getString(_outfitsKey);
    if (outfitsData != null) {
      final Map<String, dynamic> json = jsonDecode(outfitsData);
      setState(() {
        _plannedOutfits = json.map((k, v) => MapEntry(k, List<String>.from(v)));
      });
    }
  }

  Future<void> _saveFestivals() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _festivals.map((e) => e.toJson()).toList();
    await prefs.setString(_festivalsKey, jsonEncode(json));
  }

  Future<void> _saveOutfits() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _plannedOutfits.map((k, v) => MapEntry(k, v));
    await prefs.setString(_outfitsKey, jsonEncode(json));
  }

  List<_FestivalEvent> get _upcomingFestivals {
    final now = DateTime.now();
    final upcoming = _festivals.where((f) {
      final festivalDate = DateTime(f.date.year, f.date.month, f.date.day);
      return festivalDate.isAfter(now.subtract(const Duration(days: 1)));
    }).toList();
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming;
  }

  int _daysRemaining(DateTime date) {
    final now = DateTime.now();
    final festivalDate = DateTime(date.year, date.month, date.day);
    return festivalDate.difference(now).inDays;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<ClothingItem> _getMatchingItems(_FestivalEvent festival) {
    return _wardrobe.where((item) {
      return item.colors.any((color) =>
          festival.colorTheme.any((themeColor) =>
              color.toLowerCase() == themeColor.toLowerCase()));
    }).toList();
  }

  void _openOutfitPicker(_FestivalEvent festival) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OutfitPickerSheet(
        wardrobe: _wardrobe,
        festival: festival,
        selectedIds: _plannedOutfits[festival.name] ?? [],
        onConfirm: (selectedIds) {
          setState(() {
            _plannedOutfits[festival.name] = selectedIds;
          });
          _saveOutfits();
        },
      ),
    );
  }

  void _showAddFestivalDialog() {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final colorController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Custom Event', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Event name',
                    hintStyle: GoogleFonts.poppins(),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          _formatDate(selectedDate),
                          style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: InputDecoration(
                    hintText: 'Theme colors (comma separated)',
                    hintStyle: GoogleFonts.poppins(),
                  ),
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final colors = colorController.text
                      .split(',')
                      .map((c) => c.trim())
                      .where((c) => c.isNotEmpty)
                      .toList();
                  if (colors.isEmpty) colors.addAll(['Red', 'Gold', 'White']);

                  final themeColors = colors.map((c) => AppTheme.getColorFromName(c)).toList();

                  setState(() {
                    _festivals.add(_FestivalEvent(
                      name: nameController.text,
                      date: selectedDate,
                      colorTheme: colors,
                      icon: Icons.event,
                      themeColors: themeColors,
                      isCustom: true,
                    ));
                  });
                  _saveFestivals();
                  Navigator.pop(ctx);
                }
              },
              child: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteFestival(int index) {
    final festival = _festivals[index];
    setState(() {
      _festivals.removeAt(index);
      _plannedOutfits.remove(festival.name);
    });
    _saveFestivals();
    _saveOutfits();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcomingFestivals;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Festival Planner',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _showAddFestivalDialog,
          ),
        ],
      ),
      body: upcoming.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(upcoming),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Upcoming Festivals', upcoming.length),
                  const SizedBox(height: 12),
                  ...upcoming.asMap().entries.map((entry) =>
                      _buildFestivalCard(entry.value, _festivals.indexOf(entry.value))),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(List<_FestivalEvent> upcoming) {
    final nextFestival = upcoming.isNotEmpty ? upcoming.first : null;
    final daysLeft = nextFestival != null ? _daysRemaining(nextFestival.date) : 0;

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
                child: const Icon(Icons.celebration, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Festival Outfit Planner',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nextFestival != null
                          ? '${nextFestival.name} in $daysLeft days'
                          : 'Plan outfits for every occasion',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildOverviewStat(Icons.event, '${upcoming.length}', 'Events'),
              const SizedBox(width: 12),
              _buildOverviewStat(
                Icons.checkroom,
                '${_plannedOutfits.values.fold(0, (sum, list) => sum + list.length)}',
                'Items Planned',
              ),
              const SizedBox(width: 12),
              _buildOverviewStat(Icons.color_lens, '${_festivals.length}', 'Total Events'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Icon(Icons.event, color: AppTheme.primaryColor, size: 18),
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
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFestivalCard(_FestivalEvent festival, int index) {
    final daysLeft = _daysRemaining(festival.date);
    final isPast = daysLeft < 0;
    final isToday = daysLeft == 0;
    final matchingItems = _getMatchingItems(festival);
    final plannedIds = _plannedOutfits[festival.name] ?? [];
    final plannedCount = plannedIds.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isPast
                ? Colors.black.withOpacity(0.03)
                : festival.themeColors.first.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: festival.themeColors.first.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(festival.icon, color: festival.themeColors.first, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              festival.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (festival.isCustom)
                            GestureDetector(
                              onTap: () => _deleteFestival(index),
                              child: Icon(Icons.delete_outline, size: 18, color: AppTheme.textLight),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(festival.date),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDaysBadge(daysLeft, isPast, isToday),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Theme:',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                ...festival.themeColors.map((color) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    )),
                const SizedBox(width: 8),
                Text(
                  festival.colorTheme.join(' / '),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (matchingItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checkroom, size: 14, color: AppTheme.successColor),
                      const SizedBox(width: 4),
                      Text(
                        'Matching Items (${matchingItems.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: matchingItems.length,
                      itemBuilder: (ctx, i) => _buildMatchingItemChip(matchingItems[i]),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No matching items in wardrobe',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (plannedCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: AppTheme.successColor),
                    const SizedBox(width: 4),
                    Text(
                      '$plannedCount items planned',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isPast ? null : () => _openOutfitPicker(festival),
                icon: const Icon(Icons.checkroom, size: 18),
                label: Text(
                  plannedCount > 0 ? 'Update Outfit' : 'Plan Outfit',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPast ? AppTheme.textLight : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysBadge(int daysLeft, bool isPast, bool isToday) {
    Color color;
    String text;
    if (isToday) {
      color = AppTheme.successColor;
      text = 'TODAY';
    } else if (isPast) {
      color = AppTheme.textLight;
      text = 'Passed';
    } else if (daysLeft <= 7) {
      color = AppTheme.errorColor;
      text = '$daysLeft days';
    } else if (daysLeft <= 30) {
      color = AppTheme.warningColor;
      text = '$daysLeft days';
    } else {
      color = AppTheme.primaryColor;
      text = '$daysLeft days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildMatchingItemChip(ClothingItem item) {
    final imageFile = File(item.imagePath);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 36,
              height: 36,
              child: imageFile.existsSync()
                  ? Image.file(imageFile, fit: BoxFit.cover)
                  : Container(
                      color: AppTheme.dividerColor,
                      child: Icon(_getCategoryIcon(item.category), size: 16, color: AppTheme.textLight),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.primaryColor,
                style: GoogleFonts.poppins(fontSize: 9, color: AppTheme.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration_outlined, color: AppTheme.textLight, size: 64),
            const SizedBox(height: 16),
            Text(
              'No upcoming festivals',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add custom events or check back later',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddFestivalDialog,
              icon: const Icon(Icons.add, size: 20),
              label: Text('Add Event', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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

class _OutfitPickerSheet extends StatefulWidget {
  final List<ClothingItem> wardrobe;
  final _FestivalEvent festival;
  final List<String> selectedIds;
  final Function(List<String> selectedIds) onConfirm;

  const _OutfitPickerSheet({
    required this.wardrobe,
    required this.festival,
    required this.selectedIds,
    required this.onConfirm,
  });

  @override
  State<_OutfitPickerSheet> createState() => _OutfitPickerSheetState();
}

class _OutfitPickerSheetState extends State<_OutfitPickerSheet> {
  late List<String> _selectedIds;
  ClothingCategory? _activeFilter;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  List<ClothingItem> get _filteredItems {
    if (_activeFilter == null) return widget.wardrobe;
    return widget.wardrobe.where((i) => i.category == _activeFilter).toList();
  }

  bool _isMatching(ClothingItem item) {
    return item.colors.any((color) =>
        widget.festival.colorTheme.any((themeColor) =>
            color.toLowerCase() == themeColor.toLowerCase()));
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan Outfit for ${widget.festival.name}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select items that match the theme colors',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onConfirm(_selectedIds);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('All', null),
                    _buildFilterChip('Tops', ClothingCategory.tops),
                    _buildFilterChip('Bottoms', ClothingCategory.bottoms),
                    _buildFilterChip('Outerwear', ClothingCategory.outerwear),
                    _buildFilterChip('Dresses', ClothingCategory.dresses),
                    _buildFilterChip('Footwear', ClothingCategory.footwear),
                    _buildFilterChip('Accessories', ClothingCategory.accessories),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items in this category',
                          style: GoogleFonts.poppins(color: AppTheme.textLight),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final selected = _selectedIds.contains(item.id);
                          final matching = _isMatching(item);
                          final imageFile = File(item.imagePath);

                          return GestureDetector(
                            onTap: () => _toggleItem(item.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primaryColor.withOpacity(0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.primaryColor
                                      : matching
                                          ? AppTheme.successColor.withOpacity(0.5)
                                          : AppTheme.dividerColor,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: imageFile.existsSync()
                                          ? Image.file(imageFile, fit: BoxFit.cover)
                                          : Container(
                                              color: AppTheme.backgroundColor,
                                              child: Icon(
                                                _getCategoryIcon(item.category),
                                                color: AppTheme.textLight,
                                                size: 22,
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
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppTheme.getColorFromName(item.primaryColor),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${item.category.name.toUpperCase()} • ${item.primaryColor}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: AppTheme.textLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (matching)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'MATCH',
                                        style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.successColor,
                                        ),
                                      ),
                                    ),
                                  if (selected)
                                    Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 22)
                                  else
                                    Icon(Icons.radio_button_unchecked, color: AppTheme.textLight, size: 22),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, ClothingCategory? category) {
    final isActive = _activeFilter == category;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
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

class _FestivalEvent {
  final String name;
  final DateTime date;
  final List<String> colorTheme;
  final IconData icon;
  final List<Color> themeColors;
  final bool isCustom;

  _FestivalEvent({
    required this.name,
    required this.date,
    required this.colorTheme,
    required this.icon,
    required this.themeColors,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date.toIso8601String(),
    'colorTheme': colorTheme,
    'iconCodePoint': icon.codePoint,
    'iconFontFamily': icon.fontFamily,
    'themeColors': themeColors.map((c) => c.value).toList(),
    'isCustom': isCustom,
  };

  factory _FestivalEvent.fromJson(Map<String, dynamic> json) => _FestivalEvent(
    name: json['name'],
    date: DateTime.parse(json['date']),
    colorTheme: List<String>.from(json['colorTheme']),
    icon: Icons.celebration,
    themeColors: (json['themeColors'] as List).map((c) => Color(c)).toList(),
    isCustom: json['isCustom'] ?? false,
  );
}
