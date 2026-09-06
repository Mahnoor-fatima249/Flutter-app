import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/wardrobe_provider.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';
import '../widgets/clothing_card.dart';
import 'item_detail_screen.dart';
import 'camera_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  bool _isGridView = true;
  ClothingCategory? _selectedFilterCategory;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCategoryFilterChips(),
          Expanded(
            child: _buildContent(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Wardrobe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Consumer<WardrobeProvider>(
                builder: (context, provider, child) {
                  return Text(
                    '${provider.totalItems} items in your collection',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showSortOptions();
                },
                icon: const Icon(
                  Icons.sort,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<WardrobeProvider>(
        builder: (context, provider, child) {
          return TextField(
            onChanged: provider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search your wardrobe...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
              suffixIcon: provider.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () => provider.setSearchQuery(''),
                      icon: const Icon(Icons.clear, color: AppTheme.textLight),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilterChips() {
    return Consumer<WardrobeProvider>(
      builder: (context, provider, child) {
        final categories = [
          null,
          ...ClothingCategory.values,
        ];
        final labels = [
          'All',
          ...ClothingCategory.values.map((c) => c.name[0].toUpperCase() + c.name.substring(1)),
        ];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: List.generate(categories.length, (index) {
              final cat = categories[index];
              final isSelected = _selectedFilterCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(labels[index]),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilterCategory = cat;
                    });
                    provider.setCategory(cat);
                  },
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Consumer<WardrobeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = provider.wardrobe;

        if (provider.allWardrobe.isEmpty) {
          return _buildEmptyState();
        }

        if (items.isEmpty) {
          return _buildNoResultsFound();
        }

        if (_isGridView) {
          return AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: ClothingCard(
                        item: items[index],
                        showDetails: true,
                        onTap: () => _navigateToDetail(items[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildListItem(items[index]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildListItem(ClothingItem item) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.successColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.favorite, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          context.read<WardrobeProvider>().toggleFavorite(item.id);
          return false;
        }
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text('Remove ${item.name} from wardrobe?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<WardrobeProvider>().deleteClothingItem(item.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.cardDecoration,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.getColorFromName(item.primaryColor).withOpacity(0.3),
                  AppTheme.getColorFromName(item.primaryColor).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(item.category),
                color: AppTheme.getColorFromName(item.primaryColor).withOpacity(0.7),
                size: 28,
              ),
            ),
          ),
          title: Text(
            item.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            '${item.category.name} • ${item.primaryColor}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isFavorite)
                const Icon(Icons.favorite, color: AppTheme.secondaryColor, size: 20),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textLight),
            ],
          ),
          onTap: () => _navigateToDetail(item),
        ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 56,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Koi item nahi mila',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search term or category filter',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.secondaryColor.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checkroom,
                size: 56,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Apna Digital Wardrobe Banao',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan karke ya gallery se kapde add karo\nto AI unhe organize karega',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _buildTipCard(Icons.camera_alt, 'Scan se Kapde Add Karo', 'Camera ya gallery se photo lo, AI auto-detect karega'),
            const SizedBox(height: 10),
            _buildTipCard(Icons.palette, 'Color Detect Hoti Hai', 'Har kapde ki exact colour aur fabric AI batata hai'),
            const SizedBox(height: 10),
            _buildTipCard(Icons.checkroom, 'Outfits Suggest Hote Hain', 'AI weather aur occasion ke hisaab se outfit suggest karta hai'),
            const SizedBox(height: 10),
            _buildTipCard(Icons.local_laundry_service, 'Laundry Track Karo', 'Kab dhoya, kab ganda - sab track rakho'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(ClothingItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Recently Added'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Most Worn'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Name'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Color'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
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
