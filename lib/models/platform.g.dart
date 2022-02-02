// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlatformAdapter extends TypeAdapter<Platform> {
  @override
  final int typeId = 2;

  @override
  Platform read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Platform.all;
      case 1:
        return Platform.zchan;
      case 2:
        return Platform.dvach;
      case 3:
        return Platform.fourchan;
      default:
        return null;
    }
  }

  @override
  void write(BinaryWriter writer, Platform obj) {
    switch (obj) {
      case Platform.all:
        writer.writeByte(0);
        break;
      case Platform.zchan:
        writer.writeByte(1);
        break;
      case Platform.dvach:
        writer.writeByte(2);
        break;
      case Platform.fourchan:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
