// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clothing_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClothingCategoryAdapter extends TypeAdapter<ClothingCategory> {
  @override
  final int typeId = 0;

  @override
  ClothingCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ClothingCategory.tops;
      case 1:
        return ClothingCategory.bottoms;
      case 2:
        return ClothingCategory.outerwear;
      case 3:
        return ClothingCategory.dresses;
      case 4:
        return ClothingCategory.footwear;
      case 5:
        return ClothingCategory.accessories;
      case 6:
        return ClothingCategory.activewear;
      case 7:
        return ClothingCategory.formal;
      default:
        return ClothingCategory.tops;
    }
  }

  @override
  void write(BinaryWriter writer, ClothingCategory obj) {
    switch (obj) {
      case ClothingCategory.tops:
        writer.writeByte(0);
        break;
      case ClothingCategory.bottoms:
        writer.writeByte(1);
        break;
      case ClothingCategory.outerwear:
        writer.writeByte(2);
        break;
      case ClothingCategory.dresses:
        writer.writeByte(3);
        break;
      case ClothingCategory.footwear:
        writer.writeByte(4);
        break;
      case ClothingCategory.accessories:
        writer.writeByte(5);
        break;
      case ClothingCategory.activewear:
        writer.writeByte(6);
        break;
      case ClothingCategory.formal:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClothingCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClothingSeasonAdapter extends TypeAdapter<ClothingSeason> {
  @override
  final int typeId = 1;

  @override
  ClothingSeason read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ClothingSeason.spring;
      case 1:
        return ClothingSeason.summer;
      case 2:
        return ClothingSeason.autumn;
      case 3:
        return ClothingSeason.winter;
      case 4:
        return ClothingSeason.allSeason;
      default:
        return ClothingSeason.spring;
    }
  }

  @override
  void write(BinaryWriter writer, ClothingSeason obj) {
    switch (obj) {
      case ClothingSeason.spring:
        writer.writeByte(0);
        break;
      case ClothingSeason.summer:
        writer.writeByte(1);
        break;
      case ClothingSeason.autumn:
        writer.writeByte(2);
        break;
      case ClothingSeason.winter:
        writer.writeByte(3);
        break;
      case ClothingSeason.allSeason:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClothingSeasonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OccasionTypeAdapter extends TypeAdapter<OccasionType> {
  @override
  final int typeId = 2;

  @override
  OccasionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OccasionType.casual;
      case 1:
        return OccasionType.formal;
      case 2:
        return OccasionType.sporty;
      case 3:
        return OccasionType.party;
      case 4:
        return OccasionType.work;
      case 5:
        return OccasionType.date;
      case 6:
        return OccasionType.outdoor;
      default:
        return OccasionType.casual;
    }
  }

  @override
  void write(BinaryWriter writer, OccasionType obj) {
    switch (obj) {
      case OccasionType.casual:
        writer.writeByte(0);
        break;
      case OccasionType.formal:
        writer.writeByte(1);
        break;
      case OccasionType.sporty:
        writer.writeByte(2);
        break;
      case OccasionType.party:
        writer.writeByte(3);
        break;
      case OccasionType.work:
        writer.writeByte(4);
        break;
      case OccasionType.date:
        writer.writeByte(5);
        break;
      case OccasionType.outdoor:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OccasionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClothingItemAdapter extends TypeAdapter<ClothingItem> {
  @override
  final int typeId = 3;

  @override
  ClothingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClothingItem(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as ClothingCategory,
      colors: (fields[3] as List).cast<String>(),
      primaryColor: fields[4] as String,
      seasons: (fields[5] as List).cast<ClothingSeason>(),
      occasions: (fields[6] as List).cast<OccasionType>(),
      imagePath: fields[7] as String,
      brand: fields[8] as String?,
      dateAdded: fields[9] as DateTime,
      wearCount: fields[10] as int,
      lastWorn: fields[11] as DateTime?,
      isFavorite: fields[12] as bool,
      price: fields[13] as double?,
      material: fields[14] as String?,
      notes: fields[15] as String?,
      mlConfidence: (fields[16] as Map?)?.cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, ClothingItem obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.colors)
      ..writeByte(4)
      ..write(obj.primaryColor)
      ..writeByte(5)
      ..write(obj.seasons)
      ..writeByte(6)
      ..write(obj.occasions)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.brand)
      ..writeByte(9)
      ..write(obj.dateAdded)
      ..writeByte(10)
      ..write(obj.wearCount)
      ..writeByte(11)
      ..write(obj.lastWorn)
      ..writeByte(12)
      ..write(obj.isFavorite)
      ..writeByte(13)
      ..write(obj.price)
      ..writeByte(14)
      ..write(obj.material)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.mlConfidence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClothingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
