import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/clothing_item.dart';
import '../models/travel_plan.dart';
import '../services/storage_service.dart';
import '../services/features_service.dart';
import '../theme/app_theme.dart';

class TravelPlannerScreen extends StatefulWidget {
  const TravelPlannerScreen({super.key});

  @override
  State<TravelPlannerScreen> createState() => _TravelPlannerScreenState();
}

class _TravelPlannerScreenState extends State<TravelPlannerScreen> {
  final FeaturesService _features = FeaturesService();
  final StorageService _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Travel Planner',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlanDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    final plans = _features.getAllTravelPlans();

    if (plans.isEmpty) {
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
                Icons.flight_takeoff,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No trips planned',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan your trips and pack outfits',
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
      itemCount: plans.length,
      itemBuilder: (context, index) => _buildPlanCard(plans[index]),
    );
  }

  Widget _buildPlanCard(TravelPlan plan) {
    final daysLeft = plan.startDate.difference(DateTime.now()).inDays;
    final isPast = plan.endDate.isBefore(DateTime.now());
    final isUpcoming = plan.startDate.isAfter(DateTime.now());

    return GestureDetector(
      onTap: () => _showPlanDetail(plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isPast
                    ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600])
                    : isUpcoming
                        ? AppTheme.primaryGradient
                        : AppTheme.secondaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flight, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.destination,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${plan.startDate.day}/${plan.startDate.month} - ${plan.endDate.day}/${plan.endDate.month}/${plan.endDate.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpcoming)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$daysLeft days left',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPlanStat(
                    '${plan.tripLength}',
                    'Days',
                    Icons.calendar_today,
                    AppTheme.primaryColor,
                  ),
                  _buildPlanStat(
                    '${plan.itemIds.length}',
                    'Items',
                    Icons.checkroom,
                    AppTheme.secondaryColor,
                  ),
                  _buildPlanStat(
                    '${plan.weather ?? 'Any'}',
                    'Weather',
                    Icons.wb_sunny,
                    AppTheme.accentColor,
                  ),
                ],
              ),
            ),
            if (plan.notes != null && plan.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  plan.notes!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
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

  void _showPlanDetail(TravelPlan plan) {
    final wardrobe = _storage.getWardrobe();
    final packedItems = wardrobe.where((item) => plan.itemIds.contains(item.id)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan.destination,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
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
                          Navigator.pop(context);
                          if (value == 'edit') {
                            _showAddPlanDialog(plan: plan);
                          } else if (value == 'delete') {
                            _features.deleteTravelPlan(plan.id);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${plan.startDate.day}/${plan.startDate.month} - ${plan.endDate.day}/${plan.endDate.month} (${plan.tripLength} days)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (plan.weather != null)
                    Text(
                      'Expected weather: ${plan.weather}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Packed Items (${packedItems.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: packedItems.isEmpty
                        ? Center(
                            child: Text(
                              'No items packed yet',
                              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: packedItems.length,
                            itemBuilder: (context, index) {
                              final item = packedItems[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.getColorFromName(item.primaryColor)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(item.category),
                                    color: AppTheme.getColorFromName(item.primaryColor),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '${item.category.name} - ${item.primaryColor}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPlanDialog({TravelPlan? plan}) {
    final destController = TextEditingController(text: plan?.destination ?? '');
    final notesController = TextEditingController(text: plan?.notes ?? '');
    final weatherController = TextEditingController(text: plan?.weather ?? '');
    DateTime startDate = plan?.startDate ?? DateTime.now();
    DateTime endDate = plan?.endDate ?? DateTime.now().add(const Duration(days: 3));
    Set<String> selectedIds = Set<String>.from(plan?.itemIds ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan != null ? 'Edit Trip' : 'Plan a Trip',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: destController,
                        decoration: InputDecoration(
                          hintText: 'Destination',
                          hintStyle: GoogleFonts.poppins(),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateButton(
                              'Start: ${startDate.day}/${startDate.month}',
                              () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) setModalState(() => startDate = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDateButton(
                              'End: ${endDate.day}/${endDate.month}',
                              () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) setModalState(() => endDate = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weatherController,
                        decoration: InputDecoration(
                          hintText: 'Expected weather (e.g., Hot, Cold)',
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
                      const SizedBox(height: 16),
                      Text(
                        'Pack Items',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _storage.getWardrobe().length,
                          itemBuilder: (context, index) {
                            final item = _storage.getWardrobe()[index];
                            final isSelected = selectedIds.contains(item.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setModalState(() {
                                  if (value == true) {
                                    selectedIds.add(item.id);
                                  } else {
                                    selectedIds.remove(item.id);
                                  }
                                });
                              },
                              title: Text(
                                item.name,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${item.category.name} - ${item.primaryColor}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              secondary: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.getColorFromName(item.primaryColor)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(item.category),
                                  color: AppTheme.getColorFromName(item.primaryColor),
                                  size: 18,
                                ),
                              ),
                              activeColor: AppTheme.primaryColor,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: destController.text.isNotEmpty
                              ? () {
                                  final newPlan = TravelPlan(
                                    id: plan?.id ?? const Uuid().v4(),
                                    destination: destController.text,
                                    startDate: startDate,
                                    endDate: endDate,
                                    itemIds: selectedIds.toList(),
                                    notes: notesController.text.isNotEmpty
                                        ? notesController.text
                                        : null,
                                    weather: weatherController.text.isNotEmpty
                                        ? weatherController.text
                                        : null,
                                  );
                                  if (plan != null) {
                                    _features.updateTravelPlan(newPlan);
                                  } else {
                                    _features.addTravelPlan(newPlan);
                                  }
                                  setState(() {});
                                  Navigator.pop(context);
                                }
                              : null,
                          child: Text(
                            plan != null ? 'Update Trip' : 'Save Trip',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDateButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
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
