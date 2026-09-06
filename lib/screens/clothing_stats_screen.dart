import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/clothing_item.dart';

class ClothingStatsScreen extends StatefulWidget {
  const ClothingStatsScreen({super.key});

  @override
  State<ClothingStatsScreen> createState() => _ClothingStatsScreenState();
}

class _ClothingStatsScreenState extends State<ClothingStatsScreen> {
  final StorageService _storage = StorageService();

  late List<ClothingItem> _wardrobe;
  late Map<String, int> _categoryStats;
  late Map<String, int> _colorStats;
  late Map<String, int> _seasonStats;
  String _mostCommonColor = '';
  String _mostCommonCategory = '';
  String _mostCommonSeason = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    _wardrobe = _storage.getWardrobe();
    _categoryStats = {};
    _colorStats = {};
    _seasonStats = {};

    if (_wardrobe.isEmpty) return;

    // Category stats
    for (final cat in ClothingCategory.values) {
      final count = _wardrobe.where((item) => item.category == cat).length;
      if (count > 0) {
        _categoryStats[cat.name[0].toUpperCase() + cat.name.substring(1)] = count;
      }
    }

    // Color stats
    for (final item in _wardrobe) {
      for (final color in item.colors) {
        final name = color[0].toUpperCase() + color.substring(1);
        _colorStats[name] = (_colorStats[name] ?? 0) + 1;
      }
    }

    // Season stats
    for (final item in _wardrobe) {
      for (final season in item.seasons) {
        final label = season == ClothingSeason.allSeason
            ? 'All Season'
            : season.name[0].toUpperCase() + season.name.substring(1);
        _seasonStats[label] = (_seasonStats[label] ?? 0) + 1;
      }
    }

    // Most common values
    if (_categoryStats.isNotEmpty) {
      _mostCommonCategory = _categoryStats.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    if (_colorStats.isNotEmpty) {
      _mostCommonColor = _colorStats.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    if (_seasonStats.isNotEmpty) {
      _mostCommonSeason = _seasonStats.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Wardrobe Ka Hisab',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _wardrobe.isEmpty ? _buildEmptyState() : _buildStatsContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checkroom_outlined,
                size: 64,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Wardrobe mein kapde add karo pehle',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some clothes to see your wardrobe analytics',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildSectionTitle('Categories'),
          const SizedBox(height: 12),
          _buildBarChart(_categoryStats, AppTheme.primaryColor),
          const SizedBox(height: 24),
          _buildSectionTitle('Colors'),
          const SizedBox(height: 12),
          _buildBarChart(_colorStats, AppTheme.secondaryColor),
          const SizedBox(height: 24),
          _buildSectionTitle('Seasons'),
          const SizedBox(height: 12),
          _buildBarChart(_seasonStats, AppTheme.accentColor),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wardrobe Analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_wardrobe.length} items in your collection',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Total Items',
          '${_wardrobe.length}',
          Icons.checkroom,
          AppTheme.primaryColor,
        ),
        _buildStatCard(
          'Top Color',
          _mostCommonColor.isEmpty ? '-' : _mostCommonColor,
          Icons.palette,
          AppTheme.secondaryColor,
        ),
        _buildStatCard(
          'Top Category',
          _mostCommonCategory.isEmpty ? '-' : _mostCommonCategory,
          Icons.category,
          AppTheme.accentColor,
        ),
        _buildStatCard(
          'Top Season',
          _mostCommonSeason.isEmpty ? '-' : _mostCommonSeason,
          Icons.wb_sunny,
          AppTheme.warningColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: data.entries.map((entry) {
          final fraction = maxValue > 0 ? entry.value / maxValue : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        height: 22,
                        width: MediaQuery.of(context).size.width * 0.45 * fraction,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.6)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${entry.value}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
