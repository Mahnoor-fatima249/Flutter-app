import 'package:hive/hive.dart';

part 'wishlist_item.g.dart';

@HiveType(typeId: 11)
class WishlistItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? category;

  @HiveField(3)
  String? color;

  @HiveField(4)
  double? budget;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  int priority;

  @HiveField(7)
  bool isPurchased;

  @HiveField(8)
  DateTime createdAt;

  WishlistItem({
    required this.id,
    required this.name,
    this.category,
    this.color,
    this.budget,
    this.notes,
    this.priority = 2,
    this.isPurchased = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Medium';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'color': color,
        'budget': budget,
        'notes': notes,
        'priority': priority,
        'isPurchased': isPurchased,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        color: json['color'],
        budget: json['budget']?.toDouble(),
        notes: json['notes'],
        priority: json['priority'] ?? 2,
        isPurchased: json['isPurchased'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
