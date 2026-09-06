import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/features_service.dart';
import '../models/outfit_history.dart';

class OutfitRatingScreen extends StatefulWidget {
  const OutfitRatingScreen({super.key});

  @override
  State<OutfitRatingScreen> createState() => _OutfitRatingScreenState();
}

class _OutfitRatingScreenState extends State<OutfitRatingScreen> {
  final FeaturesService _featuresService = FeaturesService();
  Map<String, int> _ratings = {};
  Map<String, String> _notes = {};
  bool _loading = true;
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingKeys = prefs.getKeys().where((k) => k.startsWith('rating_'));
    final noteKeys = prefs.getKeys().where((k) => k.startsWith('note_'));

    final ratings = <String, int>{};
    final notes = <String, String>{};

    for (final key in ratingKeys) {
      final id = key.replaceFirst('rating_', '');
      ratings[id] = prefs.getInt(key) ?? 3;
    }
    for (final key in noteKeys) {
      final id = key.replaceFirst('note_', '');
      notes[id] = prefs.getString(key) ?? '';
    }

    setState(() {
      _ratings = ratings;
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _saveRating(String outfitId, int rating, {String? notes}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rating_$outfitId', rating);
    if (notes != null) {
      await prefs.setString('note_$outfitId', notes);
    }
    setState(() {
      _ratings[outfitId] = rating;
      if (notes != null) _notes[outfitId] = notes;
    });
  }

  int _getRating(String outfitId) => _ratings[outfitId] ?? 3;

  String _getNote(String outfitId) => _notes[outfitId] ?? '';

  double get _averageRating {
    final outfits = _featuresService.getAllHistory();
    if (outfits.isEmpty) return 0;
    final total = outfits.fold<int>(0, (sum, o) => sum + _getRating(o.id));
    return total / outfits.length;
  }

  List<OutfitHistory> get _topRated {
    final outfits = _featuresService.getAllHistory();
    final rated = outfits.where((o) => _ratings.containsKey(o.id)).toList();
    rated.sort((a, b) => _getRating(b.id).compareTo(_getRating(a.id)));
    return rated.take(5).toList();
  }

  List<OutfitHistory> get _lowRated {
    final outfits = _featuresService.getAllHistory();
    final rated = outfits.where((o) => _ratings.containsKey(o.id)).toList();
    rated.sort((a, b) => _getRating(a.id).compareTo(_getRating(b.id)));
    return rated.take(5).toList();
  }

  List<OutfitHistory> get _sortedOutfits {
    final outfits = _featuresService.getAllHistory();
    switch (_sortBy) {
      case 'rating_high':
        outfits.sort((a, b) => _getRating(b.id).compareTo(_getRating(a.id)));
        break;
      case 'rating_low':
        outfits.sort((a, b) => _getRating(a.id).compareTo(_getRating(b.id)));
        break;
      default:
        outfits.sort((a, b) => b.date.compareTo(a.date));
    }
    return outfits;
  }

  void _showQuickRateSheet(OutfitHistory outfit) {
    int tempRating = _getRating(outfit.id);
    final noteController = TextEditingController(text: _getNote(outfit.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rate This Outfit',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempRating = starNum),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starNum <= tempRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppTheme.warningColor,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ratingLabel(tempRating),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Notes (e.g., "Bahut achha laga")',
                      hintStyle: GoogleFonts.poppins(color: AppTheme.textLight),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _saveRating(
                          outfit.id,
                          tempRating,
                          notes: noteController.text,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Rating saved!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Save Rating',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _ratingLabel(int rating) {
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

  Color _ratingColor(int rating) {
    switch (rating) {
      case 1:
        return AppTheme.errorColor;
      case 2:
        return const Color(0xFFFF9800);
      case 3:
        return AppTheme.warningColor;
      case 4:
        return AppTheme.successColor;
      case 5:
        return const Color(0xFF10B981);
      default:
        return AppTheme.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Rate Outfits',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _featuresService.getAllHistory().isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAverageCard(),
                      const SizedBox(height: 16),
                      _buildSortBar(),
                      const SizedBox(height: 16),
                      if (_topRated.isNotEmpty) ...[
                        _buildSectionHeader('Top Rated Outfits', Icons.star_rounded, AppTheme.warningColor),
                        const SizedBox(height: 8),
                        ..._topRated.map((o) => _buildOutfitCard(o)),
                        const SizedBox(height: 20),
                      ],
                      if (_lowRated.isNotEmpty) ...[
                        _buildSectionHeader('Needs Improvement', Icons.trending_down_rounded, AppTheme.errorColor),
                        const SizedBox(height: 8),
                        ..._lowRated.map((o) => _buildOutfitCard(o)),
                        const SizedBox(height: 20),
                      ],
                      _buildSectionHeader('All Outfits', Icons.checkroom, AppTheme.primaryColor),
                      const SizedBox(height: 8),
                      ..._sortedOutfits.map((o) => _buildOutfitCard(o)),
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
          Icon(Icons.rate_review_outlined, size: 80, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'No Outfits Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add outfits to your history to start rating them',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard() {
    final avg = _averageRating;
    final rated = _ratings.length;
    final total = _featuresService.getAllHistory().length;

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
                  'Average Rating',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Icon(Icons.star_rounded, color: AppTheme.warningColor, size: 24),
                    ),
                  ],
                ),
                Text(
                  '$rated of $total outfits rated',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
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
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Row(
      children: [
        Text(
          'Sort by:',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        _buildSortChip('Date', 'date'),
        const SizedBox(width: 6),
        _buildSortChip('Highest', 'rating_high'),
        const SizedBox(width: 6),
        _buildSortChip('Lowest', 'rating_low'),
      ],
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOutfitCard(OutfitHistory outfit) {
    final rating = _getRating(outfit.id);
    final note = _getNote(outfit.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _ratingColor(rating).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (outfit.occasion != null && outfit.occasion!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          outfit.occasion!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${outfit.itemIds.length} item${outfit.itemIds.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(outfit.date),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppTheme.warningColor,
                        size: 18,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ratingLabel(rating),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _ratingColor(rating),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                note,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showQuickRateSheet(outfit),
              icon: const Icon(Icons.star_rate_rounded, size: 18),
              label: Text(
                'Quick Rate',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(color: _ratingColor(rating).withOpacity(0.3)),
                foregroundColor: _ratingColor(rating),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
