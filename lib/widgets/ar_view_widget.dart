import 'dart:io';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';

class ARViewWidget extends StatelessWidget {
  final ClothingItem item;
  final double rotationX;
  final double rotationY;
  final double scale;
  final double positionX;
  final double positionY;
  final bool showSkeleton;
  final VoidCallback? onCapture;
  final VoidCallback? onReset;
  final VoidCallback? onClose;

  const ARViewWidget({
    super.key,
    required this.item,
    this.rotationX = 0,
    this.rotationY = 0,
    this.scale = 1.0,
    this.positionX = 0,
    this.positionY = 0,
    this.showSkeleton = false,
    this.onCapture,
    this.onReset,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Stack(
        children: [
          _buildARContent(),
          _buildControls(),
          _buildCloseButton(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildARContent() {
    return Center(
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(rotationX * 3.14159 / 180)
          ..rotateY(rotationY * 3.14159 / 180)
          ..scale(scale)
          ..translate(positionX, positionY),
        alignment: Alignment.center,
        child: _buildModelViewer(),
      ),
    );
  }

  Widget _buildModelViewer() {
    if (item.imagePath.startsWith('http')) {
      return ModelViewer(
        src: item.imagePath,
        alt: item.name,
        ar: true,
        autoRotate: true,
        autoPlay: true,
        animationName: null,
        cameraControls: true,
        backgroundColor: const Color(0xFF000000),
      );
    }

    final file = File(item.imagePath);
    if (file.existsSync()) {
      return ModelViewer(
        src: file.uri.toString(),
        alt: item.name,
        ar: true,
        autoRotate: true,
        autoPlay: true,
        animationName: null,
        cameraControls: true,
        backgroundColor: const Color(0xFF000000),
      );
    }

    return _buildFallbackView();
  }

  Widget _buildFallbackView() {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getColorFromName(item.primaryColor).withOpacity(0.3),
            AppTheme.getColorFromName(item.primaryColor).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(item.category),
            size: 80,
            color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'AR Preview',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      right: 16,
      top: 100,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.zoom_in,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.zoom_out,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.rotate_right,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.flip,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.center_focus_strong,
            onTap: onReset,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 50,
      left: 16,
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBottomButton(
            icon: Icons.camera_alt,
            label: 'Capture',
            onTap: onCapture,
            isPrimary: true,
          ),
          const SizedBox(width: 24),
          _buildBottomButton(
            icon: Icons.info_outline,
            label: 'Details',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isPrimary ? AppTheme.primaryColor : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
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
