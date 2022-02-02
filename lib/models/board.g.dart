// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BoardAdapter extends TypeAdapter<Board> {
  @override
  final int typeId = 3;

  @override
  Board read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Board(
      fields[0] as String,
      name: fields[1] as String,
      platform: fields[4] as Platform,
      category: fields[2] as String,
      bumpLimit: fields[3] as int,
      isFavorite: fields[5] as bool,
      isNsfw: fields[6] as bool,
      index: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Board obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.bumpLimit)
      ..writeByte(4)
      ..write(obj.platform)
      ..writeByte(5)
      ..write(obj.isFavorite)
      ..writeByte(6)
      ..write(obj.isNsfw)
      ..writeByte(7)
      ..write(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
