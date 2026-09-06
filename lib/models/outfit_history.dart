import 'package:hive/hive.dart';

part 'outfit_history.g.dart';

@HiveType(typeId: 16)
class OutfitHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<String> itemIds;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  int rating;

  @HiveField(4)
  String? occasion;

  @HiveField(5)
  String? notes;

  OutfitHistory({
    required this.id,
    required this.itemIds,
    required this.date,
    this.rating = 3,
    this.occasion,
    this.notes,
  });

  String get ratingLabel {
    if (rating <= 1) return 'Poor';
    if (rating == 2) return 'Fair';
    if (rating == 3) return 'Good';
    if (rating == 4) return 'Great';
    return 'Excellent';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemIds': itemIds,
        'date': date.toIso8601String(),
        'rating': rating,
        'occasion': occasion,
        'notes': notes,
      };

  factory OutfitHistory.fromJson(Map<String, dynamic> json) =>
      OutfitHistory(
        id: json['id'],
        itemIds: List<String>.from(json['itemIds']),
        date: DateTime.parse(json['date']),
        rating: json['rating'] ?? 3,
        occasion: json['occasion'],
        notes: json['notes'],
      );
}
