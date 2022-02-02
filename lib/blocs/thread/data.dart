import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// import 'package:ichan/db/app_db.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/services/exports.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ScrollData {
  ScrollData({
    this.unreadIndex = 0,
    this.rememberIndex = 0,
    this.listenable,
  });

  int unreadIndex;
  int rememberIndex;
  ValueNotifier<Iterable<ItemPosition>> listenable = ValueNotifier([]);
  ItemPosition get firstItem => listenable?.value?.firstOrNull();
  ItemPosition get lastItem => listenable?.value?.lastOrNull();
  int get firstIndex => firstItem.index;
  int get lastIndex => lastItem.index;

  void reset() {
    listenable = ValueNotifier([]);
  }

  @override
  String toString() =>
      "unreadIndex: $unreadIndex, rememberIndex: $rememberIndex, firstIndex: $firstIndex, lastIndex: $lastIndex";
}

class SearchData {
  SearchData({
    this.query = '',
    this.pos = 1,
  }) : results = [];

  String query;
  List<int> results;
  int pos;

  void reset() {
    query = '';
    pos = 1;
    results = [];
  }

  bool get isNotEmpty => results.isNotEmpty;
  bool get isEmpty => !isNotEmpty;
}

class ThreadData {
  ThreadData({@required this.thread}) : threadStorage = ThreadStorage.fromThread(thread);

  factory ThreadData.fromThreadLink(ThreadLink threadLink) {
    final result = ThreadData(thread: Thread.fromThreadLink(threadLink));
    if (threadLink.postId.isNotEmpty && threadLink.postId != threadLink.threadId) {
      result.ts.rememberPostId = threadLink.postId;
    }
    return result;
  }

  final ThreadStorage threadStorage;
  final ScrollData scrollData = ScrollData();
  final SearchData searchData = SearchData();
  Thread thread;
  List<Post> posts = [];
  ThreadStatus status = ThreadStatus.empty;
  int refreshedAt = 0;

  List<Media> get mediaList => thread.mediaFiles ?? [];
  ThreadStorage get ts => threadStorage;

  int get scrollIndex {
    if (posts.length <= 5) {
      return -1;
    }

    if (threadStorage.rememberPostId.isEmpty) {
      // print("Getting index from fav unread");
      return unreadPostIndex;
    } else {
      // print("Getting index from fav remember: ${threadStorage.rememberPostId}");
      return postIdToIndex(threadStorage.rememberPostId);
    }
  }

  int get unreadCount => threadStorage.unreadCount;

  int get unreadPostIndex => postIdToIndex(threadStorage.unreadPostId);

  int postIdToIndex(String id) => posts.indexWhere((post) => post.outerId == id);

  void addFavorite() {
    if (posts.isNotEmpty) {
      threadStorage.isFavorite = true;
      _updateStorage();
    }
  }

  void removeFavorite() {
    threadStorage.isFavorite = false;
    _updateStorage();
  }

  void _updateStorage() {
    threadStorage.boardName ??= thread.boardName;
    threadStorage.threadId ??= thread.outerId;
    threadStorage.platform ??= thread.platform;
    threadStorage.threadTitle = thread.fullTitle;

    threadStorage.putOrSave();
  }

  void markUnread(String postId) {
    ts.unreadPostId = postId;
    ts.rememberPostId = postId;
    final newCount = posts.length - postIdToIndex(postId) - 1;
    if (newCount >= 0) {
      ts.unreadCount = newCount;
    } else {
      ts.unreadCount = 0;
    }
  }

  String get unreadPostId => threadStorage.unreadPostId;
  String get rememberPostId => threadStorage.rememberPostId;
  bool get isFavorite => threadStorage.isFavorite;
  bool get isReadable => status == ThreadStatus.loaded || status == ThreadStatus.cached;
}
