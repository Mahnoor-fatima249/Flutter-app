import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';

class ClothingCard extends StatefulWidget {
  final ClothingItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDetails;
  final bool isSelected;

  const ClothingCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.showDetails = false,
    this.isSelected = false,
  });

  @override
  State<ClothingCard> createState() => _ClothingCardState();
}

class _ClothingCardState extends State<ClothingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primaryColor
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: widget.isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _buildImage(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildFavoriteBadge(),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildCategoryBadge(),
                    ),
                    if (widget.item.wearCount > 0)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: _buildWearCountBadge(),
                      ),
                  ],
                ),
              ),
              if (widget.showDetails) _buildDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.item.imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: widget.item.imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.backgroundColor,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    final file = File(widget.item.imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getColorFromName(widget.item.primaryColor).withOpacity(0.3),
            AppTheme.getColorFromName(widget.item.primaryColor).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(widget.item.category),
              size: 40,
              color: AppTheme.getColorFromName(widget.item.primaryColor).withOpacity(0.6),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.getColorFromName(widget.item.primaryColor),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteBadge() {
    if (!widget.item.isFavorite) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite,
        color: AppTheme.secondaryColor,
        size: 16,
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.item.category.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildWearCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 10, color: AppTheme.primaryColor),
          const SizedBox(width: 2),
          Text(
            '${widget.item.wearCount}',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.getColorFromName(widget.item.primaryColor),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.item.primaryColor,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (widget.item.brand != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.item.brand!,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ],
      ),
    );
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
