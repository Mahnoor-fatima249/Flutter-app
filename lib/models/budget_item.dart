import 'package:hive/hive.dart';

part 'budget_item.g.dart';

@HiveType(typeId: 13)
class BudgetItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String category;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String? notes;

  BudgetItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
        id: json['id'],
        name: json['name'],
        amount: json['amount'].toDouble(),
        category: json['category'],
        date: DateTime.parse(json['date']),
        notes: json['notes'],
      );
}
