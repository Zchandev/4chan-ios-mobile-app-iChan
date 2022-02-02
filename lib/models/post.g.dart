// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostAdapter extends TypeAdapter<Post> {
  @override
  final int typeId = 5;

  @override
  Post read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Post(
      body: fields[0] as String,
      outerId: fields[1] as String,
      timestamp: fields[2] as int,
      boardName: fields[17] as String,
      threadId: fields[18] as String,
      title: fields[3] as String,
      name: fields[4] as String,
      tripcode: fields[6] as String,
      isOp: fields[8] as bool,
      isBanned: fields[9] as bool,
      counter: fields[11] as int,
      email: fields[7] as String,
      isSage: fields[10] as bool,
      isDeleted: fields[15] as bool,
      isMine: fields[16] as bool,
      isToMe: fields[20] as bool,
      isUnread: fields[21] as bool,
      mediaFiles: (fields[12] as List)?.cast<Media>(),
      platform: fields[5] as Platform,
      repliesParent: (fields[13] as List)?.cast<String>(),
    )
      ..replies = (fields[14] as List)?.cast<String>()
      ..extras = (fields[19] as Map)?.cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, Post obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.body)
      ..writeByte(1)
      ..write(obj.outerId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.platform)
      ..writeByte(6)
      ..write(obj.tripcode)
      ..writeByte(7)
      ..write(obj.email)
      ..writeByte(8)
      ..write(obj.isOp)
      ..writeByte(9)
      ..write(obj.isBanned)
      ..writeByte(10)
      ..write(obj.isSage)
      ..writeByte(11)
      ..write(obj.counter)
      ..writeByte(12)
      ..write(obj.mediaFiles)
      ..writeByte(13)
      ..write(obj.repliesParent)
      ..writeByte(14)
      ..write(obj.replies)
      ..writeByte(15)
      ..write(obj.isDeleted)
      ..writeByte(16)
      ..write(obj.isMine)
      ..writeByte(17)
      ..write(obj.boardName)
      ..writeByte(18)
      ..write(obj.threadId)
      ..writeByte(19)
      ..write(obj.extras)
      ..writeByte(20)
      ..write(obj.isToMe)
      ..writeByte(21)
      ..write(obj.isUnread);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
