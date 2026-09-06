// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OutfitHistoryAdapter extends TypeAdapter<OutfitHistory> {
  @override
  final int typeId = 16;

  @override
  OutfitHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutfitHistory(
      id: fields[0] as String,
      itemIds: (fields[1] as List).cast<String>(),
      date: fields[2] as DateTime,
      rating: fields[3] as int,
      occasion: fields[4] as String?,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OutfitHistory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemIds)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.rating)
      ..writeByte(4)
      ..write(obj.occasion)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
