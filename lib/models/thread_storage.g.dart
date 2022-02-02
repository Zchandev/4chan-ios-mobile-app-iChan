// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_storage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThreadStorageAdapter extends TypeAdapter<ThreadStorage> {
  @override
  final int typeId = 1;

  @override
  ThreadStorage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThreadStorage(
      threadId: fields[0] as String,
      boardName: fields[1] as String,
      threadTitle: fields[2] as String,
      platform: fields[17] as Platform,
      unreadPostId: fields[3] as String,
      rememberPostId: fields[9] as String,
      unreadCount: fields[4] as int,
      visits: fields[6] as int,
      ownPostsCount: fields[12] as int,
      refresh: fields[7] as bool,
      isHidden: fields[13] as bool,
      hasReplies: fields[8] as bool,
      isFavorite: fields[10] as bool,
      temp: fields[14] as bool,
      savedJson: fields[18] as String,
      opCookie: fields[15] as String,
    )
      ..domain = fields[5] as String
      ..visitedAt = fields[11] as int
      ..extras = (fields[16] as Map)?.cast<String, dynamic>()
      ..refreshedAt = fields[19] as int;
  }

  @override
  void write(BinaryWriter writer, ThreadStorage obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.threadId)
      ..writeByte(1)
      ..write(obj.boardName)
      ..writeByte(2)
      ..write(obj.threadTitle)
      ..writeByte(3)
      ..write(obj.unreadPostId)
      ..writeByte(4)
      ..write(obj.unreadCount)
      ..writeByte(5)
      ..write(obj.domain)
      ..writeByte(6)
      ..write(obj.visits)
      ..writeByte(7)
      ..write(obj.refresh)
      ..writeByte(8)
      ..write(obj.hasReplies)
      ..writeByte(9)
      ..write(obj.rememberPostId)
      ..writeByte(10)
      ..write(obj.isFavorite)
      ..writeByte(11)
      ..write(obj.visitedAt)
      ..writeByte(12)
      ..write(obj.ownPostsCount)
      ..writeByte(13)
      ..write(obj.isHidden)
      ..writeByte(14)
      ..write(obj.temp)
      ..writeByte(15)
      ..write(obj.opCookie)
      ..writeByte(16)
      ..write(obj.extras)
      ..writeByte(17)
      ..write(obj.platform)
      ..writeByte(18)
      ..write(obj.savedJson)
      ..writeByte(19)
      ..write(obj.refreshedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreadStorageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
