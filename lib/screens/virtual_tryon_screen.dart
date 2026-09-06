import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ar_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';
import '../widgets/ar_view_widget.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final ClothingItem? initialItem;

  const VirtualTryOnScreen({super.key, this.initialItem});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  ClothingItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialItem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ARProvider>(
        builder: (context, arProvider, child) {
          if (arProvider.isARActive && _selectedItem != null) {
            return _buildARView(arProvider);
          }

          return _buildSelectionView(arProvider);
        },
      ),
    );
  }

  Widget _buildARView(ARProvider arProvider) {
    return Stack(
      children: [
        ARViewWidget(
          item: _selectedItem!,
          rotationX: arProvider.rotationX,
          rotationY: arProvider.rotationY,
          scale: arProvider.scale,
          positionX: arProvider.positionX,
          positionY: arProvider.positionY,
          showSkeleton: arProvider.showSkeleton,
          onCapture: () => _captureScreenshot(),
          onReset: () => arProvider.resetTransform(),
          onClose: () {
            arProvider.stopARTryOn();
            setState(() {
              _selectedItem = null;
            });
          },
        ),
        _buildARControls(arProvider),
      ],
    );
  }

  Widget _buildARControls(ARProvider arProvider) {
    return Positioned(
      left: 16,
      top: 100,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.rotate_right,
            label: 'Rotate',
            onTap: () {
              arProvider.updateRotation(
                arProvider.rotationX,
                arProvider.rotationY + 45,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.flip,
            label: 'Flip',
            onTap: () {
              arProvider.updateRotation(
                arProvider.rotationX + 180,
                arProvider.rotationY,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.zoom_in,
            label: 'Zoom',
            onTap: () {
              arProvider.updateScale(arProvider.scale + 0.2);
            },
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.zoom_out,
            label: 'Shrink',
            onTap: () {
              arProvider.updateScale(arProvider.scale - 0.2);
            },
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.accessibility_new,
            label: 'Skeleton',
            isActive: arProvider.showSkeleton,
            onTap: () => arProvider.toggleSkeleton(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryColor
                  : Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionView(ARProvider arProvider) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _selectedItem == null
                ? _buildItemSelector()
                : _buildSelectedPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
          const Text(
            'Virtual Try-On',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildItemSelector() {
    return Consumer<WardrobeProvider>(
      builder: (context, wardrobeProvider, child) {
        final items = wardrobeProvider.allWardrobe;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.checkroom,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No items to try on',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add clothes to your wardrobe first',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select an item to try on',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildItemCard(item);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemCard(ClothingItem item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedItem = item;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(item.category),
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
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

  Widget _buildSelectedPreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.getColorFromName(_selectedItem!.primaryColor)
                      .withOpacity(0.2),
                  Colors.black.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.getColorFromName(_selectedItem!.primaryColor)
                          .withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(_selectedItem!.category),
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedItem!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedItem!.category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedItem = null;
                    });
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Change Item'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ARProvider>().startARTryOn(_selectedItem!);
                  },
                  icon: const Icon(Icons.view_in_ar),
                  label: const Text('Start AR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _captureScreenshot() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot saved!'),
        backgroundColor: AppTheme.successColor,
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
