import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class FabricCareScreen extends StatefulWidget {
  const FabricCareScreen({super.key});

  @override
  State<FabricCareScreen> createState() => _FabricCareScreenState();
}

class _FabricCareScreenState extends State<FabricCareScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFabrics = _fabricData.where((f) {
      return f.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Fabric Care Guide',
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
          _buildSearchBar(),
          Expanded(
            child: filteredFabrics.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredFabrics.length,
                    itemBuilder: (context, index) {
                      return _buildFabricCard(filteredFabrics[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search fabrics...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.backgroundColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 12),
          Text(
            'No fabric found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabricCard(FabricData fabric) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: AppTheme.backgroundColor,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: fabric.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(fabric.icon, color: fabric.color, size: 24),
          ),
          title: Text(
            fabric.name,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            fabric.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.expand_more,
            color: AppTheme.textLight,
          ),
          children: [
            _buildDetailRow(Icons.water_drop_outlined, 'Washing', fabric.wash),
            _buildDetailRow(Icons.wb_sunny_outlined, 'Drying', fabric.dry),
            _buildDetailRow(Icons.iron_outlined, 'Ironing', fabric.iron),
            _buildDetailRow(Icons.inventory_2_outlined, 'Storage', fabric.storage),
            const SizedBox(height: 8),
            _buildDosDonts(fabric.dos, fabric.donts),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '$label: ',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: text,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosDonts(List<String> dos, List<String> donts) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Do's",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 4),
              ...dos.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppTheme.successColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Don'ts",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 4),
              ...donts.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.cancel, size: 14, color: AppTheme.errorColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  static final List<FabricData> _fabricData = [
    FabricData(
      name: 'Cotton',
      subtitle: 'Natural fiber, breathable & versatile',
      icon: Icons.eco,
      color: const Color(0xFF2E7D32),
      wash: 'Machine wash cold or warm (40°C). Use mild detergent. Turn inside out before washing.',
      dry: 'Tumble dry on low heat or line dry in shade. Remove promptly to avoid wrinkles.',
      iron: 'Iron on medium to high heat while slightly damp. Use steam for stubborn wrinkles.',
      storage: 'Fold neatly or hang in a cool, dry place. Keep away from direct sunlight to prevent yellowing.',
      dos: const ['Pre-shrink before sewing', 'Wash dark colors separately', 'Use fabric softener occasionally'],
      donts: const ['Avoid bleach on colored cotton', 'Don\'t wring vigorously', 'Avoid drying in direct sun'],
    ),
    FabricData(
      name: 'Silk',
      subtitle: 'Luxurious natural protein fiber',
      icon: Icons.diamond_outlined,
      color: const Color(0xFF8E24AA),
      wash: 'Hand wash in lukewarm water (30°C) with silk-specific detergent. Never wring or twist.',
      dry: 'Lay flat on a towel to air dry. Keep away from direct heat and sunlight.',
      iron: 'Iron on low heat (silk setting) while still damp. Iron on the reverse side or use a pressing cloth.',
      storage: 'Store folded in a breathable cotton bag. Add cedar blocks to repel moths. Avoid plastic bags.',
      dos: const ['Use pH-neutral detergent', 'Hang to air after wearing', 'Steam to remove wrinkles gently'],
      donts: const ['Never use bleach', 'Avoid washing machine', 'Don\'t hang on wire hangers'],
    ),
    FabricData(
      name: 'Wool',
      subtitle: 'Warm, resilient natural animal fiber',
      icon: Icons.pets,
      color: const Color(0xFFD84315),
      wash: 'Hand wash in cold water (30°C) with wool-specific detergent. Squeeze gently, don\'t rub.',
      dry: 'Lay flat on a towel away from heat. Reshape while damp. Never hang wool garments.',
      iron: 'Iron on low heat with a damp pressing cloth. Steam from a distance to reshape.',
      storage: 'Fold and store with cedar or lavender sachets. Use breathable garment bags. Protect from moths.',
      dos: const ['Use wool-specific detergent', 'Store folded, not hung', 'Air out after wearing'],
      donts: const ['Never wring or twist', 'Avoid machine dryer', 'Don\'t use bleach or vinegar'],
    ),
    FabricData(
      name: 'Denim',
      subtitle: 'Durable cotton twill weave',
      icon: Icons.checkroom,
      color: const Color(0xFF1565C0),
      wash: 'Turn inside out. Machine wash cold with like colors. Wash infrequently to preserve color.',
      dry: 'Hang dry or tumble dry on low. Avoid excessive heat which causes shrinkage.',
      iron: 'Iron on medium-high heat while damp for a crisp finish. Use steam for tough creases.',
      storage: 'Hang by the waistband or fold neatly. Dark denim should be stored away from light.',
      dos: const ['Turn inside out before wash', 'Wash with cold water', 'Spot clean when possible'],
      donts: const ['Avoid over-washing', 'Don\'t use bleach', 'Avoid high-heat drying'],
    ),
    FabricData(
      name: 'Polyester',
      subtitle: 'Synthetic, wrinkle-resistant & durable',
      icon: Icons.science,
      color: const Color(0xFF00897B),
      wash: 'Machine wash warm (40°C). Polyester is colorfast and retains shape well.',
      dry: 'Tumble dry on low heat. Remove promptly. Polyester dries very quickly.',
      iron: 'Iron on low heat if needed. Usually wrinkle-resistant. Use steam for set-in wrinkles.',
      storage: 'Fold or hang as preferred. Very low maintenance storage. Resistant to moths and mildew.',
      dos: const ['Wash with similar fabrics', 'Use regular detergent', 'Remove from dryer promptly'],
      donts: const ['Avoid high heat ironing', 'Don\'t use fabric softener often', 'Avoid static buildup with dryer sheets'],
    ),
    FabricData(
      name: 'Linen',
      subtitle: 'Lightweight natural flax fiber',
      icon: Icons.grass,
      color: const Color(0xFF689F38),
      wash: 'Machine wash cold or warm with mild detergent. Wash separately for first few washes.',
      dry: 'Line dry in shade. Linen dries quickly. Shake out before hanging to reduce wrinkles.',
      iron: 'Iron while damp on medium-high heat. Use steam. Iron on the reverse side for sheen preservation.',
      storage: 'Fold loosely and store in a cool, dry place. Avoid hanging to prevent stretching.',
      dos: const ['Embrace natural wrinkles', 'Wash in mesh bags', 'Store with good air circulation'],
      donts: const ['Avoid high-heat tumble drying', 'Don\'t bleach frequently', 'Avoid plastic storage bags'],
    ),
    FabricData(
      name: 'Leather',
      subtitle: 'Animal hide, needs special care',
      icon: Icons.shield,
      color: const Color(0xFF795548),
      wash: 'Wipe with a damp cloth for surface cleaning. Use leather-specific cleaners for deep cleaning.',
      dry: 'Air dry at room temperature away from heat sources. Stuff with paper to maintain shape.',
      iron: 'Never iron directly. Use a cool iron with a protective cloth for gentle smoothing only.',
      storage: 'Store in breathable cloth bags. Use padded hangers. Keep in cool, dry area. Stuff to maintain shape.',
      dos: const ['Condition regularly with leather balm', 'Store in breathable bags', 'Rotate wearing to prevent wear patterns'],
      donts: const ['Never machine wash', 'Avoid direct sunlight for storage', 'Don\'t use plastic bags'],
    ),
    FabricData(
      name: 'Velvet',
      subtitle: 'Plush, dense pile fabric',
      icon: Icons.auto_awesome,
      color: const Color(0xFF6A1B9A),
      wash: 'Dry clean only for best results. Hand wash in cold water with velvet-specific detergent if necessary.',
      dry: 'Lay flat on a towel away from heat and direct sunlight. Reshape the pile while damp.',
      iron: 'Steam from the reverse side on low heat. Never iron directly on the pile.',
      storage: 'Hang on padded hangers in breathable garment bags. Avoid folding which crushes the pile.',
      dos: const ['Steam to refresh pile', 'Brush gently with a soft brush', 'Hang on padded hangers'],
      donts: const ['Never iron directly on pile', 'Avoid machine washing', 'Don\'t compress when storing'],
    ),
    FabricData(
      name: 'Chiffon',
      subtitle: 'Sheer, lightweight woven fabric',
      icon: Icons.air,
      color: const Color(0xFFEC407A),
      wash: 'Hand wash in cold water with gentle detergent. Place in a mesh laundry bag if machine washing.',
      dry: 'Lay flat on a towel to dry. Never wring chiffon. Handle gently when wet.',
      iron: 'Iron on low heat on the reverse side. Use a pressing cloth. Steam is preferred over direct ironing.',
      storage: 'Roll instead of folding to avoid creases. Store flat or hang in a garment bag.',
      dos: const ['Use mesh bags for washing', 'Roll for storage', 'Handle with care when wet'],
      donts: const ['Never wring or twist', 'Avoid high heat', 'Don\'t use bleach or harsh detergents'],
    ),
    FabricData(
      name: 'Satin',
      subtitle: 'Smooth, glossy weave with luxurious sheen',
      icon: Icons.star_outline,
      color: const Color(0xFFFFB300),
      wash: 'Hand wash in lukewarm water (30°C) with mild detergent. Turn inside out before washing.',
      dry: 'Lay flat on a towel to air dry. Avoid wringing. Keep away from direct sunlight.',
      iron: 'Iron on low heat on the reverse side while still damp. Use a pressing cloth for extra protection.',
      storage: 'Store folded in a cotton bag. Avoid hanging which can cause stretching and sagging.',
      dos: const ['Turn inside out before wash', 'Use mild detergent', 'Store in cotton bags'],
      donts: const ['Never use bleach', 'Avoid rough surfaces', 'Don\'t hang for long-term storage'],
    ),
    FabricData(
      name: 'Nylon',
      subtitle: 'Strong synthetic polymer fiber',
      icon: Icons.hardware,
      color: const Color(0xFF3949AB),
      wash: 'Machine wash warm (40°C). Use regular detergent. Avoid washing with rough fabrics.',
      dry: 'Tumble dry on low heat or line dry. Nylon dries very quickly.',
      iron: 'Iron on low heat if needed. Usually wrinkle-resistant. Use a pressing cloth to avoid shine.',
      storage: 'Fold and store in drawers. Very low maintenance. Resistant to moths and mildew.',
      dos: const ['Wash with similar synthetics', 'Use fabric softener to reduce static', 'Remove from dryer promptly'],
      donts: const ['Avoid high heat ironing', 'Don\'t wash with rough fabrics', 'Avoid prolonged sunlight exposure'],
    ),
    FabricData(
      name: 'Rayon',
      subtitle: 'Semi-synthetic from wood pulp',
      icon: Icons.park,
      color: const Color(0xFF009688),
      wash: 'Hand wash in cold water or dry clean. Rayon weakens when wet, handle gently.',
      dry: 'Lay flat on a towel to air dry. Never wring. Reshape while damp.',
      iron: 'Iron on medium heat while still damp. Use steam for best results.',
      storage: 'Fold and store in a cool, dry place. Avoid hanging as rayon can stretch when wet.',
      dos: const ['Hand wash or dry clean', 'Support while wet', 'Iron while damp'],
      donts: const ['Never wring when wet', 'Avoid machine wash if possible', 'Don\'t hang wet rayon'],
    ),
    FabricData(
      name: 'Cashmere',
      subtitle: 'Premium soft goat wool fiber',
      icon: Icons.favorite,
      color: const Color(0xFFE91E63),
      wash: 'Hand wash in cold water (30°C) with cashmere-specific detergent. Gently squeeze, never rub.',
      dry: 'Lay flat on a towel and reshape. Dry away from heat and sunlight.',
      iron: 'Steam lightly on low heat from a distance. Never press directly with an iron.',
      storage: 'Fold and store in breathable bags with cedar balls. Wash before seasonal storage to prevent moth damage.',
      dos: const ['Rest between wears (24 hrs)', 'Use cashmere comb to remove pills', 'Store with cedar sachets'],
      donts: const ['Never machine wash', 'Don\'t hang on hangers', 'Avoid fabric softener'],
    ),
    FabricData(
      name: 'Georgette',
      subtitle: 'Sheer, crêpe-like lightweight fabric',
      icon: Icons.grain,
      color: const Color(0xFFFF7043),
      wash: 'Hand wash in cold water with mild detergent. Use a mesh bag for machine wash on delicate cycle.',
      dry: 'Lay flat on a towel to dry. Never wring. Handle carefully when wet as it\'s fragile.',
      iron: 'Iron on low heat on the reverse side. Use a pressing cloth. Steam is recommended over ironing.',
      storage: 'Roll gently and store flat. Avoid folding which creates permanent creases.',
      dos: const ['Use mesh bags for washing', 'Steam to remove wrinkles', 'Store rolled, not folded'],
      donts: const ['Never wring or twist', 'Avoid bleach or harsh chemicals', 'Don\'t hang on wire hangers'],
    ),
    FabricData(
      name: 'Net',
      subtitle: 'Open weave mesh-like fabric',
      icon: Icons.grid_view,
      color: const Color(0xFF78909C),
      wash: 'Hand wash in cold water with gentle detergent. Place in a mesh laundry bag for protection.',
      dry: 'Lay flat on a towel to air dry. Never wring. Reshape the mesh while damp.',
      iron: 'Steam lightly from a distance on low heat. Avoid direct iron contact which can melt the fibers.',
      storage: 'Roll loosely and store in a breathable bag. Avoid folding to maintain the mesh structure.',
      dos: const ['Use mesh bags for protection', 'Steam gently to refresh', 'Store with good ventilation'],
      donts: const ['Never wring net fabric', 'Avoid direct iron contact', 'Don\'t store in compressed form'],
    ),
  ];
}

class FabricData {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String wash;
  final String dry;
  final String iron;
  final String storage;
  final List<String> dos;
  final List<String> donts;

  const FabricData({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.wash,
    required this.dry,
    required this.iron,
    required this.storage,
    required this.dos,
    required this.donts,
  });
}
