import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/outfit_history.dart';
import '../services/features_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class OutfitTimelineScreen extends StatefulWidget {
  const OutfitTimelineScreen({super.key});

  @override
  State<OutfitTimelineScreen> createState() => _OutfitTimelineScreenState();
}

class _OutfitTimelineScreenState extends State<OutfitTimelineScreen> {
  final FeaturesService _features = FeaturesService();
  final StorageService _storage = StorageService();

  late DateTime _currentWeekStart;
  late DateTime _selectedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentWeekStart = _getWeekStart(now);
    _selectedMonth = DateTime(now.year, now.month);
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<OutfitHistory> _getHistoryForDate(DateTime date) {
    return _features.getAllHistory().where((h) =>
      h.date.year == date.year &&
      h.date.month == date.month &&
      h.date.day == date.day
    ).toList();
  }

  bool _hasOutfitOnDate(DateTime date) {
    return _getHistoryForDate(date).isNotEmpty;
  }

  int _calculateStreak() {
    final allHistory = _features.getAllHistory();
    if (allHistory.isEmpty) return 0;

    final dateSet = <String>{};
    for (final h in allHistory) {
      dateSet.add('${h.date.year}-${h.date.month}-${h.date.day}');
    }

    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (dateSet.contains('${checkDate.year}-${checkDate.month}-${checkDate.day}')) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Map<String, int> _getMonthlySummary(DateTime month) {
    final monthHistory = _features.getHistoryForMonth(month);
    final plannedDays = <String>{};
    final unplannedDays = <String>{};
    final itemCounts = <String, int>{};

    for (final entry in monthHistory) {
      final dateKey = '${entry.date.day}';
      if (entry.occasion != null && entry.occasion!.isNotEmpty) {
        plannedDays.add(dateKey);
      } else {
        unplannedDays.add(dateKey);
      }
      for (final itemId in entry.itemIds) {
        itemCounts[itemId] = (itemCounts[itemId] ?? 0) + 1;
      }
    }

    String mostWorn = 'None';
    int maxCount = 0;
    itemCounts.forEach((itemId, count) {
      if (count > maxCount) {
        maxCount = count;
        final item = _storage.getClothingItem(itemId);
        mostWorn = item?.name ?? 'Unknown';
      }
    });

    return {
      'daysWorn': monthHistory.length,
      'daysPlanned': plannedDays.length,
      'daysUnplanned': unplannedDays.length,
      'maxCount': maxCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Outfit Timeline',
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
            _buildStreakCounter(),
            const SizedBox(height: 16),
            _buildMonthNavigation(),
            const SizedBox(height: 12),
            _buildWeekCalendar(),
            const SizedBox(height: 16),
            _buildMonthlySummary(),
            const SizedBox(height: 16),
            _buildTimelineList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCounter() {
    final streak = _calculateStreak();
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
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak ${streak == 1 ? "day" : "days"} in a row',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'wearing planned outfits',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
              _currentWeekStart = _getWeekStart(firstDay);
            });
          },
          icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
        ),
        Text(
          _getMonthName(_selectedMonth.month),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
              _currentWeekStart = _getWeekStart(firstDay);
            });
          },
          icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildWeekCalendar() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = _currentWeekStart.add(Duration(days: index));
          final hasOutfit = _hasOutfitOnDate(date);
          final isSelected = _selectedDate != null &&
              _selectedDate!.year == date.year &&
              _selectedDate!.month == date.month &&
              _selectedDate!.day == date.day;
          final isToday = DateTime.now().year == date.year &&
              DateTime.now().month == date.month &&
              DateTime.now().day == date.day;
          final isCurrentMonth = date.month == _selectedMonth.month;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              _showDayDetails(date);
            },
            child: Container(
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : isToday
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppTheme.primaryColor : Colors.black).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isCurrentMonth
                              ? AppTheme.textSecondary
                              : AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isCurrentMonth
                              ? AppTheme.textPrimary
                              : AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasOutfit)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlySummary() {
    final summary = _getMonthlySummary(_selectedMonth);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryItem(
                'Days Planned',
                '${summary['daysPlanned']}',
                AppTheme.successColor,
                Icons.event_available,
              ),
              const SizedBox(width: 12),
              _buildSummaryItem(
                'Days Unplanned',
                '${summary['daysUnplanned']}',
                AppTheme.warningColor,
                Icons.event_busy,
              ),
              const SizedBox(width: 12),
              _buildSummaryItem(
                'Most Worn',
                summary['maxCount']! > 0 ? '${summary['maxCount']}x' : '-',
                AppTheme.primaryColor,
                Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineList() {
    final monthHistory = _features.getHistoryForMonth(_selectedMonth);

    if (monthHistory.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No outfit history this month',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...monthHistory.map((entry) => _buildTimelineCard(entry)),
      ],
    );
  }

  Widget _buildTimelineCard(OutfitHistory entry) {
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 100,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: ratingColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getDayName(entry.date.weekday)}, ${entry.date.day} ${_getMonthName(entry.date.month)}',
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
                      _buildRatingStars(entry.rating, ratingColor),
                    ],
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = items[index]!;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                    color: AppTheme.getColorFromName(item?.primaryColor ?? 'grey').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                    item?.name ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(int rating, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: i < rating ? color : AppTheme.textLight,
        );
      }),
    );
  }

  void _showDayDetails(DateTime date) {
    final history = _getHistoryForDate(date);
    if (history.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_getDayName(date.weekday)}, ${date.day} ${_getMonthName(date.month)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: history.length,
                      itemBuilder: (context, index) => _buildDayOutfitCard(history[index]),
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

  Widget _buildDayOutfitCard(OutfitHistory entry) {
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (entry.occasion != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.occasion!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              _buildRatingStars(entry.rating, ratingColor),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.getColorFromName(item?.primaryColor ?? 'grey').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item?.name ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.notes!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }
}
