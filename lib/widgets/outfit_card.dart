import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/outfit.dart';
import '../theme/app_theme.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onWear;
  final bool showActions;

  const OutfitCard({
    super.key,
    required this.outfit,
    this.onTap,
    this.onSave,
    this.onWear,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildImageGrid(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outfit.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTag(outfit.occasion.name.toUpperCase(), AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    _buildTag(outfit.season.name.toUpperCase(), AppTheme.accentColor),
                  ],
                ),
              ],
            ),
          ),
          _buildAIScore(),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAIScore() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'AI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${(outfit.aiScore * 100).round()}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    final items = outfit.items.take(4).toList();
    final remaining = outfit.items.length - 4;

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (items.isNotEmpty)
            Expanded(
              flex: 2,
              child: _buildMainImage(items[0]),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                if (items.length > 1)
                  Expanded(
                    child: _buildSmallImage(items[1]),
                  ),
                if (items.length > 2) ...[
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        if (items.length > 2)
                          Expanded(
                            child: _buildSmallImage(items[2]),
                          ),
                        if (items.length > 3) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Stack(
                              children: [
                                _buildSmallImage(items[3]),
                                if (remaining > 0)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '+$remaining',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage(dynamic item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _buildItemImage(item),
    );
  }

  Widget _buildSmallImage(dynamic item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _buildItemImage(item),
    );
  }

  Widget _buildItemImage(dynamic item) {
    if (item.imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: item.imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(item),
        errorWidget: (context, url, error) => _buildPlaceholder(item),
      );
    }

    final file = File(item.imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(item),
      );
    }

    return _buildPlaceholder(item);
  }

  Widget _buildPlaceholder(dynamic item) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getColorFromName(item.primaryColor).withOpacity(0.3),
            AppTheme.getColorFromName(item.primaryColor).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(item.category),
          color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (outfit.aiReason != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      outfit.aiReason!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (showActions)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSave,
                    icon: Icon(
                      outfit.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                    ),
                    label: Text(outfit.isSaved ? 'Saved' : 'Save'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onWear,
                    icon: const Icon(Icons.checkroom, size: 18),
                    label: const Text('Wear Today'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(dynamic category) {
    switch (category) {
      case 'tops':
        return Icons.checkroom;
      case 'bottoms':
        return Icons.water_drop_outlined;
      case 'outerwear':
        return Icons.ac_unit;
      case 'dresses':
        return Icons.woman;
      case 'footwear':
        return Icons.snowshoeing;
      case 'accessories':
        return Icons.watch;
      case 'activewear':
        return Icons.fitness_center;
      case 'formal':
        return Icons.business_center;
      default:
        return Icons.checkroom;
    }
  }
}
