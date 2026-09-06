import 'package:hive/hive.dart';

part 'travel_plan.g.dart';

@HiveType(typeId: 14)
class TravelPlan extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String destination;

  @HiveField(2)
  DateTime startDate;

  @HiveField(3)
  DateTime endDate;

  @HiveField(4)
  List<String> itemIds;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  String? weather;

  TravelPlan({
    required this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.itemIds,
    this.notes,
    this.weather,
  });

  int get tripLength {
    return endDate.difference(startDate).inDays + 1;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination': destination,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'itemIds': itemIds,
        'notes': notes,
        'weather': weather,
      };

  factory TravelPlan.fromJson(Map<String, dynamic> json) => TravelPlan(
        id: json['id'],
        destination: json['destination'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        itemIds: List<String>.from(json['itemIds']),
        notes: json['notes'],
        weather: json['weather'],
      );
}
