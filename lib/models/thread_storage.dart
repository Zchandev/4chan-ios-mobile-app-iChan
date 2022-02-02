import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:ichan/models/platform.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/services/htmlz.dart';
import 'package:ichan/services/my.dart' as my;

part 'thread_storage.g.dart';

enum Status {
  refreshing,
  read,
  unread,
  unreadWithReplies,
  deleted,
  disabled,
  closed,
  error,
}

@HiveType(typeId: 1)
class ThreadStorage extends HiveObject {
  ThreadStorage({
    @required this.threadId,
    @required this.boardName,
    @required this.threadTitle,
    @required this.platform,
    this.unreadPostId = '',
    this.rememberPostId = '',
    this.unreadCount = 0,
    this.visits = 0,
    this.ownPostsCount = 0,
    this.refresh = true,
    this.isHidden = false,
    this.hasReplies = false,
    this.isFavorite = false,
    this.temp = false,
    this.savedJson = '',
    this.opCookie = '',
  })  : refreshedAt = DateTime.now().millisecondsSinceEpoch,
        visitedAt = DateTime.now().millisecondsSinceEpoch,
        extras = {};

  factory ThreadStorage.fromThread(Thread thread) {
    final existing = findById(thread.toKey);
    if (existing.isNotEmpty) {
      return existing;
    } else {
      return ThreadStorage(
        threadId: thread.outerId,
        boardName: thread.boardName,
        threadTitle: thread.fullTitle,
        platform: thread.platform,
        unreadCount: 0,
      );
    }
  }

  factory ThreadStorage.empty() {
    return ThreadStorage(
      platform: null,
      threadId: null,
      boardName: null,
      threadTitle: null,
    );
  }

  @HiveField(0)
  String threadId;

  @HiveField(1)
  String boardName;

  @HiveField(2)
  String threadTitle;

  @HiveField(3)
  String unreadPostId;

  @HiveField(4)
  int unreadCount;

  @HiveField(5)
  String domain;

  @HiveField(6)
  int visits;

  @HiveField(7)
  bool refresh;

  @HiveField(8)
  bool hasReplies;

  @HiveField(9)
  String rememberPostId;

  @HiveField(10)
  bool isFavorite;

  @HiveField(11)
  int visitedAt;

  @HiveField(12)
  int ownPostsCount;

  @HiveField(13)
  bool isHidden = false;

  @HiveField(14)
  bool temp = false;

  @HiveField(15)
  String opCookie;

  @HiveField(16)
  Map<String, dynamic> extras;

  @HiveField(17)
  Platform platform;

  @HiveField(18)
  String savedJson;

  @HiveField(19)
  int refreshedAt;

  Status _status;

  String _shortTitle;

  static ThreadStorage find({String threadId, String boardName, Platform platform}) {
    return my.favs.box
        .get("${platform.toString()}-$boardName-$threadId", defaultValue: ThreadStorage.empty());
  }

  static ThreadStorage findById(String _id) {
    return my.favs.box.get(_id, defaultValue: ThreadStorage.empty());
  }

  bool get isOp => opCookie.isNotEmpty;

  String get shortTitle {
    _shortTitle ??= Htmlz.unescape(threadTitle);
    return _shortTitle;
  }

  Status get status => _status ?? (unreadCount == 0 ? Status.read : Status.unread);
  set status(Status newStatus) => _status = newStatus;

  bool get isEmpty => threadId == null && boardName == null;
  bool get isNotEmpty => !isEmpty;
  bool get isRemembered => rememberPostId != '';
  bool get isSaved => savedJson?.isNotEmpty == true;

  String get id => "${platform.toString()}-$boardName-$threadId";

  void toggleFavorite() {
    isFavorite = !isFavorite;
    putOrSave();
  }

  Future<void> putOrSave() async {
    if (isNotEmpty) {
      return isInBox ? await save() : await my.favs.box.put(id, this);
    }
    return Future.value();
  }
}
