import 'package:hive/hive.dart';

part 'style_dna.g.dart';

@HiveType(typeId: 15)
class StyleDNA extends HiveObject {
  @HiveField(0)
  Map<String, int> preferences;

  @HiveField(1)
  String primaryStyle;

  @HiveField(2)
  List<String> topColors;

  @HiveField(3)
  DateTime completedAt;

  StyleDNA({
    required this.preferences,
    required this.primaryStyle,
    required this.topColors,
    required this.completedAt,
  });

  String get topStyle {
    if (preferences.isEmpty) return 'Unknown';
    final sorted = preferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Map<String, dynamic> toJson() => {
        'preferences': preferences,
        'primaryStyle': primaryStyle,
        'topColors': topColors,
        'completedAt': completedAt.toIso8601String(),
      };

  factory StyleDNA.fromJson(Map<String, dynamic> json) => StyleDNA(
        preferences: Map<String, int>.from(json['preferences']),
        primaryStyle: json['primaryStyle'],
        topColors: List<String>.from(json['topColors']),
        completedAt: DateTime.parse(json['completedAt']),
      );
}
