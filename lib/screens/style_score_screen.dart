import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/features_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class StyleScoreScreen extends StatefulWidget {
  const StyleScoreScreen({super.key});

  @override
  State<StyleScoreScreen> createState() => _StyleScoreScreenState();
}

class _StyleScoreScreenState extends State<StyleScoreScreen> {
  final FeaturesService _features = FeaturesService();
  final StorageService _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    final score = _features.calculateWeeklyScore();
    final wardrobeSize = _storage.getWardrobe().length;
    final historyCount = _features.getAllHistory().length;
    final wishlistPurchased = _features.getPurchasedItems().length;
    final laundryClean = _features.getAllLaundryItems().where((l) => l.daysSinceLastWash < 7).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Style Score',
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
          children: [
            _buildMainScore(score),
            const SizedBox(height: 24),
            _buildScoreBreakdown(score, wardrobeSize, historyCount, wishlistPurchased, laundryClean),
            const SizedBox(height: 20),
            _buildTipsCard(score),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScore(int score) {
    String level;
    Color levelColor;
    String message;

    if (score >= 80) {
      level = 'Style Master';
      levelColor = AppTheme.successColor;
      message = 'Outstanding! Your style game is on point!';
    } else if (score >= 60) {
      level = 'Style Pro';
      levelColor = AppTheme.primaryColor;
      message = 'Great job! You have a solid fashion sense.';
    } else if (score >= 40) {
      level = 'Style Learner';
      levelColor = AppTheme.warningColor;
      message = 'Good start! Keep exploring your style.';
    } else {
      level = 'Style Beginner';
      levelColor = AppTheme.secondaryColor;
      message = 'Start building your wardrobe and style!';
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Weekly Style Score',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 70.0,
            lineWidth: 12.0,
            percent: (score / 100).clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '/100',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            progressColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              level,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(int score, int wardrobeSize, int historyCount, int purchased, int laundryClean) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildBreakdownItem(
            'Outfit Variety',
            historyCount >= 5 ? 20 : historyCount * 4,
            20,
            Icons.checkroom,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem(
            'Wardrobe Size',
            wardrobeSize >= 20 ? 20 : wardrobeSize,
            20,
            Icons.inventory_2,
            AppTheme.secondaryColor,
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem(
            'Purchased Items',
            purchased >= 3 ? 20 : purchased * 7,
            20,
            Icons.shopping_bag,
            AppTheme.accentColor,
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem(
            'Laundry Status',
            laundryClean * 2,
            20,
            Icons.local_laundry_service,
            AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem(
            'Planned Outfits',
            _features.getAllCalendarEntries().where((c) => c.isCompleted).length >= 5
                ? 20
                : _features.getAllCalendarEntries().where((c) => c.isCompleted).length * 4,
            20,
            Icons.calendar_today,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int value, int max, IconData icon, Color color) {
    final percentage = (value / max).clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$value/$max',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppTheme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard(int score) {
    List<String> tips = [];

    if (score < 40) {
      tips = [
        'Add more items to your wardrobe',
        'Log your outfits to track style',
        'Keep your laundry up to date',
        'Plan outfits for the week',
      ];
    } else if (score < 70) {
      tips = [
        'Try mixing different outfit styles',
        'Purchase items from your wishlist',
        'Maintain your laundry schedule',
        'Complete more planned outfits',
      ];
    } else {
      tips = [
        'Keep up the great style!',
        'Try adding accessories',
        'Explore new color combinations',
        'Share your style tips',
      ];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb, color: AppTheme.warningColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Style Tips',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
