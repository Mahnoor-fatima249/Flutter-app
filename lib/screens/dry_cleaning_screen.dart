import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/clothing_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class DryCleaningScreen extends StatefulWidget {
  const DryCleaningScreen({super.key});

  @override
  State<DryCleaningScreen> createState() => _DryCleaningScreenState();
}

class _DryCleaningScreenState extends State<DryCleaningScreen> {
  final StorageService _storage = StorageService();
  Map<String, String> _dryCleaningData = {}; // itemId -> ISO date string
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('dry_cleaning_data');
    if (data != null) {
      final decoded = jsonDecode(data);
      _dryCleaningData = Map<String, String>.from(decoded);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dry_cleaning_data', jsonEncode(_dryCleaningData));
  }

  DateTime? _getLastCleanedDate(String itemId) {
    final dateStr = _dryCleaningData[itemId];
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  int _daysSinceLastClean(String itemId) {
    final date = _getLastCleanedDate(itemId);
    if (date == null) return 999;
    return DateTime.now().difference(date).inDays;
  }

  _DryCleanStatus _getStatus(int days) {
    if (days <= 14) return _DryCleanStatus.clean;
    if (days <= 30) return _DryCleanStatus.soon;
    return _DryCleanStatus.overdue;
  }

  Color _getStatusColor(_DryCleanStatus status) {
    switch (status) {
      case _DryCleanStatus.clean:
        return AppTheme.successColor;
      case _DryCleanStatus.soon:
        return AppTheme.warningColor;
      case _DryCleanStatus.overdue:
        return AppTheme.errorColor;
    }
  }

  String _getStatusLabel(_DryCleanStatus status) {
    switch (status) {
      case _DryCleanStatus.clean:
        return 'Recently Cleaned';
      case _DryCleanStatus.soon:
        return 'Schedule Soon';
      case _DryCleanStatus.overdue:
        return 'Needs Cleaning';
    }
  }

  List<ClothingItem> _getSortedItems() {
    final items = _storage.getWardrobe();
    items.sort((a, b) {
      final daysA = _daysSinceLastClean(a.id);
      final daysB = _daysSinceLastClean(b.id);
      return daysB.compareTo(daysA);
    });
    return items;
  }

  Map<String, int> _getSummary(List<ClothingItem> items) {
    int cleaned = 0;
    int soon = 0;
    int overdue = 0;

    for (final item in items) {
      final days = _daysSinceLastClean(item.id);
      final status = _getStatus(days);
      switch (status) {
        case _DryCleanStatus.clean:
          cleaned++;
          break;
        case _DryCleanStatus.soon:
          soon++;
          break;
        case _DryCleanStatus.overdue:
          overdue++;
          break;
      }
    }

    return {
      'cleaned': cleaned,
      'soon': soon,
      'overdue': overdue,
    };
  }

  void _showScheduleDatePicker(String itemId) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dryCleaningData[itemId] = picked.toIso8601String();
      });
      await _saveData();
    }
  }

  void _markAsCleaned(String itemId) async {
    setState(() {
      _dryCleaningData[itemId] = DateTime.now().toIso8601String();
    });
    await _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Dry Cleaning Tracker',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final items = _getSortedItems();

    if (items.isEmpty) {
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
              'No wardrobe items',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to your wardrobe to track dry cleaning',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final summary = _getSummary(items);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(summary),
          const SizedBox(height: 20),
          Text(
            'Wardrobe Items',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildItemCard(item)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, int> summary) {
    return Container(
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            '${summary['cleaned']}',
            'Cleaned',
            Icons.check_circle,
            Colors.white,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildSummaryItem(
            '${summary['soon']}',
            'Need Cleaning',
            Icons.schedule,
            Colors.white,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildSummaryItem(
            '${summary['overdue']}',
            'Overdue',
            Icons.warning,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon, Color color) {
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

  Widget _buildItemCard(ClothingItem item) {
    final days = _daysSinceLastClean(item.id);
    final status = _getStatus(days);
    final statusColor = _getStatusColor(status);
    final lastCleaned = _getLastCleanedDate(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: status == _DryCleanStatus.overdue
            ? Border.all(color: AppTheme.errorColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: status == _DryCleanStatus.overdue
                ? AppTheme.errorColor.withOpacity(0.15)
                : AppTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: statusColor,
                    size: 24,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.category.name} • ${item.primaryColor}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                days >= 999
                    ? 'Never dry cleaned'
                    : '$days days since last dry clean',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (lastCleaned != null) ...[
                const Spacer(),
                Text(
                  'Last: ${_formatDate(lastCleaned)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showScheduleDatePicker(item.id),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    'Schedule Dry Clean',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _markAsCleaned(item.id),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    'Mark as Cleaned',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

enum _DryCleanStatus { clean, soon, overdue }
