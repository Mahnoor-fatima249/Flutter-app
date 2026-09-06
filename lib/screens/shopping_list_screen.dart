import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingItem> _items = [];
  bool _isLoading = true;

  static const String _storageKey = 'shopping_list_items';

  final List<String> _categories = [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
    'Activewear',
    'Formal',
    'Sleepwear',
    'Other',
  ];

  final List<String> _colors = [
    'Black',
    'White',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Purple',
    'Pink',
    'Brown',
    'Grey',
    'Navy',
    'Beige',
    'Cream',
    'Maroon',
    'Teal',
    'Gold',
    'Silver',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _items = jsonList.map((json) => ShoppingItem.fromJson(json)).toList();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _items.map((item) => item.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  int get _totalCount => _items.length;
  int get _boughtCount => _items.where((i) => i.isBought).length;
  int get _remainingCount => _totalCount - _boughtCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Shopping List',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              onPressed: _confirmClearBought,
              icon: const Icon(Icons.cleaning_services_outlined, size: 20),
              tooltip: 'Clear bought items',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryBar(),
                Expanded(child: _buildItemsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Item',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildSummaryStat('Total', _totalCount, AppTheme.primaryColor),
          const SizedBox(width: 12),
          Container(width: 1, height: 36, color: AppTheme.dividerColor),
          const SizedBox(width: 12),
          _buildSummaryStat('Bought', _boughtCount, AppTheme.successColor),
          const SizedBox(width: 12),
          Container(width: 1, height: 36, color: AppTheme.dividerColor),
          const SizedBox(width: 12),
          _buildSummaryStat('Remaining', _remainingCount, AppTheme.warningColor),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    final sortedItems = List<ShoppingItem>.from(_items);
    sortedItems.sort((a, b) {
      if (a.isBought != b.isBought) return a.isBought ? 1 : -1;
      return a.priorityValue.compareTo(b.priorityValue);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildEmptyState() {
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
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No items yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first shopping item',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ShoppingItem item) {
    final priorityColor = _getPriorityColor(item.priority);

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
          item.isBought ? Icons.undo : Icons.check,
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
          _toggleBought(item);
          return false;
        }
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Delete Item',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Remove "${item.name}" from your shopping list?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteItem(item.id);
        }
      },
      child: GestureDetector(
        onLongPress: () => _showDeleteConfirmation(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: priorityColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildPriorityIndicator(priorityColor, item.priority),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: item.isBought
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isBought
                              ? AppTheme.textLight
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.category_outlined,
                            item.category,
                          ),
                          if (item.color.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildColorDot(item.color),
                            const SizedBox(width: 4),
                            Text(
                              item.color,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: item.isBought,
                  onChanged: (_) => _toggleBought(item),
                  activeColor: AppTheme.successColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(Color color, String priority) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          priority[0].toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textLight),
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

  Widget _buildColorDot(String colorName) {
    final color = AppTheme.getColorFromName(colorName);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _toggleBought(ShoppingItem item) {
    setState(() {
      item.isBought = !item.isBought;
    });
    _saveItems();
  }

  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((i) => i.id == id);
    });
    _saveItems();
  }

  void _showDeleteConfirmation(ShoppingItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Item',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Remove "${item.name}" from your shopping list?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              _deleteItem(item.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearBought() {
    if (_boughtCount == 0) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Bought Items',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Remove all $_boughtCount bought items from the list?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _items.removeWhere((i) => i.isBought);
              });
              _saveItems();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog({ShoppingItem? existingItem}) {
    final nameController = TextEditingController(
      text: existingItem?.name ?? '',
    );
    String selectedCategory = existingItem?.category ?? _categories.first;
    String selectedColor = existingItem?.color ?? _colors.first;
    String selectedPriority = existingItem?.priority ?? 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      existingItem != null ? 'Edit Item' : 'Add to Shopping List',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Item Name',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g., White Sneakers',
                        hintStyle: GoogleFonts.poppins(
                          color: AppTheme.textLight,
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedCategory,
                                    isExpanded: true,
                                    items: _categories
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              c,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(
                                          () => selectedCategory = val,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Color',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedColor,
                                    isExpanded: true,
                                    items: _colors
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme
                                                        .getColorFromName(c),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          AppTheme.dividerColor,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  c,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(
                                          () => selectedColor = val,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Priority',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildPriorityChip(
                          'low',
                          'Low',
                          AppTheme.successColor,
                          selectedPriority,
                          setModalState,
                        ),
                        const SizedBox(width: 8),
                        _buildPriorityChip(
                          'medium',
                          'Medium',
                          AppTheme.warningColor,
                          selectedPriority,
                          setModalState,
                        ),
                        const SizedBox(width: 8),
                        _buildPriorityChip(
                          'high',
                          'High',
                          AppTheme.errorColor,
                          selectedPriority,
                          setModalState,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: nameController.text.trim().isNotEmpty
                            ? () {
                                final item = ShoppingItem(
                                  id: existingItem?.id ??
                                      DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString(),
                                  name: nameController.text.trim(),
                                  category: selectedCategory,
                                  color: selectedColor,
                                  priority: selectedPriority,
                                  isBought: existingItem?.isBought ?? false,
                                );
                                if (existingItem != null) {
                                  final idx = _items.indexWhere(
                                    (i) => i.id == existingItem.id,
                                  );
                                  if (idx != -1) _items[idx] = item;
                                } else {
                                  _items.add(item);
                                }
                                _saveItems();
                                setState(() {});
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          existingItem != null ? 'Update Item' : 'Add Item',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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

  Widget _buildPriorityChip(
    String value,
    String label,
    Color color,
    String current,
    StateSetter setModalState,
  ) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setModalState(() => current = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
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

class ShoppingItem {
  final String id;
  final String name;
  final String category;
  final String color;
  final String priority;
  bool isBought;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.priority,
    this.isBought = false,
  });

  String get priorityValue {
    switch (priority) {
      case 'low':
        return '0';
      case 'medium':
        return '1';
      case 'high':
        return '2';
      default:
        return '1';
    }
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Other',
      color: json['color'] as String? ?? 'Black',
      priority: json['priority'] as String? ?? 'medium',
      isBought: json['isBought'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'color': color,
      'priority': priority,
      'isBought': isBought,
    };
  }
}
