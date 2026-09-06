// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'style_dna.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StyleDNAAdapter extends TypeAdapter<StyleDNA> {
  @override
  final int typeId = 15;

  @override
  StyleDNA read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StyleDNA(
      preferences: (fields[0] as Map).cast<String, int>(),
      primaryStyle: fields[1] as String,
      topColors: (fields[2] as List).cast<String>(),
      completedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StyleDNA obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.preferences)
      ..writeByte(1)
      ..write(obj.primaryStyle)
      ..writeByte(2)
      ..write(obj.topColors)
      ..writeByte(3)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StyleDNAAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
