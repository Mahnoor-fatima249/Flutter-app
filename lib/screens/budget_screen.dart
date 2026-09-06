import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_item.dart';
import '../services/features_service.dart';
import '../theme/app_theme.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final FeaturesService _features = FeaturesService();
  late DateTime _currentMonth;
  double _monthlyBudget = 5000;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _monthlyBudget = _features.getMonthlyBudget();
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = _features.getMonthlyTotal(_currentMonth);
    final remaining = _monthlyBudget - totalSpent;
    final percentage = _monthlyBudget > 0 ? (totalSpent / _monthlyBudget).clamp(0.0, 1.0) : 0.0;
    final categoryExpenses = _features.getCategoryWiseExpenses(_currentMonth);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Kharcha Ka Hisab',
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
            onPressed: _showBudgetSettings,
            icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthNavigator(),
            const SizedBox(height: 16),
            _buildBudgetOverview(totalSpent, remaining, percentage),
            const SizedBox(height: 20),
            if (categoryExpenses.isNotEmpty) ...[
              Text(
                'Expenses by Category',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildPieChart(categoryExpenses, totalSpent),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Expenses',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddExpenseDialog(),
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildExpensesList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
          ),
          Text(
            '${months[_currentMonth.month - 1]} ${_currentMonth.year}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetOverview(double totalSpent, double remaining, double percentage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Monthly Budget',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PKR ${_monthlyBudget.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 0.9 ? AppTheme.errorColor : Colors.white,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem('Spent', 'PKR ${totalSpent.toStringAsFixed(0)}'),
              _buildOverviewItem('Remaining', 'PKR ${remaining.toStringAsFixed(0)}'),
              _buildOverviewItem('Used', '${(percentage * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> categoryExpenses, double total) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.warningColor,
      AppTheme.successColor,
      const Color(0xFF8B5CF6),
      const Color(0xFFF97316),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: categoryExpenses.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value.key;
                  final amount = entry.value.value;
                  final percentage = (amount / total * 100).toStringAsFixed(1);

                  return PieChartSectionData(
                    value: amount,
                    color: colors[index % colors.length],
                    radius: 50,
                    title: '$percentage%',
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: categoryExpenses.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value.key;
              final amount = entry.value.value;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$category (PKR ${amount.toStringAsFixed(0)})',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    final expenses = _features.getMonthlyExpenses(_currentMonth);

    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: AppTheme.cardDecoration,
        child: Center(
          child: Text(
            'No expenses this month',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: expenses.map((expense) => _buildExpenseCard(expense)).toList(),
    );
  }

  Widget _buildExpenseCard(BudgetItem expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shopping_bag,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          expense.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          '${expense.category} - ${expense.date.day}/${expense.date.month}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PKR ${expense.amount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit', style: GoogleFonts.poppins()),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: GoogleFonts.poppins(color: AppTheme.errorColor)),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddExpenseDialog(item: expense);
                } else if (value == 'delete') {
                  _features.deleteBudgetItem(expense.id);
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog({BudgetItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final amountController = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(0) : '',
    );
    final categoryController = TextEditingController(text: item?.category ?? '');
    final notesController = TextEditingController(text: item?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  item != null ? 'Edit Expense' : 'Add Expense',
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
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Amount (PKR)',
                    hintStyle: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    hintText: 'Category (e.g., Tops, Shoes)',
                    hintStyle: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    hintText: 'Notes (optional)',
                    hintStyle: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: nameController.text.isNotEmpty && amountController.text.isNotEmpty
                        ? () {
                            final amount = double.tryParse(amountController.text) ?? 0;
                            if (amount <= 0) return;

                            final newItem = BudgetItem(
                              id: item?.id ?? const Uuid().v4(),
                              name: nameController.text,
                              amount: amount,
                              category: categoryController.text.isNotEmpty
                                  ? categoryController.text
                                  : 'Other',
                              date: item?.date ?? DateTime.now(),
                              notes: notesController.text.isNotEmpty
                                  ? notesController.text
                                  : null,
                            );

                            if (item != null) {
                              _features.updateBudgetItem(newItem);
                            } else {
                              _features.addBudgetItem(newItem);
                            }
                            setState(() {});
                            Navigator.pop(context);
                          }
                        : null,
                    child: Text(
                      item != null ? 'Update' : 'Add Expense',
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
  }

  void _showBudgetSettings() {
    final budgetController = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget Settings',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Monthly Budget (PKR)',
                  hintStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final budget = double.tryParse(budgetController.text) ?? 5000;
                    _features.setMonthlyBudget(budget);
                    setState(() => _monthlyBudget = budget);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
