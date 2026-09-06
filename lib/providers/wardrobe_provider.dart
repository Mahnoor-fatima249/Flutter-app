import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/clothing_item.dart';
import '../services/storage_service.dart';
import '../services/object_detection_service.dart';
import '../services/local_ai_service.dart';

class WardrobeProvider extends ChangeNotifier {
  final StorageService _storage;
  final ObjectDetectionService _detectionService;
  final LocalAIService _aiService;

  List<ClothingItem> _wardrobe = [];
  List<ClothingItem> _filteredWardrobe = [];
  ClothingCategory? _selectedCategory;
  ClothingSeason? _selectedSeason;
  OccasionType? _selectedOccasion;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _lastDetectionResult;

  WardrobeProvider({
    required StorageService storage,
    required ObjectDetectionService detectionService,
    required LocalAIService aiService,
  })  : _storage = storage,
        _detectionService = detectionService,
        _aiService = aiService;

  List<ClothingItem> get wardrobe => _filteredWardrobe;
  List<ClothingItem> get allWardrobe => _wardrobe;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get lastDetectionResult => _lastDetectionResult;
  ClothingCategory? get selectedCategory => _selectedCategory;
  ClothingSeason? get selectedSeason => _selectedSeason;
  OccasionType? get selectedOccasion => _selectedOccasion;
  String get searchQuery => _searchQuery;

  int get totalItems => _wardrobe.length;
  Map<String, int> get categoryStats => _storage.getWardrobeStats();
  double get averageWearCount => _storage.getAverageWearCount();
  List<String> get colorDistribution => _storage.getColorDistribution();

  List<ClothingItem> get favorites => _wardrobe.where((i) => i.isFavorite).toList();
  
  List<ClothingItem> get leastWorn => _storage.getLeastWorn(limit: 10);
  
  List<ClothingItem> get recentlyWorn => _storage.getRecentlyWorn(limit: 10);

  void loadWardrobe() {
    _wardrobe = _storage.getWardrobe();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredWardrobe = List.from(_wardrobe);

    if (_selectedCategory != null) {
      _filteredWardrobe = _filteredWardrobe
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    if (_selectedSeason != null) {
      _filteredWardrobe = _filteredWardrobe
          .where((item) =>
              item.seasons.contains(_selectedSeason) ||
              item.seasons.contains(ClothingSeason.allSeason))
          .toList();
    }

    if (_selectedOccasion != null) {
      _filteredWardrobe = _filteredWardrobe
          .where((item) => item.occasions.contains(_selectedOccasion))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredWardrobe = _filteredWardrobe.where((item) {
        return item.name.toLowerCase().contains(lowerQuery) ||
            item.primaryColor.toLowerCase().contains(lowerQuery) ||
            item.category.name.toLowerCase().contains(lowerQuery) ||
            (item.brand?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    notifyListeners();
  }

  void setCategory(ClothingCategory? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setSeason(ClothingSeason? season) {
    _selectedSeason = season;
    _applyFilters();
  }

  void setOccasion(OccasionType? occasion) {
    _selectedOccasion = occasion;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedSeason = null;
    _selectedOccasion = null;
    _searchQuery = '';
    _applyFilters();
  }

  Future<Map<String, dynamic>> detectClothingFromImage(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _detectionService.detectClothing(imageFile);
      _lastDetectionResult = result;
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> analyzeWithAI(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _aiService.analyzeClothingImage(imageFile);
      _lastDetectionResult = result;
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<ClothingItem> addClothingItem({
    required String name,
    required ClothingCategory category,
    required List<String> colors,
    required String primaryColor,
    required List<ClothingSeason> seasons,
    required List<OccasionType> occasions,
    required String imagePath,
    String? brand,
    double? price,
    String? material,
    String? notes,
    Map<String, double>? mlConfidence,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final item = await _storage.addClothingItem(
        name: name,
        category: category,
        colors: colors,
        primaryColor: primaryColor,
        seasons: seasons,
        occasions: occasions,
        imagePath: imagePath,
        brand: brand,
        price: price,
        material: material,
        notes: notes,
        mlConfidence: mlConfidence,
      );

      _wardrobe.add(item);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return item;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateClothingItem(ClothingItem item) async {
    try {
      await _storage.updateClothingItem(item);
      final index = _wardrobe.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _wardrobe[index] = item;
      }
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteClothingItem(String id) async {
    try {
      final item = _wardrobe.firstWhere(
        (i) => i.id == id,
        orElse: () => throw StateError('Item not found'),
      );
      await _storage.deleteImage(item.imagePath);
      await _storage.deleteClothingItem(id);
      _wardrobe.removeWhere((i) => i.id == id);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    final index = _wardrobe.indexWhere((i) => i.id == id);
    if (index != -1) {
      final item = _wardrobe[index];
      final updated = item.copyWith(isFavorite: !item.isFavorite);
      await _storage.updateClothingItem(updated);
      _wardrobe[index] = updated;
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> markAsWorn(String id) async {
    final index = _wardrobe.indexWhere((i) => i.id == id);
    if (index != -1) {
      final item = _wardrobe[index];
      final updated = item.copyWith(
        wearCount: item.wearCount + 1,
        lastWorn: DateTime.now(),
      );
      await _storage.updateClothingItem(updated);
      _wardrobe[index] = updated;
      _applyFilters();
      notifyListeners();
    }
  }

  List<ClothingItem> getCategoryItems(ClothingCategory category) {
    return _wardrobe.where((item) => item.category == category).toList();
  }

  List<ClothingItem> getColorItems(String color) {
    return _wardrobe
        .where((item) => item.colors.any((c) => c.toLowerCase() == color.toLowerCase()))
        .toList();
  }

  int getCategoryCount(ClothingCategory category) {
    return _wardrobe.where((item) => item.category == category).length;
  }
}
