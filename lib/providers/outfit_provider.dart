import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/user_profile.dart';
import '../services/local_ai_service.dart';
import '../services/local_weather_service.dart';
import 'wardrobe_provider.dart';

class OutfitProvider extends ChangeNotifier {
  static const String _boxName = 'outfit_provider';
  static const String _savedOutfitsKey = 'savedOutfits';
  static const String _outfitHistoryKey = 'outfitHistory';

  final LocalAIService _aiService;
  final LocalWeatherService _weatherService;
  final WardrobeProvider _wardrobeProvider;
  late Box _box;

  List<Outfit> _suggestedOutfits = [];
  List<Outfit> _savedOutfits = [];
  List<Outfit> _outfitHistory = [];
  WeatherData? _currentWeather;
  bool _isLoading = false;
  String? _error;
  OccasionType _selectedOccasion = OccasionType.casual;

  OutfitProvider({
    required LocalAIService aiService,
    required LocalWeatherService weatherService,
    required WardrobeProvider wardrobeProvider,
  })  : _aiService = aiService,
        _weatherService = weatherService,
        _wardrobeProvider = wardrobeProvider;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _loadSavedOutfits();
    _loadOutfitHistory();
  }

  void _loadSavedOutfits() {
    final data = _box.get(_savedOutfitsKey);
    if (data != null && data is List) {
      _savedOutfits = data
          .map((e) => Outfit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  void _loadOutfitHistory() {
    final data = _box.get(_outfitHistoryKey);
    if (data != null && data is List) {
      _outfitHistory = data
          .map((e) => Outfit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  List<Outfit> get suggestedOutfits => _suggestedOutfits;
  List<Outfit> get savedOutfits => _savedOutfits;
  List<Outfit> get outfitHistory => _outfitHistory;
  WeatherData? get currentWeather => _currentWeather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OccasionType get selectedOccasion => _selectedOccasion;

  String get weatherAdvice {
    if (_currentWeather == null) return 'Weather data load karein';
    return _weatherService.getWeatherAdvice(_currentWeather!);
  }

  void setOccasion(OccasionType occasion) {
    _selectedOccasion = occasion;
    notifyListeners();
  }

  String _cleanError(String error) {
    if (error.contains('Exception:')) {
      error = error.replaceFirst('Exception: ', '').replaceFirst('Exception: ', '');
    }
    return error;
  }

  Future<void> fetchWeather(double latitude, double longitude) async {
    try {
      _currentWeather = await _weatherService.getWeather(latitude, longitude);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _cleanError(e.toString());
      notifyListeners();
    }
  }

  Future<void> fetchWeatherByCity(String city) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentWeather = await _weatherService.getWeatherByCity(city);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _cleanError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateOutfitSuggestions() async {
    final wardrobe = _wardrobeProvider.allWardrobe;
    if (wardrobe.isEmpty) {
      _error = 'Pehle wardrobe mein items add karein';
      notifyListeners();
      return;
    }

    if (_currentWeather == null) {
      _error = 'Weather data chahiye suggestions ke liye';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _suggestedOutfits = await _aiService.suggestOutfits(
        wardrobe: wardrobe,
        weather: _currentWeather!,
        occasion: _selectedOccasion,
        count: 5,
      );
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _cleanError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveOutfit(Outfit outfit) async {
    final updated = outfit.copyWith(isSaved: true);
    _savedOutfits.add(updated);
    _box.put(_savedOutfitsKey, _savedOutfits.map((o) => o.toJson()).toList());
    
    for (final item in updated.items) {
      await _wardrobeProvider.markAsWorn(item.id);
    }
    
    notifyListeners();
  }

  void removeSavedOutfit(String outfitId) {
    _savedOutfits.removeWhere((o) => o.id == outfitId);
    _box.put(_savedOutfitsKey, _savedOutfits.map((o) => o.toJson()).toList());
    notifyListeners();
  }

  void addToHistory(Outfit outfit) {
    _outfitHistory.insert(0, outfit);
    if (_outfitHistory.length > 50) {
      _outfitHistory = _outfitHistory.sublist(0, 50);
    }
    _box.put(_outfitHistoryKey, _outfitHistory.map((o) => o.toJson()).toList());
    notifyListeners();
  }

  List<Outfit> getOutfitsForOccasion(OccasionType occasion) {
    return _savedOutfits.where((o) => o.occasion == occasion).toList();
  }

  List<Outfit> getOutfitsForSeason(ClothingSeason season) {
    return _savedOutfits.where((o) => o.season == season).toList();
  }

  Outfit? getOutfitById(String id) {
    try {
      return _savedOutfits.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<OccasionType, int> getOccasionDistribution() {
    final distribution = <OccasionType, int>{};
    for (final outfit in _savedOutfits) {
      distribution[outfit.occasion] = (distribution[outfit.occasion] ?? 0) + 1;
    }
    return distribution;
  }
}
