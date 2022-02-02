// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaAdapter extends TypeAdapter<Media> {
  @override
  final int typeId = 4;

  @override
  Media read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Media(
      path: fields[6] as String,
      url: fields[7] as String,
      name: fields[1] as String,
      origName: fields[2] as String,
      thumbnail: fields[3] as String,
      thumbnailUrl: fields[4] as String,
      md5: fields[5] as String,
      nsfw: fields[9] as bool,
      ext: fields[8] as String,
      postId: fields[0] as String,
      isVideo: fields[13] as bool,
      size: fields[10] as int,
      width: fields[11] as int,
      height: fields[12] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Media obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.postId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.origName)
      ..writeByte(3)
      ..write(obj.thumbnail)
      ..writeByte(4)
      ..write(obj.thumbnailUrl)
      ..writeByte(5)
      ..write(obj.md5)
      ..writeByte(6)
      ..write(obj.path)
      ..writeByte(7)
      ..write(obj.url)
      ..writeByte(8)
      ..write(obj.ext)
      ..writeByte(9)
      ..write(obj.nsfw)
      ..writeByte(10)
      ..write(obj.size)
      ..writeByte(11)
      ..write(obj.width)
      ..writeByte(12)
      ..write(obj.height)
      ..writeByte(13)
      ..write(obj.isVideo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
