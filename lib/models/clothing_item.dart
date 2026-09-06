import 'package:hive/hive.dart';

part 'clothing_item.g.dart';

@HiveType(typeId: 0)
enum ClothingCategory {
  @HiveField(0) tops,
  @HiveField(1) bottoms,
  @HiveField(2) outerwear,
  @HiveField(3) dresses,
  @HiveField(4) footwear,
  @HiveField(5) accessories,
  @HiveField(6) activewear,
  @HiveField(7) formal,
}

@HiveType(typeId: 1)
enum ClothingSeason {
  @HiveField(0) spring,
  @HiveField(1) summer,
  @HiveField(2) autumn,
  @HiveField(3) winter,
  @HiveField(4) allSeason,
}

@HiveType(typeId: 2)
enum OccasionType {
  @HiveField(0) casual,
  @HiveField(1) formal,
  @HiveField(2) sporty,
  @HiveField(3) party,
  @HiveField(4) work,
  @HiveField(5) date,
  @HiveField(6) outdoor,
}

@HiveType(typeId: 3)
class ClothingItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  ClothingCategory category;

  @HiveField(3)
  List<String> colors;

  @HiveField(4)
  String primaryColor;

  @HiveField(5)
  List<ClothingSeason> seasons;

  @HiveField(6)
  List<OccasionType> occasions;

  @HiveField(7)
  String imagePath;

  @HiveField(8)
  String? brand;

  @HiveField(9)
  DateTime dateAdded;

  @HiveField(10)
  int wearCount;

  @HiveField(11)
  DateTime? lastWorn;

  @HiveField(12)
  bool isFavorite;

  @HiveField(13)
  double? price;

  @HiveField(14)
  String? material;

  @HiveField(15)
  String? notes;

  @HiveField(16)
  Map<String, double>? mlConfidence;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.colors,
    required this.primaryColor,
    required this.seasons,
    required this.occasions,
    required this.imagePath,
    this.brand,
    DateTime? dateAdded,
    this.wearCount = 0,
    this.lastWorn,
    this.isFavorite = false,
    this.price,
    this.material,
    this.notes,
    this.mlConfidence,
  }) : dateAdded = dateAdded ?? DateTime.now();

  double get freshnessScore {
    if (lastWorn == null) return 1.0;
    final daysSinceWorn = DateTime.now().difference(lastWorn!).inDays;
    if (daysSinceWorn >= 30) return 1.0;
    return 1.0 - (daysSinceWorn / 30.0);
  }

  String get seasonLabel {
    if (seasons.contains(ClothingSeason.allSeason)) return 'All Season';
    return seasons.map((s) => s.name).join(', ');
  }

  String get occasionLabel => occasions.map((o) => o.name).join(', ');

  ClothingItem copyWith({
    String? name,
    ClothingCategory? category,
    List<String>? colors,
    String? primaryColor,
    List<ClothingSeason>? seasons,
    List<OccasionType>? occasions,
    String? imagePath,
    String? brand,
    int? wearCount,
    DateTime? lastWorn,
    bool? isFavorite,
    double? price,
    String? material,
    String? notes,
  }) {
    return ClothingItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      colors: colors ?? this.colors,
      primaryColor: primaryColor ?? this.primaryColor,
      seasons: seasons ?? this.seasons,
      occasions: occasions ?? this.occasions,
      imagePath: imagePath ?? this.imagePath,
      brand: brand ?? this.brand,
      dateAdded: dateAdded,
      wearCount: wearCount ?? this.wearCount,
      lastWorn: lastWorn ?? this.lastWorn,
      isFavorite: isFavorite ?? this.isFavorite,
      price: price ?? this.price,
      material: material ?? this.material,
      notes: notes ?? this.notes,
      mlConfidence: mlConfidence ?? this.mlConfidence,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.index,
        'colors': colors,
        'primaryColor': primaryColor,
        'seasons': seasons.map((s) => s.index).toList(),
        'occasions': occasions.map((o) => o.index).toList(),
        'imagePath': imagePath,
        'brand': brand,
        'dateAdded': dateAdded.toIso8601String(),
        'wearCount': wearCount,
        'lastWorn': lastWorn?.toIso8601String(),
        'isFavorite': isFavorite,
        'price': price,
        'material': material,
        'notes': notes,
      };

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
        id: json['id'],
        name: json['name'],
        category: ClothingCategory.values[json['category']],
        colors: List<String>.from(json['colors']),
        primaryColor: json['primaryColor'],
        seasons: (json['seasons'] as List).map((s) => ClothingSeason.values[s]).toList(),
        occasions: (json['occasions'] as List).map((o) => OccasionType.values[o]).toList(),
        imagePath: json['imagePath'],
        brand: json['brand'],
        dateAdded: DateTime.parse(json['dateAdded']),
        wearCount: json['wearCount'] ?? 0,
        lastWorn: json['lastWorn'] != null ? DateTime.parse(json['lastWorn']) : null,
        isFavorite: json['isFavorite'] ?? false,
        price: json['price']?.toDouble(),
        material: json['material'],
        notes: json['notes'],
      );
}
