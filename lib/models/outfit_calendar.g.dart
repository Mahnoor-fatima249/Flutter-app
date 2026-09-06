// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit_calendar.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OutfitCalendarAdapter extends TypeAdapter<OutfitCalendar> {
  @override
  final int typeId = 10;

  @override
  OutfitCalendar read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutfitCalendar(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      itemIds: (fields[2] as List).cast<String>(),
      notes: fields[3] as String?,
      isCompleted: fields[4] as bool,
      occasion: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OutfitCalendar obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.itemIds)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.occasion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitCalendarAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
