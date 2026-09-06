// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TravelPlanAdapter extends TypeAdapter<TravelPlan> {
  @override
  final int typeId = 14;

  @override
  TravelPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TravelPlan(
      id: fields[0] as String,
      destination: fields[1] as String,
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime,
      itemIds: (fields[4] as List).cast<String>(),
      notes: fields[5] as String?,
      weather: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TravelPlan obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.destination)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.itemIds)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.weather);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
