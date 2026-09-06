import 'package:hive/hive.dart';

part 'outfit_calendar.g.dart';

@HiveType(typeId: 10)
class OutfitCalendar extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final List<String> itemIds;

  @HiveField(3)
  String? notes;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  String? occasion;

  OutfitCalendar({
    required this.id,
    required this.date,
    required this.itemIds,
    this.notes,
    this.isCompleted = false,
    this.occasion,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'itemIds': itemIds,
        'notes': notes,
        'isCompleted': isCompleted,
        'occasion': occasion,
      };

  factory OutfitCalendar.fromJson(Map<String, dynamic> json) =>
      OutfitCalendar(
        id: json['id'],
        date: DateTime.parse(json['date']),
        itemIds: List<String>.from(json['itemIds']),
        notes: json['notes'],
        isCompleted: json['isCompleted'] ?? false,
        occasion: json['occasion'],
      );
}
