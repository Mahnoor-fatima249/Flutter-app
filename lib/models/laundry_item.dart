import 'package:hive/hive.dart';

part 'laundry_item.g.dart';

@HiveType(typeId: 12)
class LaundryItem extends HiveObject {
  @HiveField(0)
  final String clothingItemId;

  @HiveField(1)
  DateTime lastWashed;

  @HiveField(2)
  int washCount;

  @HiveField(3)
  String? careInstructions;

  @HiveField(4)
  DateTime? nextWashDate;

  LaundryItem({
    required this.clothingItemId,
    required this.lastWashed,
    this.washCount = 0,
    this.careInstructions,
    this.nextWashDate,
  });

  int get daysSinceLastWash {
    return DateTime.now().difference(lastWashed).inDays;
  }

  bool get needsWashing {
    if (nextWashDate == null) return false;
    return DateTime.now().isAfter(nextWashDate!);
  }

  Map<String, dynamic> toJson() => {
        'clothingItemId': clothingItemId,
        'lastWashed': lastWashed.toIso8601String(),
        'washCount': washCount,
        'careInstructions': careInstructions,
        'nextWashDate': nextWashDate?.toIso8601String(),
      };

  factory LaundryItem.fromJson(Map<String, dynamic> json) => LaundryItem(
        clothingItemId: json['clothingItemId'],
        lastWashed: DateTime.parse(json['lastWashed']),
        washCount: json['washCount'] ?? 0,
        careInstructions: json['careInstructions'],
        nextWashDate: json['nextWashDate'] != null
            ? DateTime.parse(json['nextWashDate'])
            : null,
      );
}
