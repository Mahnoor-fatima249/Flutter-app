import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/clothing_item.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _wardrobeBox = 'wardrobe';
  static const String _outfitsBox = 'outfits';
  static const String _profileBox = 'profile';
  static const String _settingsBox = 'settings';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<ClothingItem> _wardrobe;
  late Box<Map> _outfits;
  late Box<Map> _profile;
  late Box _settings;
  bool _initialized = false;

  final _uuid = const Uuid();

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(ClothingCategoryAdapter());
    Hive.registerAdapter(ClothingSeasonAdapter());
    Hive.registerAdapter(OccasionTypeAdapter());
    Hive.registerAdapter(ClothingItemAdapter());

    _wardrobe = await Hive.openBox<ClothingItem>(_wardrobeBox);
    _outfits = await Hive.openBox<Map>(_outfitsBox);
    _profile = await Hive.openBox<Map>(_profileBox);
    _settings = await Hive.openBox(_settingsBox);
    _initialized = true;
  }

  List<ClothingItem> getWardrobe() {
    if (!_initialized) return [];
    return _wardrobe.values.toList();
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
    final item = ClothingItem(
      id: _uuid.v4(),
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

    await _wardrobe.put(item.id, item);
    return item;
  }

  Future<void> updateClothingItem(ClothingItem item) async {
    await _wardrobe.put(item.id, item);
  }

  Future<void> deleteClothingItem(String id) async {
    await _wardrobe.delete(id);
  }

  ClothingItem? getClothingItem(String id) {
    return _wardrobe.get(id);
  }

  List<ClothingItem> searchWardrobe(String query) {
    final lowerQuery = query.toLowerCase();
    return _wardrobe.values.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
          item.primaryColor.toLowerCase().contains(lowerQuery) ||
          item.category.name.toLowerCase().contains(lowerQuery) ||
          (item.brand?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  List<ClothingItem> filterByCategory(ClothingCategory category) {
    return _wardrobe.values.where((item) => item.category == category).toList();
  }

  List<ClothingItem> filterBySeason(ClothingSeason season) {
    return _wardrobe.values.where((item) => 
      item.seasons.contains(season) || item.seasons.contains(ClothingSeason.allSeason)
    ).toList();
  }

  List<ClothingItem> filterByOccasion(OccasionType occasion) {
    return _wardrobe.values.where((item) => item.occasions.contains(occasion)).toList();
  }

  List<ClothingItem> getFavorites() {
    return _wardrobe.values.where((item) => item.isFavorite).toList();
  }

  List<ClothingItem> getLeastWorn({int limit = 10}) {
    final sorted = _wardrobe.values.toList()
      ..sort((a, b) => a.wearCount.compareTo(b.wearCount));
    return sorted.take(limit).toList();
  }

  List<ClothingItem> getRecentlyWorn({int limit = 10}) {
    final sorted = _wardrobe.values.where((item) => item.lastWorn != null).toList()
      ..sort((a, b) => b.lastWorn!.compareTo(a.lastWorn!));
    return sorted.take(limit).toList();
  }

  Future<String> saveImage(File imageFile, String folder) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/$folder');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    final fileName = '${_uuid.v4()}.jpg';
    final savedImage = await imageFile.copy('${imagesDir.path}/$fileName');
    return savedImage.path;
  }

  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Profile Photo
  String? getProfilePhoto() {
    if (!_initialized) return null;
    return _settings.get('profile_photo');
  }

  Future<void> saveProfilePhoto(String path) async {
    await _settings.put('profile_photo', path);
  }

  Future<void> deleteProfilePhoto() async {
    await _settings.delete('profile_photo');
  }

  // User Name
  String getUserName() {
    if (!_initialized) return 'Style Enthusiast';
    return _settings.get('user_name', defaultValue: 'Style Enthusiast');
  }

  Future<void> saveUserName(String name) async {
    await _settings.put('user_name', name);
  }

  // User Bio
  String getUserBio() {
    if (!_initialized) return 'Fashion Explorer';
    return _settings.get('user_bio', defaultValue: 'Fashion Explorer');
  }

  Future<void> saveUserBio(String bio) async {
    await _settings.put('user_bio', bio);
  }

  // Custom Home Images
  List<String> getCustomHomeImages() {
    if (!_initialized) return [];
    final images = _settings.get('custom_home_images', defaultValue: <String>[]);
    return List<String>.from(images);
  }

  Future<void> saveCustomHomeImage(String path) async {
    final images = getCustomHomeImages();
    images.add(path);
    await _settings.put('custom_home_images', images);
  }

  Future<void> removeCustomHomeImage(String path) async {
    final images = getCustomHomeImages();
    images.remove(path);
    await _settings.put('custom_home_images', images);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  // Preferred Language
  String getPreferredLanguage() {
    if (!_initialized) return 'english';
    return _settings.get('preferred_language', defaultValue: 'english');
  }

  Future<void> savePreferredLanguage(String lang) async {
    await _settings.put('preferred_language', lang);
  }

  UserProfile? getProfile() {
    final profileData = _profile.get('current');
    if (profileData != null) {
      return UserProfile.fromJson(Map<String, dynamic>.from(profileData));
    }
    return null;
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _profile.put('current', profile.toJson());
  }

  Map<String, dynamic> getSettings() {
    return Map<String, dynamic>.from(_settings.toMap());
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  Map<String, int> getWardrobeStats() {
    final wardrobe = getWardrobe();
    final categoryCount = <String, int>{};
    
    for (final category in ClothingCategory.values) {
      final count = wardrobe.where((item) => item.category == category).length;
      if (count > 0) {
        categoryCount[category.name] = count;
      }
    }
    
    return categoryCount;
  }

  double getAverageWearCount() {
    final wardrobe = getWardrobe();
    if (wardrobe.isEmpty) return 0;
    
    final total = wardrobe.fold(0, (sum, item) => sum + item.wearCount);
    return total / wardrobe.length;
  }

  List<String> getColorDistribution() {
    final wardrobe = getWardrobe();
    final colorCount = <String, int>{};
    
    for (final item in wardrobe) {
      for (final color in item.colors) {
        colorCount[color] = (colorCount[color] ?? 0) + 1;
      }
    }
    
    final sorted = colorCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.map((e) => e.key).toList();
  }

  // ==================== NOTIFICATIONS ====================

  List<Map<String, dynamic>> getNotifications() {
    if (!_initialized) return [];
    final notifications = _settings.get('notifications', defaultValue: <Map>[]);
    return List<Map>.from(notifications).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  int getUnreadNotificationCount() {
    final notifications = getNotifications();
    return notifications.where((n) => n['read'] == false).length;
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final notifications = getNotifications();
    notifications.insert(0, {
      'id': _uuid.v4(),
      'title': title,
      'message': message,
      'type': type,
      'read': false,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }
    await _settings.put('notifications', notifications);
  }

  Future<void> markNotificationAsRead(String id) async {
    final notifications = getNotifications();
    final index = notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notifications[index]['read'] = true;
      await _settings.put('notifications', notifications);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final notifications = getNotifications();
    for (final n in notifications) {
      n['read'] = true;
    }
    await _settings.put('notifications', notifications);
  }

  Future<void> clearNotifications() async {
    await _settings.put('notifications', <Map>[]);
  }

  String getLastSeenVersion() {
    if (!_initialized) return '0.0.0';
    return _settings.get('last_seen_version', defaultValue: '0.0.0');
  }

  Future<void> saveLastSeenVersion(String version) async {
    await _settings.put('last_seen_version', version);
  }

  // ==================== OUTFIT OF THE DAY ====================

  String? getOutfitOfDayDate() {
    if (!_initialized) return null;
    return _settings.get('ootd_date');
  }

  List<String> getOutfitOfDayIds() {
    if (!_initialized) return [];
    final ids = _settings.get('ootd_ids', defaultValue: <String>[]);
    return List<String>.from(ids);
  }

  Future<void> saveOutfitOfDay(String date, List<String> itemIds) async {
    await _settings.put('ootd_date', date);
    await _settings.put('ootd_ids', itemIds);
  }
}
