import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/clothing_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class WeeklyPlannerScreen extends StatefulWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  State<WeeklyPlannerScreen> createState() => _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends State<WeeklyPlannerScreen> {
  final StorageService _storage = StorageService();
  List<_DayPlan> _weekPlan = [];
  List<ClothingItem> _wardrobe = [];
  static const String _storageKey = 'weekly_planner_data';

  @override
  void initState() {
    super.initState();
    _wardrobe = _storage.getWardrobe();
    _loadWeekPlan();
  }

  DateTime _getDateForDay(int index) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: index));
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _loadWeekPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> json = jsonDecode(data);
      setState(() {
        _weekPlan = json.map((e) => _DayPlan.fromJson(e)).toList();
      });
    } else {
      setState(() {
        _weekPlan = List.generate(7, (index) => _DayPlan(
          dayName: _getDayName(index),
          date: _getDateForDay(index),
          morningTopId: null,
          morningBottomId: null,
          morningOuterwearId: null,
          eveningTopId: null,
          eveningBottomId: null,
          eveningOuterwearId: null,
          status: _DayStatus.unplanned,
        ));
      });
    }
  }

  String _getDayName(int index) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[index];
  }

  Future<void> _saveWeekPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _weekPlan.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(json));
  }

  int get _plannedDays => _weekPlan.where((d) => d.status != _DayStatus.unplanned).length;
  int get _completedDays => _weekPlan.where((d) => d.status == _DayStatus.done).length;
  double get _completionRate => _plannedDays > 0 ? _completedDays / _plannedDays : 0.0;

  void _openOutfitPicker(int dayIndex, bool isEvening) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OutfitPickerSheet(
        wardrobe: _wardrobe,
        dayPlan: _weekPlan[dayIndex],
        isEvening: isEvening,
        onConfirm: (morningTop, morningBottom, morningOuterwear, eveningTop, eveningBottom, eveningOuterwear) {
          setState(() {
            final day = _weekPlan[dayIndex];
            day.morningTopId = morningTop;
            day.morningBottomId = morningBottom;
            day.morningOuterwearId = morningOuterwear;
            day.eveningTopId = eveningTop;
            day.eveningBottomId = eveningBottom;
            day.eveningOuterwearId = eveningOuterwear;
            day.status = _hasAnyOutfit(day) ? _DayStatus.planned : _DayStatus.unplanned;
          });
          _saveWeekPlan();
        },
      ),
    );
  }

  bool _hasAnyOutfit(_DayPlan day) {
    return day.morningTopId != null || day.morningBottomId != null ||
        day.eveningTopId != null || day.eveningBottomId != null;
  }

  void _autoPlan() {
    final random = Random();
    final tops = _wardrobe.where((i) => i.category == ClothingCategory.tops).toList();
    final bottoms = _wardrobe.where((i) => i.category == ClothingCategory.bottoms).toList();
    final outerwear = _wardrobe.where((i) => i.category == ClothingCategory.outerwear).toList();

    if (tops.isEmpty || bottoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Need at least tops and bottoms in wardrobe for auto-plan', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    for (int i = 0; i < 7; i++) {
      final day = _weekPlan[i];
      if (day.status == _DayStatus.unplanned) {
        day.morningTopId = tops[random.nextInt(tops.length)].id;
        day.morningBottomId = bottoms[random.nextInt(bottoms.length)].id;
        if (outerwear.isNotEmpty && random.nextBool()) {
          day.morningOuterwearId = outerwear[random.nextInt(outerwear.length)].id;
        }
        if (random.nextBool()) {
          day.eveningTopId = tops[random.nextInt(tops.length)].id;
          day.eveningBottomId = bottoms[random.nextInt(bottoms.length)].id;
        }
        day.status = _DayStatus.planned;
      }
    }

    setState(() {});
    _saveWeekPlan();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Outfits auto-planned for unplanned days!', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _clearAllPlans() {
    setState(() {
      for (final day in _weekPlan) {
        day.morningTopId = null;
        day.morningBottomId = null;
        day.morningOuterwearId = null;
        day.eveningTopId = null;
        day.eveningBottomId = null;
        day.eveningOuterwearId = null;
        day.status = _DayStatus.unplanned;
      }
    });
    _saveWeekPlan();
  }

  void _toggleDone(int index) {
    setState(() {
      final day = _weekPlan[index];
      if (day.status == _DayStatus.planned) {
        day.status = _DayStatus.done;
      } else if (day.status == _DayStatus.done) {
        day.status = _DayStatus.planned;
      }
    });
    _saveWeekPlan();
  }

  void _removeMorningOutfit(int index) {
    setState(() {
      final day = _weekPlan[index];
      day.morningTopId = null;
      day.morningBottomId = null;
      day.morningOuterwearId = null;
      if (!_hasAnyOutfit(day)) {
        day.status = _DayStatus.unplanned;
      } else if (day.status == _DayStatus.done) {
        day.status = _DayStatus.planned;
      }
    });
    _saveWeekPlan();
  }

  void _removeEveningOutfit(int index) {
    setState(() {
      final day = _weekPlan[index];
      day.eveningTopId = null;
      day.eveningBottomId = null;
      day.eveningOuterwearId = null;
      if (!_hasAnyOutfit(day)) {
        day.status = _DayStatus.unplanned;
      } else if (day.status == _DayStatus.done) {
        day.status = _DayStatus.planned;
      }
    });
    _saveWeekPlan();
  }

  ClothingItem? _getItemById(String? id) {
    if (id == null) return null;
    try {
      return _wardrobe.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Weekly Planner',
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
            icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.errorColor),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Clear All Plans?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  content: Text('This will remove all planned outfits.', style: GoogleFonts.poppins()),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins())),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearAllPlans();
                      },
                      child: Text('Clear', style: GoogleFonts.poppins(color: AppTheme.errorColor)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _wardrobe.isEmpty ? _buildEmptyState() : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekOverview(),
            const SizedBox(height: 12),
            _buildAutoPlanButton(),
            const SizedBox(height: 16),
            ...List.generate(7, (index) => _buildDayCard(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
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
                child: const Icon(Icons.date_range, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Plan your outfits for the week',
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
              _buildOverviewStat(Icons.check_circle_outline, '$_plannedDays/7', 'Planned'),
              const SizedBox(width: 12),
              _buildOverviewStat(Icons.task_alt, '${(_completionRate * 100).round()}%', 'Done'),
              const SizedBox(width: 12),
              _buildOverviewStat(Icons.pending_outlined, '${7 - _plannedDays}', 'Remaining'),
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

  Widget _buildAutoPlanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _autoPlan,
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: Text(
          'Auto-Plan Unplanned Days',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDayCard(int index) {
    final day = _weekPlan[index];
    final isToday = DateTime.now().year == day.date.year &&
        DateTime.now().month == day.date.month &&
        DateTime.now().day == day.date.day;

    return Dismissible(
      key: Key('day_$index'),
      direction: _hasAnyOutfit(day) ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _removeMorningOutfit(index);
          _removeEveningOutfit(index);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Outfits removed from ${day.dayName}', style: GoogleFonts.poppins()),
              action: SnackBarAction(
                label: 'Undo',
                textColor: Colors.white,
                onPressed: () => _loadWeekPlan(),
              ),
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isToday ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: isToday
                  ? AppTheme.primaryColor.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'TODAY',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  Text(
                    day.dayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(day.date),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(day.status),
                  const SizedBox(width: 8),
                  if (day.status != _DayStatus.unplanned)
                    GestureDetector(
                      onTap: () => _toggleDone(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: day.status == _DayStatus.done
                              ? AppTheme.successColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          day.status == _DayStatus.done ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: day.status == _DayStatus.done ? AppTheme.successColor : AppTheme.textLight,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOutfitSection(
                    label: 'Morning',
                    icon: Icons.wb_sunny_outlined,
                    topId: day.morningTopId,
                    bottomId: day.morningBottomId,
                    outerwearId: day.morningOuterwearId,
                    onTap: () => _openOutfitPicker(index, false),
                    onRemove: _hasAnyOutfit(day) ? () => _removeMorningOutfit(index) : null,
                  ),
                  if (day.eveningTopId != null || day.eveningBottomId != null) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1, indent: 0, endIndent: 0),
                    const SizedBox(height: 8),
                    _buildOutfitSection(
                      label: 'Evening',
                      icon: Icons.nights_stay_outlined,
                      topId: day.eveningTopId,
                      bottomId: day.eveningBottomId,
                      outerwearId: day.eveningOuterwearId,
                      onTap: () => _openOutfitPicker(index, true),
                      onRemove: _hasAnyOutfit(day) ? () => _removeEveningOutfit(index) : null,
                    ),
                  ],
                  if (day.morningTopId == null && day.morningBottomId == null &&
                      day.eveningTopId == null && day.eveningBottomId == null)
                    GestureDetector(
                      onTap: () => _openOutfitPicker(index, false),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add_circle_outline, color: AppTheme.textLight, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to plan outfit',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitSection({
    required String label,
    required IconData icon,
    String? topId,
    String? bottomId,
    String? outerwearId,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    final top = _getItemById(topId);
    final bottom = _getItemById(bottomId);
    final outer = _getItemById(outerwearId);
    final hasItems = top != null || bottom != null || outer != null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              if (hasItems && onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.close, size: 16, color: AppTheme.textLight),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasItems)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (top != null) _buildItemChip(top, 'Top'),
                if (bottom != null) _buildItemChip(bottom, 'Bottom'),
                if (outer != null) _buildItemChip(outer, 'Outer'),
              ],
            )
          else
            Text(
              'Not planned',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight),
            ),
        ],
      ),
    );
  }

  Widget _buildItemChip(ClothingItem item, String role) {
    final imageFile = File(item.imagePath);
    return Container(
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
              width: 28,
              height: 28,
              child: imageFile.existsSync()
                  ? Image.file(imageFile, fit: BoxFit.cover)
                  : Container(
                      color: AppTheme.dividerColor,
                      child: Icon(_getCategoryIcon(item.category), size: 14, color: AppTheme.textLight),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                role,
                style: GoogleFonts.poppins(fontSize: 8, color: AppTheme.textLight),
              ),
              Text(
                item.name,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(_DayStatus status) {
    Color color;
    String text;
    switch (status) {
      case _DayStatus.planned:
        color = AppTheme.primaryColor;
        text = 'Planned';
        break;
      case _DayStatus.done:
        color = AppTheme.successColor;
        text = 'Done';
        break;
      case _DayStatus.unplanned:
        color = AppTheme.textLight;
        text = 'Unplanned';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
            Icon(Icons.checkroom_outlined, color: AppTheme.textLight, size: 64),
            const SizedBox(height: 16),
            Text(
              'No wardrobe items found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some clothes to your wardrobe first\nto plan weekly outfits',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
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
  final _DayPlan dayPlan;
  final bool isEvening;
  final Function(String? morningTop, String? morningBottom, String? morningOuterwear,
      String? eveningTop, String? eveningBottom, String? eveningOuterwear) onConfirm;

  const _OutfitPickerSheet({
    required this.wardrobe,
    required this.dayPlan,
    required this.isEvening,
    required this.onConfirm,
  });

  @override
  State<_OutfitPickerSheet> createState() => _OutfitPickerSheetState();
}

class _OutfitPickerSheetState extends State<_OutfitPickerSheet> {
  String? _selectedTopId;
  String? _selectedBottomId;
  String? _selectedOuterwearId;
  ClothingCategory? _activeFilter;

  @override
  void initState() {
    super.initState();
    if (widget.isEvening) {
      _selectedTopId = widget.dayPlan.eveningTopId;
      _selectedBottomId = widget.dayPlan.eveningBottomId;
      _selectedOuterwearId = widget.dayPlan.eveningOuterwearId;
    } else {
      _selectedTopId = widget.dayPlan.morningTopId;
      _selectedBottomId = widget.dayPlan.morningBottomId;
      _selectedOuterwearId = widget.dayPlan.morningOuterwearId;
    }
  }

  List<ClothingItem> get _filteredItems {
    if (_activeFilter == null) return widget.wardrobe;
    return widget.wardrobe.where((i) => i.category == _activeFilter).toList();
  }

  void _selectItem(ClothingItem item) {
    setState(() {
      switch (item.category) {
        case ClothingCategory.tops:
          _selectedTopId = (_selectedTopId == item.id) ? null : item.id;
          break;
        case ClothingCategory.bottoms:
          _selectedBottomId = (_selectedBottomId == item.id) ? null : item.id;
          break;
        case ClothingCategory.outerwear:
          _selectedOuterwearId = (_selectedOuterwearId == item.id) ? null : item.id;
          break;
        default:
          break;
      }
    });
  }

  bool _isSelected(ClothingItem item) {
    return _selectedTopId == item.id ||
        _selectedBottomId == item.id ||
        _selectedOuterwearId == item.id;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
                    Text(
                      '${widget.isEvening ? "Evening" : "Morning"} Outfit',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        widget.onConfirm(
                          widget.isEvening ? widget.dayPlan.morningTopId : _selectedTopId,
                          widget.isEvening ? widget.dayPlan.morningBottomId : _selectedBottomId,
                          widget.isEvening ? widget.dayPlan.morningOuterwearId : _selectedOuterwearId,
                          widget.isEvening ? _selectedTopId : widget.dayPlan.eveningTopId,
                          widget.isEvening ? _selectedBottomId : widget.dayPlan.eveningBottomId,
                          widget.isEvening ? _selectedOuterwearId : widget.dayPlan.eveningOuterwearId,
                        );
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
                          final selected = _isSelected(item);
                          final imageFile = File(item.imagePath);
                          return GestureDetector(
                            onTap: () => _selectItem(item),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
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

enum _DayStatus { planned, unplanned, done }

class _DayPlan {
  String dayName;
  DateTime date;
  String? morningTopId;
  String? morningBottomId;
  String? morningOuterwearId;
  String? eveningTopId;
  String? eveningBottomId;
  String? eveningOuterwearId;
  _DayStatus status;

  _DayPlan({
    required this.dayName,
    required this.date,
    this.morningTopId,
    this.morningBottomId,
    this.morningOuterwearId,
    this.eveningTopId,
    this.eveningBottomId,
    this.eveningOuterwearId,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'dayName': dayName,
    'date': date.toIso8601String(),
    'morningTopId': morningTopId,
    'morningBottomId': morningBottomId,
    'morningOuterwearId': morningOuterwearId,
    'eveningTopId': eveningTopId,
    'eveningBottomId': eveningBottomId,
    'eveningOuterwearId': eveningOuterwearId,
    'status': status.index,
  };

  factory _DayPlan.fromJson(Map<String, dynamic> json) => _DayPlan(
    dayName: json['dayName'],
    date: DateTime.parse(json['date']),
    morningTopId: json['morningTopId'],
    morningBottomId: json['morningBottomId'],
    morningOuterwearId: json['morningOuterwearId'],
    eveningTopId: json['eveningTopId'],
    eveningBottomId: json['eveningBottomId'],
    eveningOuterwearId: json['eveningOuterwearId'],
    status: _DayStatus.values[json['status'] ?? 1],
  );
}
