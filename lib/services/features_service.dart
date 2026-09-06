import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/outfit_calendar.dart';
import '../models/wishlist_item.dart';
import '../models/laundry_item.dart';
import '../models/budget_item.dart';
import '../models/travel_plan.dart';
import '../models/style_dna.dart';
import '../models/outfit_history.dart';

class FeaturesService {
  static const String _calendarBox = 'outfit_calendar';
  static const String _wishlistBox = 'wishlist';
  static const String _laundryBox = 'laundry';
  static const String _budgetBox = 'budget';
  static const String _travelBox = 'travel';
  static const String _styleDnaBox = 'style_dna';
  static const String _historyBox = 'outfit_history';
  static const String _settingsBox = 'features_settings';

  static final FeaturesService _instance = FeaturesService._internal();
  factory FeaturesService() => _instance;
  FeaturesService._internal();

  late Box<OutfitCalendar> _calendar;
  late Box<WishlistItem> _wishlist;
  late Box<LaundryItem> _laundry;
  late Box<BudgetItem> _budget;
  late Box<TravelPlan> _travel;
  late Box<StyleDNA> _styleDna;
  late Box<OutfitHistory> _history;
  late Box _settings;
  bool _initialized = false;

  final _uuid = const Uuid();

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    Hive.registerAdapter(OutfitCalendarAdapter());
    Hive.registerAdapter(WishlistItemAdapter());
    Hive.registerAdapter(LaundryItemAdapter());
    Hive.registerAdapter(BudgetItemAdapter());
    Hive.registerAdapter(TravelPlanAdapter());
    Hive.registerAdapter(StyleDNAAdapter());
    Hive.registerAdapter(OutfitHistoryAdapter());

    _calendar = await Hive.openBox<OutfitCalendar>(_calendarBox);
    _wishlist = await Hive.openBox<WishlistItem>(_wishlistBox);
    _laundry = await Hive.openBox<LaundryItem>(_laundryBox);
    _budget = await Hive.openBox<BudgetItem>(_budgetBox);
    _travel = await Hive.openBox<TravelPlan>(_travelBox);
    _styleDna = await Hive.openBox<StyleDNA>(_styleDnaBox);
    _history = await Hive.openBox<OutfitHistory>(_historyBox);
    _settings = await Hive.openBox(_settingsBox);
    _initialized = true;
  }

  // ==================== CALENDAR ====================

  List<OutfitCalendar> getAllCalendarEntries() {
    if (!_initialized) return [];
    return _calendar.values.toList();
  }

  OutfitCalendar? getCalendarEntry(DateTime date) {
    final key = _dateKey(date);
    return _calendar.get(key);
  }

  List<OutfitCalendar> getCalendarEntriesForWeek(DateTime weekStart) {
    final entries = <OutfitCalendar>[];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final entry = getCalendarEntry(date);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  Future<void> addCalendarEntry(OutfitCalendar entry) async {
    final key = _dateKey(entry.date);
    await _calendar.put(key, entry);
  }

  Future<void> updateCalendarEntry(OutfitCalendar entry) async {
    final key = _dateKey(entry.date);
    await _calendar.put(key, entry);
  }

  Future<void> deleteCalendarEntry(DateTime date) async {
    final key = _dateKey(date);
    await _calendar.delete(key);
  }

  // ==================== WISHLIST ====================

  List<WishlistItem> getAllWishlistItems() {
    if (!_initialized) return [];
    return _wishlist.values.toList();
  }

  List<WishlistItem> getUnpurchasedItems() {
    return _wishlist.values.where((item) => !item.isPurchased).toList();
  }

  List<WishlistItem> getPurchasedItems() {
    return _wishlist.values.where((item) => item.isPurchased).toList();
  }

  Future<void> addWishlistItem(WishlistItem item) async {
    await _wishlist.put(item.id, item);
  }

  Future<void> updateWishlistItem(WishlistItem item) async {
    await _wishlist.put(item.id, item);
  }

  Future<void> deleteWishlistItem(String id) async {
    await _wishlist.delete(id);
  }

  WishlistItem? getWishlistItem(String id) {
    return _wishlist.get(id);
  }

  double get totalWishlistBudget {
    return getUnpurchasedItems().fold(0.0, (sum, item) => sum + (item.budget ?? 0));
  }

  // ==================== LAUNDRY ====================

  List<LaundryItem> getAllLaundryItems() {
    if (!_initialized) return [];
    return _laundry.values.toList();
  }

  LaundryItem? getLaundryItem(String clothingItemId) {
    return _laundry.get(clothingItemId);
  }

  Future<void> addLaundryItem(LaundryItem item) async {
    await _laundry.put(item.clothingItemId, item);
  }

  Future<void> markAsWashed(String clothingItemId) async {
    final existing = _laundry.get(clothingItemId);
    if (existing != null) {
      existing.lastWashed = DateTime.now();
      existing.washCount = existing.washCount + 1;
      existing.nextWashDate = DateTime.now().add(const Duration(days: 7));
      await _laundry.put(clothingItemId, existing);
    } else {
      final item = LaundryItem(
        clothingItemId: clothingItemId,
        lastWashed: DateTime.now(),
        washCount: 1,
        nextWashDate: DateTime.now().add(const Duration(days: 7)),
      );
      await _laundry.put(clothingItemId, item);
    }
  }

  Future<void> updateLaundryItem(LaundryItem item) async {
    await _laundry.put(item.clothingItemId, item);
  }

  Future<void> deleteLaundryItem(String clothingItemId) async {
    await _laundry.delete(clothingItemId);
  }

  List<LaundryItem> getItemsNeedingWash() {
    return _laundry.values.where((item) => item.needsWashing || item.daysSinceLastWash > 5).toList();
  }

  // ==================== BUDGET ====================

  List<BudgetItem> getAllBudgetItems() {
    if (!_initialized) return [];
    return _budget.values.toList();
  }

  List<BudgetItem> getMonthlyExpenses(DateTime month) {
    return _budget.values.where((item) =>
      item.date.year == month.year && item.date.month == month.month
    ).toList();
  }

  Future<void> addBudgetItem(BudgetItem item) async {
    await _budget.put(item.id, item);
  }

  Future<void> updateBudgetItem(BudgetItem item) async {
    await _budget.put(item.id, item);
  }

  Future<void> deleteBudgetItem(String id) async {
    await _budget.delete(id);
  }

  double getMonthlyTotal(DateTime month) {
    return getMonthlyExpenses(month).fold(0.0, (sum, item) => sum + item.amount);
  }

  double getMonthlyBudget() {
    return _settings.get('monthly_budget', defaultValue: 5000.0);
  }

  Future<void> setMonthlyBudget(double amount) async {
    await _settings.put('monthly_budget', amount);
  }

  Map<String, double> getCategoryWiseExpenses(DateTime month) {
    final expenses = <String, double>{};
    for (final item in getMonthlyExpenses(month)) {
      expenses[item.category] = (expenses[item.category] ?? 0) + item.amount;
    }
    return expenses;
  }

  // ==================== TRAVEL ====================

  List<TravelPlan> getAllTravelPlans() {
    if (!_initialized) return [];
    return _travel.values.toList();
  }

  Future<void> addTravelPlan(TravelPlan plan) async {
    await _travel.put(plan.id, plan);
  }

  Future<void> updateTravelPlan(TravelPlan plan) async {
    await _travel.put(plan.id, plan);
  }

  Future<void> deleteTravelPlan(String id) async {
    await _travel.delete(id);
  }

  TravelPlan? getTravelPlan(String id) {
    return _travel.get(id);
  }

  // ==================== STYLE DNA ====================

  StyleDNA? getStyleDNA() {
    if (!_initialized) return null;
    return _styleDna.get('current');
  }

  Future<void> saveStyleDNA(StyleDNA dna) async {
    await _styleDna.put('current', dna);
  }

  // ==================== OUTFIT HISTORY ====================

  List<OutfitHistory> getAllHistory() {
    if (!_initialized) return [];
    final list = _history.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<OutfitHistory> getHistoryForMonth(DateTime month) {
    return getAllHistory().where((item) =>
      item.date.year == month.year && item.date.month == month.month
    ).toList();
  }

  Future<void> addHistoryEntry(OutfitHistory entry) async {
    await _history.put(entry.id, entry);
  }

  Future<void> updateHistoryEntry(OutfitHistory entry) async {
    await _history.put(entry.id, entry);
  }

  Future<void> deleteHistoryEntry(String id) async {
    await _history.delete(id);
  }

  // ==================== STYLE SCORE ====================

  int calculateWeeklyScore() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int score = 0;

    final weekHistory = getAllHistory().where((h) =>
      h.date.isAfter(weekStart.subtract(const Duration(days: 1)))
    ).toList();
    final uniqueItems = <String>{};
    for (final h in weekHistory) {
      uniqueItems.addAll(h.itemIds);
    }
    if (uniqueItems.length >= 3) score += 20;
    else if (uniqueItems.length >= 2) score += 10;

    final laundryClean = getAllLaundryItems().where((l) => l.daysSinceLastWash < 7).length;
    score += (laundryClean * 2).clamp(0, 20);

    final wardrobeSize = _settings.get('wardrobe_size', defaultValue: 0) as int;
    if (wardrobeSize >= 20) score += 20;
    else if (wardrobeSize >= 10) score += 10;

    final purchased = getPurchasedItems().length;
    if (purchased >= 3) score += 20;
    else if (purchased >= 1) score += 10;

    final plannedOutfits = getAllCalendarEntries().where((c) => c.isCompleted).length;
    if (plannedOutfits >= 5) score += 20;
    else if (plannedOutfits >= 3) score += 10;

    return score.clamp(0, 100);
  }

  // ==================== HELPER ====================

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
