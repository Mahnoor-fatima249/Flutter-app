import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/clothing_item.dart';

class WearLogScreen extends StatefulWidget {
  const WearLogScreen({super.key});

  @override
  State<WearLogScreen> createState() => _WearLogScreenState();
}

class _WearLogScreenState extends State<WearLogScreen> {
  final StorageService _storage = StorageService();
  Map<String, Map<String, dynamic>> _wearData = {};
  List<ClothingItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWearData();
  }

  Future<void> _loadWearData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('wear_log_data');
    if (data != null) {
      final Map<String, dynamic> decoded = json.decode(data);
      _wearData = decoded.map((key, value) =>
          MapEntry(key, Map<String, dynamic>.from(value)));
    }
    _refreshItems();
    setState(() => _isLoading = false);
  }

  Future<void> _saveWearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wear_log_data', json.encode(_wearData));
  }

  void _refreshItems() {
    _items = _storage.getWardrobe();
    _items.sort((a, b) {
      final aDays = _daysSinceWorn(a.id);
      final bDays = _daysSinceWorn(b.id);
      final aUrgency = _getUrgency(aDays);
      final bUrgency = _getUrgency(bDays);
      if (aUrgency != bUrgency) {
        return bUrgency.compareTo(aUrgency);
      }
      return (bDays ?? 999).compareTo(aDays ?? 999);
    });
  }

  int? _daysSinceWorn(String itemId) {
    final wearInfo = _wearData[itemId];
    if (wearInfo == null || wearInfo['lastWorn'] == null) return null;
    final lastWorn = DateTime.parse(wearInfo['lastWorn']);
    return DateTime.now().difference(lastWorn).inDays;
  }

  int _getUrgency(int? days) {
    if (days == null) return 2;
    if (days >= 14) return 2;
    if (days >= 7) return 1;
    return 0;
  }

  Color _getUrgencyColor(int? days) {
    if (days == null) return AppTheme.warningColor;
    if (days < 7) return AppTheme.successColor;
    if (days < 14) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getUrgencyLabel(int? days) {
    if (days == null) return 'Never worn';
    if (days == 0) return 'Worn today';
    if (days < 7) return 'Fresh';
    if (days < 14) return 'Getting old';
    return 'Overdue';
  }

  int _getWearCount(String itemId) {
    final wearInfo = _wearData[itemId];
    if (wearInfo == null) return 0;
    return wearInfo['wearCount'] ?? 0;
  }

  Future<void> _markAsWornToday(ClothingItem item) async {
    final now = DateTime.now();
    _wearData[item.id] = {
      'lastWorn': now.toIso8601String(),
      'wearCount': (_wearData[item.id]?['wearCount'] ?? 0) + 1,
    };
    await _saveWearData();
    _refreshItems();
    setState(() {});
  }

  List<ClothingItem> _getFilteredItems(String filter) {
    return _items.where((item) {
      final days = _daysSinceWorn(item.id);
      if (filter == 'fresh') return days != null && days < 7;
      if (filter == 'attention') return days != null && days >= 7 && days < 14;
      if (filter == 'overdue') return days == null || days >= 14;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final freshCount = _getFilteredItems('fresh').length;
    final attentionCount = _getFilteredItems('attention').length;
    final overdueCount = _getFilteredItems('overdue').length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Wear Log',
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
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(freshCount, attentionCount, overdueCount),
                      const SizedBox(height: 16),
                      _buildItemsList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No items in wardrobe',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your wardrobe to track wear',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int fresh, int attention, int overdue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wear Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryItem('Fresh', fresh, AppTheme.successColor),
              const SizedBox(width: 8),
              _buildSummaryItem('Need attention', attention, AppTheme.warningColor),
              const SizedBox(width: 8),
              _buildSummaryItem('Overdue', overdue, AppTheme.errorColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Items (${_items.length})',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._items.map((item) => _buildItemCard(item)),
      ],
    );
  }

  Widget _buildItemCard(ClothingItem item) {
    final days = _daysSinceWorn(item.id);
    final color = _getUrgencyColor(days);
    final label = _getUrgencyLabel(days);
    final wearCount = _getWearCount(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
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
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: _getColorHex(item.primaryColor)),
                    const SizedBox(width: 4),
                    Text(
                      item.primaryColor,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.repeat, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      '$wearCount wears',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  days == null ? 'Never worn' : days == 0 ? 'Worn today' : '$days days since worn',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _markAsWornToday(item),
            icon: const Icon(Icons.check, size: 14),
            label: Text(
              'Worn',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorHex(String colorName) {
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'black': Colors.black,
      'white': Colors.white,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'pink': Colors.pink,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'brown': Colors.brown,
      'navy': const Color(0xFF000080),
      'beige': const Color(0xFFF5F5DC),
      'cream': const Color(0xFFFFDDC1),
      'maroon': const Color(0xFF800000),
      'olive': const Color(0xFF808000),
      'teal': const Color(0xFF008080),
      'cyan': Colors.cyan,
      'indigo': Colors.indigo,
    };
    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }
}