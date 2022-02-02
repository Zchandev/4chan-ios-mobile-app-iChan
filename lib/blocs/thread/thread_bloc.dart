import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/scheduler.dart';
import 'package:ichan/blocs/blocs.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/blocs/thread/event.dart';
import 'package:ichan/blocs/thread/state.dart';
import 'package:ichan/blocs/thread/thread_parser.dart';

import 'package:ichan/models/models.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/repositories/repositories.dart';
import 'package:ichan/services/exceptions.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  ThreadBloc({@required this.repo}) : super(const ThreadEmpty());

  final Repo repo;
  final Map<String, ThreadData> _threadDataList = {};
  ThreadData _current;

  // for debug only
  ThreadData get current => _current;

  @override
  Stream<ThreadState> mapEventToState(ThreadEvent event) async* {
    if (event is ThreadFetchStarted) {
      if (event.force) {
        _threadDataList.remove(event.thread.toKey);
      }

      yield* _threadFetchStartedEvent(event);
    } else if (event is ThreadPostsAppended) {
      final threadData = getThreadData(event.fav.id);

      ThreadParser parser;
      if (threadData != null) {
        yield ThreadLoading(threadData: threadData);
        parser = ThreadParser(threadData: threadData);
        await parser.appendPosts(event.posts);
        yield ThreadLoaded(threadData: threadData);
      } else {
        parser = ThreadParser(threadStorage: event.fav);
        parser.appendPosts(event.posts);
      }
    } else if (event is ThreadRefreshStarted) {
      // Todo: multiplatform support
      if (event.thread.platform == Platform.dvach) {
        yield* _threadRefreshStartedEvent(event);
      } else {
        print("Redirecting to full refresh");
        add(ThreadFetchStarted(thread: event.thread));
      }
      //======================================================================
    } else if (event is ThreadScrollStarted && (state is ThreadLoading == false)) {
      yield* _scrollThreadEvent(event);
    } else if (event is ThreadReportPressed) {
      yield* _threadReportPressedEvent(event);
    } else if (event is ThreadDeletePressed) {
      yield* _threadDeletePressedEvent(event);
    } else if (event is ThreadCacheDisabled) {
      _threadDataList.clear();
      _current = ThreadData(thread: Thread.empty());
    } else if (event is ThreadSearchStarted) {
      final q = event.query.toLowerCase();
      final threadData = getThreadData(event.thread.toKey);
      final searchData = threadData.searchData;
      searchData.query = q;
      searchData.pos = event.pos;

      if (q.contains(' ')) {
        searchData.results = searchAll(threadData, q);
      } else {
        searchData.results = searchWord(threadData, q);

        if (searchData.results.isEmpty) {
          searchData.results = searchAll(threadData, q);
        }
      }

      if (searchData.results.isNotEmpty) {
        yield StartScroll(
          threadData: threadData,
          index: searchData.results[searchData.pos - 1],
        );
      } else {
        yield ThreadLoading(threadData: threadData);
      }

      yield ThreadLoaded(threadData: threadData);
    } else if (event is ThreadClosed) {
      yield* _threadClosedEvent(event);
    }
  }

  List<int> searchWord(ThreadData threadData, String query) {
    final List<int> result = [];
    int i = 0;
    for (final post in threadData.posts) {
      final words = post.cleanBody.toLowerCase().split(' ');
      if (words.any((e) => e.startsWith(query))) {
        result.add(i);
        if (result.length >= 100) {
          return result;
        }
      }
      i += 1;
    }
    return result;
  }

  List<int> searchAll(ThreadData threadData, String query) {
    final List<int> result = [];
    int i = 0;
    for (final post in threadData.posts) {
      if (post.cleanBody.toLowerCase().contains(query)) {
        result.add(i);
        if (result.length >= 100) {
          return result;
        }
      }
      i += 1;
    }
    return result;
  }

  Future<bool> listenableReady() async {
    if (_current.scrollData?.listenable?.value?.isNotEmpty != true) {
      await Future.delayed(25.milliseconds);
      return listenableReady();
    } else {
      return Future.value(true);
    }
  }

  Stream<ThreadState> _threadReportPressedEvent(ThreadReportPressed event) async* {
    print("CreateReport event");

    Log.warn("1");

    final result = await repo.on(Platform.dvach).createReport(payload: event.payload);
    Log.warn("2");
    if (result["ok"] == true) {
      Log.warn("OK");
      yield ThreadMessage(message: "Report has been sent", threadData: _current);
      yield ThreadLoaded(threadData: _current);
    } else {
      Log.warn("NOT OK");
      yield ThreadMessage(
        message: result["error"],
        threadData: _current,
      );
      yield ThreadLoaded(threadData: _current);
    }
  }

  Stream<ThreadState> _threadDeletePressedEvent(ThreadDeletePressed event) async* {
    print("Delete event");

    final payload = {
      'threadId': event.post.threadId,
      'postId': event.post.outerId,
      'boardName': event.post.boardName,
    };

    final result = await repo.on(event.post.platform).deletePost(payload);
    if (result['ok']) {
      yield ThreadMessage(message: "Post has been deleted", threadData: _current);
      yield ThreadLoaded(threadData: _current);
    } else {
      yield ThreadMessage(message: result['error'], threadData: _current);
      _current.posts.removeWhere((e) => e.outerId == event.post.outerId);
      yield ThreadLoaded(threadData: _current);
    }
    return;
  }

  Stream<ThreadState> _threadFetchStartedEvent(ThreadFetchStarted event) async* {
    _current = initThreadData(event.thread);

    final isShowCached =
        _current.posts.isNotEmpty && my.prefs.getBool('thread_cache_disabled') == false;

    if (isShowCached) {
      _current.status = ThreadStatus.cached;

      yield ThreadLoading(threadData: _current);

      await listenableReady();

      if (_current.thread.platform == Platform.dvach) {
        add(ThreadRefreshStarted(thread: _current.thread));
      } else {
        yield* threadLoad(thread: event.thread, scrollPostId: event.scrollPostId);
      }
    } else {
      if (event.thread.isNotEmpty &&
          (_current.rememberPostId == '' || _current.rememberPostId == event.thread.outerId)) {
        _current.posts = [Post.fromThread(event.thread)];
        _current.thread = event.thread;
        _current.status = ThreadStatus.partial;
        // print("====== LOADING UNREAD INDEX is ${_current.unreadPostIndex}");
        yield ThreadLoading(threadData: _current);
      } else {
        final td = ThreadData(thread: event.thread);

        yield ThreadEmpty(threadData: td);
      }

      yield* threadLoad(
        thread: event.thread,
        scrollPostId: event.scrollPostId,
        savedJson: _current.threadStorage.savedJson,
      );
    }
  }

  Stream<ThreadState> threadLoad(
      {Thread thread, String scrollPostId = '', String savedJson = ''}) async* {
    assert(thread.platform != null);
    try {
      final data =
          await repo.on(thread.platform).fetchThreadPosts(thread: thread, savedJson: savedJson);

      // print("_current.thread.uniquePosters = ${_current.thread.uniquePosters}");
      if (_current.thread.uniquePosters == null) {
        _current.thread = data["thread"] as Thread;
      }
      if (_current.status == ThreadStatus.partial) {
        _current.posts = [];
        _current.thread.mediaFiles = [];
      }
      // print("2 _current.thread.uniquePosters = ${_current.thread.uniquePosters}");

      updateFavoriteBefore();

      if (scrollPostId.isNotEmpty) {
        _current.threadStorage.rememberPostId = scrollPostId;
      }

      final parser = ThreadParser(threadData: _current);
      // print("3 _current.thread.uniquePosters = ${_current.thread.uniquePosters}");

      await SchedulerBinding.instance.scheduleTask(
        () => parser.appendPosts(data["posts"] as List<Post>),
        Priority.animation,
      );

      _current.status = ThreadStatus.loaded;
      _current.refreshedAt = DateTime.now().millisecondsSinceEpoch;

      yield ThreadLoading(threadData: _current);

      await listenableReady();

      // print("3 _current.thread.uniquePosters = ${_current.thread.uniquePosters}");

      yield ThreadLoaded(threadData: _current);
    } on MyException catch (error) {
      if (savedJson == null && _current.threadStorage.savedJson.isNotEmpty) {
        yield* threadLoad(
          thread: thread,
          scrollPostId: scrollPostId,
          savedJson: _current.threadStorage.savedJson,
        );
      } else {
        yield ThreadError(message: error.toString(), code: error.code, threadData: _current);
      }
    }
  }

  Stream<ThreadState> _threadRefreshStartedEvent(ThreadRefreshStarted event) async* {
    _current = initThreadData(event.thread);

    yield ThreadLoading(threadData: _current);
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      await getNewPosts(threadId: event.thread.outerId, boardName: event.thread.boardName);
      final int diff = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (diff < 300) {
        await Future.delayed(Duration(milliseconds: 300 - diff));
      }
      if (event.delay != null) {
        await Future.delayed(event.delay);
      }

      _current.status = ThreadStatus.loaded;
      _current.refreshedAt = DateTime.now().millisecondsSinceEpoch;
      _current.ts.extras['last_post_ts'] = _current.posts.last.timestamp * 1000;

      yield ThreadLoaded(threadData: _current);
    } on MyException catch (error) {
      _current.status = ThreadStatus.loaded;
      print("getNewPosts exception: $error");
      yield ThreadError(message: error.toString(), code: error.code, threadData: _current);
    }
  }

  Stream<ThreadState> _threadClosedEvent(ThreadClosed event) async* {
    _current = initThreadData(event.threadData.thread);
    final ts = _current.threadStorage;
    final scrollData = _current.scrollData;
    final posts = _current.posts;

    // log("EVENT Unread post count is ${ts.unreadCount}");

    ts.refreshedAt = DateTime.now().millisecondsSinceEpoch;
    ts.visitedAt = ts.refreshedAt;

    if (ts.unreadCount <= 1) {
      ts.hasReplies = false;
      final unreadPosts = posts.where((e) => e.isUnread && e.isPersisted).toList();
      for (final post in unreadPosts) {
        post.isUnread = false;
        post.save();
      }
    }

    if (posts.isEmpty) {
      // print("POSTS IS EMPTY, RETURN");
      ts.putOrSave();
      scrollData.reset();
      return;
    } else if (posts.length == 1) {
      ts.unreadPostId = posts.first.outerId;
      ts.rememberPostId = posts.first.outerId;
      ts.putOrSave();
      scrollData.reset();
      return;
    }

    if (scrollData?.firstItem == null) {
      ts.putOrSave();
      scrollData.reset();
      return;
    }

    // If its scrolled to the last page,
    final isScrolledToBottom = scrollData.lastIndex + 2 >= posts.length;

    if (isScrolledToBottom) {
      ts.rememberPostId = posts[posts.length - 1].outerId;
    } else {
      final firstItem =
          scrollData.firstIndex > scrollData.lastIndex ? scrollData.lastItem : scrollData.firstItem;

      final readIndicator = (firstItem.itemTrailingEdge - firstItem.itemLeadingEdge) / 2;

      // if we read it at least for 50%, skip to next;
      if (firstItem.itemLeadingEdge.abs() >= readIndicator) {
        final i = firstItem.index + 1;
        final _post = posts.elementAtOrNull(i) ?? posts.last;
        // print("More than 50%, setting to ${_post.outerId}");
        ts.rememberPostId = _post.outerId;
      } else {
        // print("Less than 50%, setting to ${scrollData.firstIndex}");
        ts.rememberPostId = posts[firstItem.index].outerId;
      }
      // print("New remember index: ${scrollData.firstIndex}");
    }

    final unreadPostIndex = posts.length - ts.unreadCount - 1;
    ts.unreadPostId = posts.elementAtOrNull(unreadPostIndex)?.outerId ?? posts.last.outerId;
    scrollData.reset();
    my.favoriteBloc.favoriteUpdated();
    ts.putOrSave();
  }

  Stream<ThreadState> _scrollThreadEvent(ThreadScrollStarted event) async* {
    _current = initThreadData(event.thread);
    if (_current.posts == null) {
      return;
    }

    final scrollTo = event.to ?? "post";
    final ts = _current.threadStorage;

    switch (scrollTo) {
      case "firstUnread":
        final currentPos = _current.scrollData.lastIndex;
        final isScrolledFurther = currentPos >= _current.unreadPostIndex;
        final isNextClick =
            (int.tryParse(ts.rememberPostId) ?? 0) >= (int.tryParse(ts.unreadPostId) ?? 0);

        if (isScrolledFurther || isNextClick) {
          add(ThreadScrollStarted(to: 'last', thread: event.thread));
          return;
        } else {
          ts.rememberPostId = ts.unreadPostId;
          final unreadIndex = _current.unreadPostIndex;
          yield StartScroll(
            threadData: _current,
            index: unreadIndex + 1,
          );
        }
        break;
      case "nextUnread":
        final posts = _current.posts;
        final unreadIndex = _current.unreadPostIndex + 1;

        ts.rememberPostId = posts.elementAtOrNull(unreadIndex)?.outerId ?? posts.last.outerId;

        ts.unreadPostId = ts.rememberPostId;

        yield StartScroll(
          threadData: _current,
          index: unreadIndex + 1,
        );
        break;
      case "last":
        ts.unreadPostId = _current.posts.last.outerId;
        ts.rememberPostId = ts.unreadPostId;
        ts.unreadCount = 0;

        yield StartScroll(
          threadData: _current,
          index: _current.posts.length - 1,
        );
        break;
      case "first":
        ts.rememberPostId = _current.posts.first.outerId;
        yield StartScroll(threadData: _current, index: 0);
        break;
      case "index":
        yield StartScroll(threadData: _current, index: event.index);
        break;
      case "post":
        ts.rememberPostId = event.postId;

        yield StartScroll(
          threadData: _current,
          index: postIdToIndex(postId: event.postId),
        );
        break;
      default:
        print("INVALID EVENT FOR SCROLL: ${event.to}");
    }

    yield ThreadLoaded(threadData: _current);
  }

  void updateFavoriteBefore() async {
    final ts = _current.threadStorage;

    if (ts.isEmpty || ts.isRemembered == false) {
      ts.boardName = _current.thread.boardName;
      ts.threadId = _current.thread.outerId;
      ts.threadTitle = _current.thread.titleOrBody;
      ts.platform = _current.thread.platform;
      if (_current.posts.isNotEmpty) {
        ts.unreadPostId = _current.posts.first.outerId;
        ts.unreadCount = _current.posts.length - 1;
        ts.extras['last_post_ts'] = _current.posts.last.timestamp * 1000;
      } else {
        ts.unreadPostId = _current.thread.outerId;
        ts.extras['last_post_ts'] = _current.thread.timestamp * 1000;
      }
      ts.rememberPostId = ts.unreadPostId;
    }

    if (_current.thread.isClosed) {
      ts.status = Status.closed;
    }

    if (ts.threadTitle != _current.thread.titleOrBody) {
      ts.threadTitle = _current.thread.titleOrBody;
    }
    ts.visitedAt = DateTime.now().millisecondsSinceEpoch;
    ts.visits += 1;
    my.prefs.incrStats('threads_clicked');

    if (ts.isInBox) {
      ts.save();
    } else {
      my.prefs.incrStats('threads_visited');
      my.favs.box.put(ts.id, ts);
    }

    my.favoriteBloc.favoriteUpdated();
  }

  Future<void> getNewPosts({@required String threadId, @required String boardName}) async {
    assert(threadId != null && boardName != null);
    assert(_current != null);

    final startPostId = _current.posts.isEmpty ? threadId : _current.posts.last.outerId;

    final newPosts = await repo
        .on(Platform.dvach)
        .fetchNewPosts(threadId: threadId, boardName: boardName, startPostId: startPostId);

    final parser = ThreadParser(threadData: _current);
    await SchedulerBinding.instance.scheduleTask(
      () => parser.appendPosts(newPosts),
      Priority.animation,
    );

    final lastId = _current.threadStorage.unreadPostId.toInt();
    for (final post in newPosts) {
      if (post.outerId.toInt() > lastId) {
        _current.threadStorage.unreadCount += 1;
      }
    }
  }

  int postIdToIndex({String postId, int orElse}) {
    final int result = _current?.posts?.indexWhere((e) => e.outerId == postId);
    if ((result == null || result == -1) && orElse != null) {
      return orElse;
    }
    return result ?? -1;
  }

  ThreadData initThreadData(Thread thread) {
    if (_threadDataList.containsKey(thread.toKey)) {
      final result = _threadDataList[thread.toKey];
      return result;
    } else {
      return _threadDataList[thread.toKey] = ThreadData(thread: thread);
    }
  }

  ThreadData getThreadData(String key) => _threadDataList[key];
}
