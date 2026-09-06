import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'outfit_calendar_screen.dart';
import 'wishlist_screen.dart';
import 'laundry_screen.dart';
import 'budget_screen.dart';
import 'travel_planner_screen.dart';
import 'style_dna_screen.dart';
import 'mix_match_screen.dart';
import 'outfit_history_screen.dart';
import 'style_score_screen.dart';
import 'color_palette_screen.dart';
import 'fabric_care_screen.dart';
import 'size_tracker_screen.dart';
import 'clothing_stats_screen.dart';
import 'shopping_list_screen.dart';
import 'color_wheel_screen.dart';
import 'outfit_builder_screen.dart';
import 'seasonal_planner_screen.dart';
import 'wear_log_screen.dart';
import 'dry_cleaning_screen.dart';
import 'outfit_rating_screen.dart';
import 'outfit_timeline_screen.dart';
import 'capsule_wardrobe_screen.dart';
import 'mood_board_screen.dart';
import 'weekly_planner_screen.dart';
import 'festival_planner_screen.dart';
import 'wardrobe_optimizer_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Fashion Tools',
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              'Planning & Organization',
              Icons.event_note,
              const Color(0xFF6366F1),
              [
                _ToolItem('Calendar', Icons.calendar_today, const Color(0xFF6366F1), const OutfitCalendarScreen()),
                _ToolItem('Weekly Planner', Icons.view_week_outlined, const Color(0xFF8B5CF6), const WeeklyPlannerScreen()),
                _ToolItem('Season Planner', Icons.wb_sunny_outlined, const Color(0xFFF59E0B), const SeasonalPlannerScreen()),
                _ToolItem('Festival Planner', Icons.celebration_outlined, const Color(0xFFEC4899), const FestivalPlannerScreen()),
                _ToolItem('Travel', Icons.flight_takeoff_outlined, const Color(0xFF0EA5E9), const TravelPlannerScreen()),
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              'Style & Outfits',
              Icons.checkroom,
              const Color(0xFFE94560),
              [
                _ToolItem('Outfit Builder', Icons.checkroom, const Color(0xFFE94560), const OutfitBuilderScreen()),
                _ToolItem('Mix & Match', Icons.compare_arrows, const Color(0xFF06B6D4), const MixMatchScreen()),
                _ToolItem('Capsule Wardrobe', Icons.inventory_2_outlined, const Color(0xFF7C3AED), const CapsuleWardrobeScreen()),
                _ToolItem('Wardrobe Optimizer', Icons.auto_awesome, AppTheme.successColor, const WardrobeOptimizerScreen()),
                _ToolItem('Mood Board', Icons.dashboard_outlined, const Color(0xFFFF8A65), const MoodBoardScreen()),
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              'Colors & Analysis',
              Icons.palette,
              const Color(0xFF10B981),
              [
                _ToolItem('Color Palette', Icons.palette_outlined, const Color(0xFF10B981), const ColorPaletteScreen()),
                _ToolItem('Color Wheel', Icons.colorize, const Color(0xFFE91E63), const ColorWheelScreen()),
                _ToolItem('Style DNA', Icons.psychology, const Color(0xFFF59E0B), const StyleDnaScreen()),
                _ToolItem('Style Score', Icons.emoji_events_outlined, const Color(0xFFFFC107), const StyleScoreScreen()),
                _ToolItem('Wardrobe Stats', Icons.bar_chart, const Color(0xFF3B82F6), const ClothingStatsScreen()),
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              'Tracking & Care',
              Icons.health_and_safety,
              const Color(0xFF059669),
              [
                _ToolItem('Laundry', Icons.local_laundry_service_outlined, const Color(0xFF059669), const LaundryScreen()),
                _ToolItem('Dry Cleaning', Icons.dry_cleaning_outlined, const Color(0xFF0891B2), const DryCleaningScreen()),
                _ToolItem('Fabric Care', Icons.cleaning_services_outlined, const Color(0xFF6366F1), const FabricCareScreen()),
                _ToolItem('Wear Log', Icons.event_repeat, const Color(0xFF14B8A6), const WearLogScreen()),
                _ToolItem('Size Tracker', Icons.straighten, const Color(0xFF0EA5E9), const SizeTrackerScreen()),
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              'Shopping & Budget',
              Icons.shopping_bag,
              const Color(0xFF8B5CF6),
              [
                _ToolItem('Wishlist', Icons.shopping_bag_outlined, const Color(0xFFEC4899), const WishlistScreen()),
                _ToolItem('Shopping List', Icons.shopping_cart_outlined, const Color(0xFFFF8A65), const ShoppingListScreen()),
                _ToolItem('Budget', Icons.account_balance_wallet_outlined, AppTheme.successColor, const BudgetScreen()),
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              'History & Insights',
              Icons.insights,
              const Color(0xFF14B8A6),
              [
                _ToolItem('History', Icons.history, const Color(0xFFEC4899), const OutfitHistoryScreen()),
                _ToolItem('Outfit Timeline', Icons.timeline, const Color(0xFF14B8A6), const OutfitTimelineScreen()),
                _ToolItem('Rate Outfits', Icons.star_rate_rounded, const Color(0xFFFFC107), const OutfitRatingScreen()),
              ],
            ),
          ],
        ),
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
                  'Your Fashion Toolkit',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '25+ tools to elevate your style',
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
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<_ToolItem> tools,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            return _buildToolCard(context, tools[index]);
          },
        ),
      ],
    );
  }

  Widget _buildToolCard(BuildContext context, _ToolItem tool) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => tool.screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: tool.color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tool.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tool.icon,
                color: tool.color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tool.name,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  final String name;
  final IconData icon;
  final Color color;
  final Widget screen;

  _ToolItem(this.name, this.icon, this.color, this.screen);
}
