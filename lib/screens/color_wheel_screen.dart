import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ColorWheelScreen extends StatelessWidget {
  const ColorWheelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Color Wheel',
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
            _buildColorWheel(),
            const SizedBox(height: 24),
            _buildHarmonySections(),
            const SizedBox(height: 24),
            _buildFashionRules(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorWheel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Color Wheel',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The foundation of color theory',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            width: 280,
            child: CustomPaint(
              painter: ColorWheelPainter(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _legendDot(Colors.red, 'Red'),
              _legendDot(const Color(0xFFFF7F00), 'Orange'),
              _legendDot(Colors.yellow, 'Yellow'),
              _legendDot(Colors.green, 'Green'),
              _legendDot(const Color(0xFF00BFFF), 'Blue'),
              _legendDot(const Color(0xFF8B00FF), 'Purple'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHarmonySections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Harmonies',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Perfect color combinations for your outfits',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildHarmonyCard(
          'Complementary',
          'Colors opposite on the wheel. Creates bold, high-contrast looks.',
          [
            [Colors.red, const Color(0xFF228B22)],
            [Colors.blue, const Color(0xFFFF7F00)],
            [Colors.yellow, const Color(0xFF800080)],
          ],
          ['Red + Green', 'Blue + Orange', 'Yellow + Purple'],
          'Great for statement pieces — a red dress with green accessories makes a striking impression.',
        ),
        _buildHarmonyCard(
          'Analogous',
          'Colors next to each other on the wheel. Creates calm, cohesive looks.',
          [
            [Colors.red, const Color(0xFFFF4500), const Color(0xFFFF8C00)],
            [Colors.blue, const Color(0xFF008B8B), const Color(0xFF00CED1)],
            [Colors.green, const Color(0xFF228B22), const Color(0xFF006400)],
          ],
          ['Red + Orange + Amber', 'Blue + Teal + Cyan', 'Green + Forest + Emerald'],
          'Perfect for monochromatic outfits or tonal layering — adds depth without clashing.',
        ),
        _buildHarmonyCard(
          'Triadic',
          'Three colors evenly spaced (120° apart). Creates vibrant, balanced outfits.',
          [
            [Colors.red, Colors.blue, Colors.yellow],
            [const Color(0xFFFF4500), const Color(0xFF00CED1), Colors.purple],
          ],
          ['Red + Blue + Yellow', 'Orange + Green + Purple'],
          'Use one dominant color with the other two as accents for balanced, energetic outfits.',
        ),
        _buildHarmonyCard(
          'Split-Complementary',
          'One color + the two adjacent to its complement. Bold but less harsh than complementary.',
          [
            [Colors.blue, const Color(0xFFFF4500), Colors.yellow],
            [Colors.red, const Color(0xFF00CED1), Colors.green],
          ],
          ['Blue + Red-Orange + Yellow-Orange', 'Red + Blue-Green + Yellow-Green'],
          'Ideal for beginners — gives contrast without the tension of complementary pairings.',
        ),
      ],
    );
  }

  Widget _buildHarmonyCard(
    String title,
    String description,
    List<List<Color>> palettes,
    List<String> paletteLabels,
    String fashionTip,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(palettes.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: palettes[i][0],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.add, size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: palettes[i][1],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        if (palettes[i].length > 2) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.add, size: 14, color: AppTheme.textLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: palettes[i][2],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      paletteLabels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.warningColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fashionTip,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFashionRules() {
    final rules = [
      _FashionRule(
        'Neutral colors go with everything',
        'Black, white, beige, gray, navy, and brown are universal. Build your wardrobe foundation with these.',
        Icons.check_circle_outline,
        const Color(0xFF10B981),
      ),
      _FashionRule(
        'Maximum 3 colors in one outfit',
        'Stick to one dominant color, one secondary, and one accent. More than three can look chaotic.',
        Icons.looks_3,
        const Color(0xFF3B82F6),
      ),
      _FashionRule(
        'Dark colors slim, light colors expand',
        'Dark shades create a slimming silhouette while light tones add volume. Use this to your advantage.',
        Icons.swap_vert,
        AppTheme.primaryColor,
      ),
      _FashionRule(
        'Skin tone matters',
        'Warm undertones pair well with earthy tones, coral, and gold. Cool undertones shine in jewel tones, silver, and pastels.',
        Icons.face,
        AppTheme.secondaryColor,
      ),
      _FashionRule(
        'Use the 60-30-10 rule',
        '60% dominant color, 30% secondary color, 10% accent. This creates a naturally balanced outfit.',
        Icons.pie_chart_outline,
        const Color(0xFFF59E0B),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fashion Color Rules',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Essential tips for every outfit',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...rules.map((rule) => _buildRuleCard(rule)),
      ],
    );
  }

  Widget _buildRuleCard(_FashionRule rule) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: rule.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              rule.icon,
              color: rule.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rule.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ColorWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final colors = [
      Colors.red,
      const Color(0xFFFF4500),
      const Color(0xFFFF7F00),
      Colors.orange,
      const Color(0xFFFFA500),
      Colors.yellow,
      const Color(0xFFADFF2F),
      Colors.green,
      const Color(0xFF228B22),
      const Color(0xFF00CED1),
      const Color(0xFF00BFFF),
      Colors.blue,
      const Color(0xFF4169E1),
      const Color(0xFF8B00FF),
      Colors.purple,
      const Color(0xFF800080),
    ];

    final outerRadius = radius;
    final innerRadius = radius * 0.55;

    for (int i = 0; i < colors.length; i++) {
      final startAngle = (2 * pi / colors.length) * i - pi / 2;
      final sweepAngle = 2 * pi / colors.length;

      final outerPath = Path();
      outerPath.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
      );
      final innerPath = Path();
      innerPath.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );

      final path = Path.combine(PathOperation.intersect, outerPath, innerPath);

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      final midAngle = startAngle + sweepAngle / 2;
      final labelRadius = radius * 0.76;
      final labelX = center.dx + labelRadius * cos(midAngle);
      final labelY = center.dy + labelRadius * sin(midAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${(i * 360 / colors.length).round()}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelX - textPainter.width / 2,
          labelY - textPainter.height / 2,
        ),
      );
    }

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerRadius - 2, centerPaint);

    final centerText = TextPainter(
      text: TextSpan(
        text: 'Color\nTheory',
        style: GoogleFonts.poppins(
          color: AppTheme.primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    centerText.layout();
    centerText.paint(
      canvas,
      Offset(
        center.dx - centerText.width / 2,
        center.dy - centerText.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FashionRule {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _FashionRule(this.title, this.description, this.icon, this.color);
}
