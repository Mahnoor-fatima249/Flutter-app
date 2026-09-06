// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laundry_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LaundryItemAdapter extends TypeAdapter<LaundryItem> {
  @override
  final int typeId = 12;

  @override
  LaundryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LaundryItem(
      clothingItemId: fields[0] as String,
      lastWashed: fields[1] as DateTime,
      washCount: fields[2] as int,
      careInstructions: fields[3] as String?,
      nextWashDate: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LaundryItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.clothingItemId)
      ..writeByte(1)
      ..write(obj.lastWashed)
      ..writeByte(2)
      ..write(obj.washCount)
      ..writeByte(3)
      ..write(obj.careInstructions)
      ..writeByte(4)
      ..write(obj.nextWashDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaundryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
