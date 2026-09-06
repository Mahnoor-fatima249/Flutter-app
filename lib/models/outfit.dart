import 'clothing_item.dart';

class Outfit {
  final String id;
  final String name;
  final List<ClothingItem> items;
  final OccasionType occasion;
  final ClothingSeason season;
  final double aiScore;
  final String? aiReason;
  final DateTime createdAt;
  final bool isSaved;
  final int timesWorn;

  Outfit({
    required this.id,
    required this.name,
    required this.items,
    required this.occasion,
    required this.season,
    this.aiScore = 0.0,
    this.aiReason,
    DateTime? createdAt,
    this.isSaved = false,
    this.timesWorn = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  String get itemCategories => items.map((i) => i.category.name).toSet().join(', ');

  double get averageColorHarmony {
    if (items.isEmpty) return 0;
    return items.fold(0.0, (sum, item) => sum + item.freshnessScore) / items.length;
  }

  Outfit copyWith({
    String? name,
    List<ClothingItem>? items,
    OccasionType? occasion,
    ClothingSeason? season,
    double? aiScore,
    String? aiReason,
    bool? isSaved,
    int? timesWorn,
  }) {
    return Outfit(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
      occasion: occasion ?? this.occasion,
      season: season ?? this.season,
      aiScore: aiScore ?? this.aiScore,
      aiReason: aiReason ?? this.aiReason,
      createdAt: createdAt,
      isSaved: isSaved ?? this.isSaved,
      timesWorn: timesWorn ?? this.timesWorn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((i) => i.toJson()).toList(),
        'occasion': occasion.index,
        'season': season.index,
        'aiScore': aiScore,
        'aiReason': aiReason,
        'createdAt': createdAt.toIso8601String(),
        'isSaved': isSaved,
        'timesWorn': timesWorn,
      };

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
        id: json['id'],
        name: json['name'],
        items: (json['items'] as List).map((i) => ClothingItem.fromJson(i)).toList(),
        occasion: OccasionType.values[json['occasion']],
        season: ClothingSeason.values[json['season']],
        aiScore: json['aiScore']?.toDouble() ?? 0.0,
        aiReason: json['aiReason'],
        createdAt: DateTime.parse(json['createdAt']),
        isSaved: json['isSaved'] ?? false,
        timesWorn: json['timesWorn'] ?? 0,
      );
}
