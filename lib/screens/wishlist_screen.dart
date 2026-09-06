import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/wishlist_item.dart';
import '../services/features_service.dart';
import '../theme/app_theme.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final FeaturesService _features = FeaturesService();
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Wishlist',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildWishlistBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final unpurchased = _features.getUnpurchasedItems().length;
    final purchased = _features.getPurchasedItems().length;
    final total = _features.totalWishlistBudget;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Purchased', 'purchased'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Pending', '$unpurchased', AppTheme.warningColor),
              _buildStatItem('Purchased', '$purchased', AppTheme.successColor),
              _buildStatItem(
                'Budget',
                'PKR ${total.toStringAsFixed(0)}',
                AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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

  Widget _buildWishlistBody() {
    List<WishlistItem> items;
    if (_filter == 'pending') {
      items = _features.getUnpurchasedItems();
    } else if (_filter == 'purchased') {
      items = _features.getPurchasedItems();
    } else {
      items = _features.getAllWishlistItems();
    }

    if (items.isEmpty) {
      return Center(
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
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your wishlist is empty',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items you want to buy',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildWishlistCard(items[index]),
    );
  }

  Widget _buildWishlistCard(WishlistItem item) {
    final priorityColor = item.priority == 3
        ? AppTheme.errorColor
        : item.priority == 2
            ? AppTheme.warningColor
            : AppTheme.successColor;

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
        child: Icon(
          item.isPurchased ? Icons.undo : Icons.check,
          color: Colors.white,
        ),
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
          item.isPurchased = !item.isPurchased;
          _features.updateWishlistItem(item);
          setState(() {});
          return false;
        }
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text('Remove ${item.name} from wishlist?'),
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
          _features.deleteWishlistItem(item.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.cardDecoration,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.priorityLabel.substring(0, 1),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: priorityColor,
                ),
              ),
            ),
          ),
          title: Text(
            item.name,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              decoration: item.isPurchased ? TextDecoration.lineThrough : null,
              color: item.isPurchased ? AppTheme.textLight : AppTheme.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.category != null)
                Text(
                  item.category!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              Row(
                children: [
                  if (item.color != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.getColorFromName(item.color!),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (item.budget != null)
                    Text(
                      'PKR ${item.budget!.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isPurchased)
                const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textLight),
            ],
          ),
          onTap: () => _showEditDialog(item),
        ),
      ),
    );
  }

  void _showAddDialog() {
    _showItemDialog();
  }

  void _showEditDialog(WishlistItem item) {
    _showItemDialog(item: item);
  }

  void _showItemDialog({WishlistItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final categoryController = TextEditingController(text: item?.category ?? '');
    final colorController = TextEditingController(text: item?.color ?? '');
    final budgetController = TextEditingController(
      text: item?.budget != null ? item!.budget!.toStringAsFixed(0) : '',
    );
    final notesController = TextEditingController(text: item?.notes ?? '');
    int priority = item?.priority ?? 2;

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
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item != null ? 'Edit Item' : 'Add to Wishlist',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Item name',
                        hintStyle: GoogleFonts.poppins(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        hintText: 'Category (e.g., Shoes, Jacket)',
                        hintStyle: GoogleFonts.poppins(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: colorController,
                            decoration: InputDecoration(
                              hintText: 'Color',
                              hintStyle: GoogleFonts.poppins(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: budgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Budget (PKR)',
                              hintStyle: GoogleFonts.poppins(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        hintText: 'Notes (optional)',
                        hintStyle: GoogleFonts.poppins(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Priority',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityOption(1, 'Low', AppTheme.successColor, priority, setModalState),
                        const SizedBox(width: 8),
                        _buildPriorityOption(2, 'Medium', AppTheme.warningColor, priority, setModalState),
                        const SizedBox(width: 8),
                        _buildPriorityOption(3, 'High', AppTheme.errorColor, priority, setModalState),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: nameController.text.isNotEmpty
                            ? () {
                                final newItem = WishlistItem(
                                  id: item?.id ?? const Uuid().v4(),
                                  name: nameController.text,
                                  category: categoryController.text.isNotEmpty
                                      ? categoryController.text
                                      : null,
                                  color: colorController.text.isNotEmpty
                                      ? colorController.text
                                      : null,
                                  budget: budgetController.text.isNotEmpty
                                      ? double.tryParse(budgetController.text)
                                      : null,
                                  notes: notesController.text.isNotEmpty
                                      ? notesController.text
                                      : null,
                                  priority: priority,
                                  isPurchased: item?.isPurchased ?? false,
                                  createdAt: item?.createdAt ?? DateTime.now(),
                                );
                                if (item != null) {
                                  _features.updateWishlistItem(newItem);
                                } else {
                                  _features.addWishlistItem(newItem);
                                }
                                setState(() {});
                                Navigator.pop(context);
                              }
                            : null,
                        child: Text(
                          item != null ? 'Update' : 'Add Item',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriorityOption(int value, String label, Color color, int current, StateSetter setModalState) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setModalState(() => current = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppTheme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
