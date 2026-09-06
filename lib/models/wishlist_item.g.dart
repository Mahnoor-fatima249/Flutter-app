// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WishlistItemAdapter extends TypeAdapter<WishlistItem> {
  @override
  final int typeId = 11;

  @override
  WishlistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WishlistItem(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String?,
      color: fields[3] as String?,
      budget: fields[4] as double?,
      notes: fields[5] as String?,
      priority: fields[6] as int,
      isPurchased: fields[7] as bool,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WishlistItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.budget)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.isPurchased)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
