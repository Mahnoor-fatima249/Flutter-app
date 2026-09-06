import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SizeTrackerScreen extends StatefulWidget {
  const SizeTrackerScreen({super.key});

  @override
  State<SizeTrackerScreen> createState() => _SizeTrackerScreenState();
}

class _SizeTrackerScreenState extends State<SizeTrackerScreen> {
  final Map<String, TextEditingController> _controllers = {
    'chest': TextEditingController(),
    'waist': TextEditingController(),
    'hips': TextEditingController(),
    'inseam': TextEditingController(),
    'shoulders': TextEditingController(),
    'neck': TextEditingController(),
    'sleeveLength': TextEditingController(),
  };

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String _selectedUnit = 'inches';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('size_tracker_history');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _history = decoded.cast<Map<String, dynamic>>();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveMeasurements() async {
    final measurements = <String, double>{};
    for (final entry in _controllers.entries) {
      final value = double.tryParse(entry.value.text);
      if (value == null || value <= 0) {
        _showSnackBar('Please fill in all measurement fields with valid numbers.');
        return;
      }
      measurements[entry.key] = value;
    }

    final entry = {
      'date': DateTime.now().toIso8601String(),
      'unit': _selectedUnit,
      'measurements': measurements,
      'size': _calculateSize(measurements),
    };

    setState(() => _history.insert(0, entry));
    await _saveToPrefs();

    for (final controller in _controllers.values) {
      controller.clear();
    }

    _showSnackBar('Measurements saved successfully!');
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('size_tracker_history', jsonEncode(_history));
  }

  Future<void> _deleteEntry(int index) async {
    setState(() => _history.removeAt(index));
    await _saveToPrefs();
    _showSnackBar('Entry deleted.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _calculateSize(Map<String, double> m) {
    final chest = _toInches(m['chest'] ?? 0);
    final waist = _toInches(m['waist'] ?? 0);
    final hips = _toInches(m['hips'] ?? 0);

    if (chest < 36 && waist < 30 && hips < 38) return 'S';
    if (chest < 40 && waist < 34 && hips < 42) return 'M';
    if (chest < 44 && waist < 38 && hips < 46) return 'L';
    if (chest < 48 && waist < 42 && hips < 50) return 'XL';
    return 'XXL';
  }

  double _toInches(double value) {
    return _selectedUnit == 'cm' ? value / 2.54 : value;
  }

  Map<String, String> get _measurementLabels => {
        'chest': 'Chest',
        'waist': 'Waist',
        'hips': 'Hips',
        'inseam': 'Inseam',
        'shoulders': 'Shoulders',
        'neck': 'Neck',
        'sleeveLength': 'Sleeve Length',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Size Tracker',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildInputCard(),
                  const SizedBox(height: 20),
                  _buildRecommendationCard(),
                  const SizedBox(height: 20),
                  _buildSizeChartCard(),
                  const SizedBox(height: 20),
                  _buildHistoryHeader(),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    _buildEmptyState()
                  else
                    _buildHistoryList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Your Size',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Save & monitor your body measurements',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.straighten,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'New Measurements',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              _buildUnitToggle(),
            ],
          ),
          const SizedBox(height: 16),
          ..._measurementLabels.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTextField(
                entry.value,
                _controllers[entry.key]!,
                _selectedUnit == 'cm' ? 'cm' : 'in',
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveMeasurements,
              icon: const Icon(Icons.save, size: 20),
              label: Text(
                'Save Measurements',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          _buildUnitButton('inches', 'In'),
          _buildUnitButton('cm', 'Cm'),
        ],
      ),
    );
  }

  Widget _buildUnitButton(String unit, String label) {
    final isSelected = _selectedUnit == unit;
    return GestureDetector(
      onTap: () => setState(() => _selectedUnit = unit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String suffix) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        hintStyle: GoogleFonts.poppins(color: AppTheme.textLight),
        labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
      ),
      style: GoogleFonts.poppins(color: AppTheme.textPrimary),
    );
  }

  Widget _buildRecommendationCard() {
    if (_history.isEmpty) return const SizedBox.shrink();

    final latest = _history.first;
    final size = latest['size'] as String;
    final measurements = latest['measurements'] as Map<String, dynamic>;
    final date = DateTime.parse(latest['date'] as String);

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Recommended Size',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                size,
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on your latest measurements from ${_formatDate(date)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Measurements:',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: measurements.entries.map((entry) {
              final unit = latest['unit'] == 'cm' ? 'cm' : 'in';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_measurementLabels[entry.key]}: ${entry.value}$unit',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeChartCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart_outlined, color: AppTheme.accentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Size Chart Reference',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Standard measurements in inches',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildSizeChartTable(),
        ],
      ),
    );
  }

  Widget _buildSizeChartTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
        headingTextStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
        ),
        dataTextStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: AppTheme.textPrimary,
        ),
        columns: const [
          DataColumn(label: Text('Size')),
          DataColumn(label: Text('Chest')),
          DataColumn(label: Text('Waist')),
          DataColumn(label: Text('Hips')),
        ],
        rows: [
          _sizeRow('S', '34-36', '28-30', '36-38'),
          _sizeRow('M', '38-40', '32-34', '40-42'),
          _sizeRow('L', '42-44', '36-38', '44-46'),
          _sizeRow('XL', '46-48', '40-42', '48-50'),
          _sizeRow('XXL', '50-52', '44-46', '52-54'),
        ],
      ),
    );
  }

  DataRow _sizeRow(String size, String chest, String waist, String hips) {
    final latest = _history.isNotEmpty ? _history.first['size'] : null;
    final isRecommended = latest == size;
    return DataRow(
      color: isRecommended
          ? WidgetStateProperty.all(AppTheme.primaryColor.withOpacity(0.08))
          : null,
      cells: [
        DataCell(
          Text(
            size,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isRecommended ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
          ),
        ),
        DataCell(Text(chest)),
        DataCell(Text(waist)),
        DataCell(Text(hips)),
      ],
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        Icon(Icons.history, color: AppTheme.secondaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          'Measurement History',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        if (_history.isNotEmpty)
          TextButton(
            onPressed: _confirmClearHistory,
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
          Icon(
            Icons.straighten_outlined,
            size: 48,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No measurements yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your measurements above to get started',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Column(
      children: List.generate(_history.length, (index) {
        final entry = _history[index];
        final date = DateTime.parse(entry['date'] as String);
        final size = entry['size'] as String;
        final unit = entry['unit'] as String;
        final measurements = entry['measurements'] as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      size,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDate(date),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (index == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Latest',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(index),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: measurements.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_measurementLabels[e.key]}: ${e.value}$unit',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Entry?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This measurement entry will be permanently removed.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteEntry(index);
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear All History?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'All measurement history will be permanently deleted.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _history.clear());
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('size_tracker_history');
              _showSnackBar('History cleared.');
            },
            child: Text('Clear All', style: GoogleFonts.poppins(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
