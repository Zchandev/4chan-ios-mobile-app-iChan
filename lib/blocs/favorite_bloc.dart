import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ichan/blocs/thread/event.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/models/post.dart';

import 'package:ichan/repositories/repositories.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/extensions.dart';
import 'package:retry/retry.dart';
import 'package:ichan/services/my.dart' as my;

// Upgraded to Cubit instead of Bloc
class FavoriteBloc extends Cubit<FavoriteState> {
  FavoriteBloc({@required this.repo}) : super(FavoriteReady());

  static const minRefreshTime = 1350;
  static const nonFavoriteRefreshTime = 24 * 3600;
  int unreadThreads = 0;
  int unreadReplies = 0;
  int autoRefreshStartedAt = 0;
  bool isRefreshing = false;

  final Repo repo;
  List<ThreadStorage> favoritesList;
  List<ThreadStorage> repliesList;

  Future startAutoupdate() async {
    if (isDebug) {
      return;
    }

    Timer.periodic(3.minutes, (timer) {
      print("Autorefresh started");

      refresh(auto: true);
    });
  }

  Future reloadFavorites() async {
    favoritesList = _getFavoritesList();
    repliesList = _getRepliesList();
  }

  Future refresh({bool auto = false}) async {
    if (auto) {
      if (autoRefreshStartedAt.timeDiffInSeconds < 30) {
        return;
      }
      autoRefreshStartedAt = DateTime.now().millisecondsSinceEpoch;
    }

    favoritesList ??= _getFavoritesList();
    repliesList ??= _getRepliesList();

    if (isRefreshing || (favoritesList.isEmpty && repliesList.isEmpty)) {
      return;
    }

    isRefreshing = true;
    final refreshStartedAt = DateTime.now().millisecondsSinceEpoch;

    emit(FavoriteReloading());
    emit(FavoriteRefreshInProgress());
    final List<ThreadStorage> allList = favoritesList
        .where((e) => _isNotDeletedAndActive(e))
        .sortedBy((a, b) => b.visits != null ? b.visits.compareTo(a.visits) : 0)
        .toList();

    final lastVisited =
        favoritesList.sortedBy((a, b) => b.visitedAt.compareTo(a.visitedAt)).take(3).toList();

    final myThreads = favoritesList.where((e) => e.isOp).take(3).toList();

    final _list = (myThreads + lastVisited + allList + repliesList).toSet().toList();

    await _refeshAll(_list, force: _list.length <= 5);
    my.prefs.incrStats('favs_refreshed');

    final diff = minRefreshTime - refreshStartedAt.timeDiff;

    if (diff > 0) {
      await Future.delayed(Duration(milliseconds: diff));
    }
    _calcUnreadReplies();
    _calcUnreadThreads();

    isRefreshing = false;

    emit(FavoriteReady());
  }

  Future updateUnreadReplies() async {
    emit(FavoriteReloading());
    _calcUnreadReplies();
    emit(FavoriteReady());
  }

  Future updateUnreadThreads() async {
    emit(FavoriteReloading());
    _calcUnreadThreads();
    emit(FavoriteReady());
  }

  Future clearDeleted() async {
    emit(FavoriteReloading());

    final keys =
        my.favs.box.values.where((e) => e.status == Status.deleted).map((e) => e.key).toList();
    my.favs.box.deleteAll(keys);

    emit(FavoriteReady());
  }

  Future clearVisited([ThreadStorage fav]) async {
    emit(FavoriteReloading());

    if (fav == null) {
      final first = my.favs.box.values.first;
      first.refreshedAt += 1;
      first.save();

      my.prefs.box.put("visited_cleared_at", DateTime.now().millisecondsSinceEpoch);
    } else {
      fav.delete();
    }

    emit(FavoriteReady());
  }

  Future favoriteDeleted([ThreadStorage fav]) async {
    emit(FavoriteReloading());
    if (fav.isSaved) {
      fav.delete();
    } else {
      fav.toggleFavorite();
    }
    emit(FavoriteReady());
  }

  Future favoriteUpdated() async {
    emit(FavoriteReloading());
    reloadFavorites();
    emit(FavoriteReady());
  }

  // Private

  List<ThreadStorage> _getFavoritesList() =>
      List.from(my.favs.box.values.where((e) => e.isFavorite));

  List<ThreadStorage> _getRepliesList() => List<ThreadStorage>.from(my.favs.box.values.where((e) =>
      e.ownPostsCount > 0 &&
      e.status != Status.deleted &&
      e.visitedAt.timeDiffInSeconds < nonFavoriteRefreshTime));

  Future _refeshAll(List<ThreadStorage> _list, {bool force = false}) async {
    for (final fav in _list) {
      if (!fav.isFavorite) {
        if (_needToRefresh(fav)) {
          // print("Awaiting non fav");
          await _refresh(fav);
        }
      } else {
        // TODO: parallel refresh on different platforms
        emit(FavoriteRefreshing(fav: fav, status: fav.status));
        if (force || _needToRefresh(fav)) {
          // print("Refreshing fav");
          fav.status = Status.refreshing;
          await _refresh(fav);
        } else {
          // print("Not refreshing fav");
        }
        emit(FavoriteRefreshing(fav: fav, status: fav.status));
      }
    }
  }

  Future<bool> _refresh(ThreadStorage fav) async {
    if (fav.refresh != true) {
      fav.status = Status.disabled;
      return false;
    }

    fav.status = Status.refreshing;

    try {
      final List<Post> posts = await retry(
        () => repo.on(fav.platform).fetchNewPosts(
            threadId: fav.threadId, boardName: fav.boardName, startPostId: fav.unreadPostId),
        maxAttempts: 3,
        delayFactor: 300.milliseconds,
        retryIf: (e) => e is UnavailableException,
      );

      fav.refreshedAt = DateTime.now().millisecondsSinceEpoch;

      if (posts.isNotEmpty) {
        fav.status = Status.unread;
        fav.unreadCount = posts.length;
        fav.extras['last_post_ts'] = posts.last.timestamp * 1000;
        fav.save();
        my.threadBloc.add(ThreadPostsAppended(posts: posts, fav: fav));
      } else {
        fav.status = Status.read;
      }

      return true;
    } on NotFoundException catch (_) {
      if (!fav.isSaved) {
        fav.status = Status.deleted;
      } else {
        fav.status = Status.disabled;
      }
      return false;
    } on UnavailableException catch (_) {
      if (fav.refreshedAt.timeDiffInSeconds >= 60) {
        fav.status = Status.error;
      }
      return false;
    }
  }

  void _calcUnreadReplies() {
    unreadReplies = my.posts.replies.where((e) => e.isUnread).length;
  }

  void _calcUnreadThreads() {
    unreadThreads =
        favoritesList.where((e) => e.unreadCount > 0 && e.status != Status.deleted).length;
    print("unreadThreads = ${unreadThreads}");
  }

  bool _needToRefresh(ThreadStorage fav) {
    fav.extras['last_post_ts'] ??= fav.visitedAt;
    fav.refreshedAt ??= 0;
    // current unixtime minus last thread refresh unixtime
    final refreshDiff = fav.refreshedAt.timeDiffInSeconds;

    // if user has just visited thread, mark it as higher priority
    final ts = max(fav.extras['last_post_ts'] as int, fav.visitedAt);
    final hoursDiff = ts.timeDiffInHours;

    bool result;
    if (!fav.isFavorite) {
      if (hoursDiff <= 0.2) {
        result = refreshDiff >= 60;
      } else if (hoursDiff <= 2) {
        result = refreshDiff >= 3 * 60;
      } else {
        result = refreshDiff >= 5 * 60;
      }
      return result;
    }

    if (hoursDiff <= 0.2) {
      result = refreshDiff >= 2;
    } else if (hoursDiff <= 1) {
      // print("Diff is $hoursDiff for ${fav.threadTitle} is 5s");
      result = refreshDiff >= 10;
    } else if (hoursDiff <= 2) {
      result = refreshDiff >= 20;
    } else if (hoursDiff <= 3) {
      result = refreshDiff >= 60;
    } else if (hoursDiff <= 6) {
      // print("Diff is $hoursDiff for ${fav.threadTitle} is 15s");
      result = refreshDiff >= 60 * 2;
    } else if (hoursDiff <= 12) {
      // print("Diff is $hoursDiff for ${fav.threadTitle} is 60s");
      result = refreshDiff >= 60 * 3;
    } else if (hoursDiff <= 24) {
      // print("Diff is $hoursDiff for ${fav.threadTitle} is 120s");
      result = refreshDiff >= 60 * 10;
    } else if (hoursDiff <= 48) {
      // print("Diff is $hoursDiff for ${fav.threadTitle} is 300s");
      result = refreshDiff >= 60 * 30;
    } else {
      // print("Diff is $hoursDiff for ${fav.threadTitle} is 600");
      result = refreshDiff >= 60 * 60;
    }

    // Log.warn(
    //     "Thread: ${fav.threadId}, hours: ${hoursDiff}, refreshed $refreshDiff sec ago, result is $result");

    return result;
  }

  bool _isNotDeletedAndActive(ThreadStorage fav) =>
      fav.refresh != false && fav.status != Status.deleted && fav.status != Status.closed;
}

abstract class FavoriteState extends Equatable {
  const FavoriteState({@required this.fav});

  final ThreadStorage fav;

  @override
  List<Object> get props => [fav];
}

class FavoriteRefreshInProgress extends FavoriteState {}

class FavoriteReloading extends FavoriteState {}

class FavoriteReady extends FavoriteState {}

class FavoriteRefreshing extends FavoriteState {
  const FavoriteRefreshing({@required this.fav, this.status}) : assert(fav != null);

  final ThreadStorage fav;
  final Status status;

  @override
  List<Object> get props => [fav, status];
}
