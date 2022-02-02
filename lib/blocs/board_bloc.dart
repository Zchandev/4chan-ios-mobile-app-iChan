import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ichan/blocs/blocs.dart';

import 'package:ichan/models/models.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/repositories/repositories.dart';
import 'package:ichan/services/my.dart' as my;

enum BoardFilter { all, recent, unvisited }

// BLOC
class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc({@required this.repo}) : super(BoardEmpty());

  final Repo repo;
  List<Thread> _threads = [];
  BoardFilter selectedFilter = BoardFilter.all;
  int loadedAt = DateTime.now().millisecondsSinceEpoch;

  List<Thread> filterByTitleStarts(String query) {
    return _threads.where((e) => e.title.toLowerCase().startsWith(query)).toList();
  }

  List<Thread> filterByTitleContains(String query) {
    return _threads.where((e) => e.title.toLowerCase().contains(query)).toList();
  }

  List<Thread> filterByBodyContains(String query) {
    return _threads.where((e) => e.body.toLowerCase().contains(query)).toList();
  }

  List<Thread> filterByTag(String query) {
    return _threads.where((e) => e.tags.toLowerCase().contains(query)).toList();
  }

  List<Thread> filterByUrl(String query) {
    final matches = RegExp(r"https?://2ch.+/.+/res/(\d+)\.html").allMatches(query).toList();

    if (matches.isEmpty) {
      return [];
    }

    return filterById(matches[0].group(1));
  }

  List<Thread> filterById(String query) {
    return _threads.where((e) => e.outerId.startsWith(query)).toList();
  }

  List<Thread> filterByFilesCount(int val) {
    return _threads.where((e) => e.filesCount >= val).toList();
  }

  List<Thread> filterByPostsCount(int val) {
    return _threads.where((e) => e.postsCount >= val).toList();
  }

  List<Thread> sortByPostsCount() {
    return _threads.sortedBy((a, b) => b.postsCount.compareTo(a.postsCount));
  }

  List<Thread> sortByFilesCount() {
    return _threads.sortedBy((a, b) => b.filesCount.compareTo(a.filesCount));
  }

  @override
  Stream<BoardState> mapEventToState(BoardEvent event) async* {
    // print("BoardEvent is $event");
    if (event is BoardLoadStarted) {
      if (event.query.isEmpty &&
          _threads.isNotEmpty &&
          _threads.first.boardName == event.board.id &&
          _threads.first.platform == event.board.platform) {
        if (loadedAt.timeDiffInMinutes <= 15) {
          yield BoardLoaded(threads: _threads, loadedAt: loadedAt);
          return;
        }
      }
      selectedFilter = BoardFilter.all;

      yield BoardLoading();

      final nsfwEnabled = event.board.platform == Platform.dvach
          ? my.prefs.getBool("dvach_nsfw")
          : my.prefs.getBool("fourchan_nsfw");

      if (my.prefs.isSafe && event.board.isNsfw == true && !nsfwEnabled) {
        yield const BoardError(
            message: "NSFW content is not available.\nOpen Settings -> Platform to enable it.",
            reloadable: false);
        return;
      }

      try {
        assert(event.board.platform != null);
        final response =
            await repo.on(event.board.platform).fetchThreads(boardName: event.board.id);
        _threads = response;
        loadedAt = DateTime.now().millisecondsSinceEpoch;

        if (event.query.isNotEmpty) {
          final filteredThreads = filterByTag(event.query);
          yield BoardLoaded(threads: filteredThreads, loadedAt: loadedAt);
        } else {
          yield BoardLoaded(threads: _threads, loadedAt: loadedAt);
        }
      } on MyException catch (error) {
        print("BoardState error is $error");
        yield BoardError(message: error.toString());
      }
    } else if (event is BoardFilterSelected) {
      loadedAt = DateTime.now().millisecondsSinceEpoch;

      if (event.filter == BoardFilter.all) {
        selectedFilter = BoardFilter.all;
        yield BoardLoaded(threads: _threads, loadedAt: loadedAt);
      } else if (event.filter == BoardFilter.recent) {
        selectedFilter = BoardFilter.recent;

        final recent = _threads.sortedBy((a, b) => b.timestamp.compareTo(a.timestamp)).toList();
        yield BoardLoaded(threads: recent, loadedAt: loadedAt);
      } else if (event.filter == BoardFilter.unvisited) {
        selectedFilter = BoardFilter.unvisited;

        final unvisited = _threads.where((thread) {
          final fav = ThreadStorage.fromThread(thread);
          return fav.visits == 0;
        }).toList();
        yield BoardLoaded(threads: unvisited, loadedAt: loadedAt);
      }
    } else if (event is ReloadThreads) {
      loadedAt = DateTime.now().millisecondsSinceEpoch;

      yield BoardLoaded(threads: state.threads, isRefreshing: true, loadedAt: loadedAt);

      try {
        _threads = await repo.on(event.board.platform).fetchThreads(boardName: event.board.id);
        if (selectedFilter != BoardFilter.all) {
          add(BoardFilterSelected(board: event.board, filter: selectedFilter));
        } else {
          yield BoardLoaded(threads: _threads, isRefreshing: false, loadedAt: loadedAt);
        }
      } on MyException catch (error) {
        print("BoardState error is $error");
        yield BoardModalError(message: error.toString());
      }
    } else if (event is BoardThreadHidden) {
      loadedAt = DateTime.now().millisecondsSinceEpoch;

      event.fav.isHidden = !event.fav.isHidden;
      event.fav.putOrSave();
      yield BoardLoaded(threads: _threads, isRefreshing: false, loadedAt: loadedAt);
    } else if (event is BoardSearchTyped) {
      loadedAt = DateTime.now().millisecondsSinceEpoch;
      if (state.threads != null) {
        List<Thread> filteredThreads;
        final length = event.query.length;

        final q = event.query.toLowerCase();

        if (q.startsWith("tag:")) {
          final tag = q.replaceAll('tag:', '').trim();
          filteredThreads = filterByTag(tag);
          yield BoardLoaded(threads: filteredThreads ?? [], loadedAt: loadedAt);
          return;
        }

        if (q.startsWith("sort:")) {
          final sort = q.replaceAll('sort:', '').trim();
          if (sort.startsWith('i') || sort.startsWith('f')) {
            filteredThreads = sortByFilesCount();
          } else if (sort.startsWith('p') || sort.startsWith('c')) {
            filteredThreads = sortByPostsCount();
          }
          yield BoardLoaded(threads: filteredThreads ?? [], loadedAt: loadedAt);
          return;
        }

        if (q.contains("min_files:") || q.contains("min_images:")) {
          final val = q.allAfter('min_files:').split(' ')[0];
          if (val.isNotEmpty) {
            filteredThreads = filterByFilesCount(val.toInt());
            yield BoardLoaded(threads: filteredThreads ?? [], loadedAt: loadedAt);
          } else {
            final val2 = q.allAfter('min_images:').split(' ')[0];
            if (val2.isNotEmpty) {
              filteredThreads = filterByFilesCount(val2.toInt());
              yield BoardLoaded(threads: filteredThreads ?? [], loadedAt: loadedAt);
            }
          }

          return;
        }

        if (q.contains("min_posts:")) {
          final val = q.allAfter('min_posts:').split(' ')[0];
          if (val.isNotEmpty) {
            filteredThreads = filterByPostsCount(val.toInt());
            yield BoardLoaded(threads: filteredThreads ?? [], loadedAt: loadedAt);
          }

          return;
        }

        if (length == 0) {
          filteredThreads = _threads;
        } else if (length <= 2) {
          filteredThreads = filterByTitleStarts(q).presence ??
              filterByTitleContains(q).presence ??
              filterByBodyContains(q).presence;
        } else if (length <= 5) {
          filteredThreads = filterByTitleContains(q).presence ?? filterByBodyContains(q).presence;
        } else {
          filteredThreads = filterByTitleContains(q).presence ??
              filterByBodyContains(q).presence ??
              filterByUrl(q).presence ??
              filterById(q).presence;
        }

        yield BoardLoaded(threads: filteredThreads ?? [], loadedAt: loadedAt);
      }
    }
  }
}

// EVENT
abstract class BoardEvent {
  const BoardEvent();

  Board get board;

  List<Object> get props => [board];
}

class BoardLoadStarted extends BoardEvent {
  const BoardLoadStarted({
    this.board,
    this.query = '',
  });

  final Board board;
  final String query;

  @override
  List<Object> get props => [board, query];
}

class ReloadThreads extends BoardEvent {
  const ReloadThreads({this.board});

  final Board board;

  @override
  List<Object> get props => [board];
}

class BoardSearchTyped extends BoardEvent {
  const BoardSearchTyped({this.query});

  final String query;

  @override
  List<Object> get props => [query];

  Board get board => null;
}

class BoardThreadHidden extends BoardEvent {
  const BoardThreadHidden({this.thread, this.fav});

  final Thread thread;
  final ThreadStorage fav;

  @override
  List<Object> get props => [thread, fav];

  Board get board => null;
}

class BoardFilterSelected extends BoardEvent {
  const BoardFilterSelected({this.board, this.filter});

  final Board board;
  final BoardFilter filter;

  @override
  List<Object> get props => [filter, board];
}

// STATE
abstract class BoardState extends Equatable {
  // const BoardState({this.threads}) : assert(threads != null);
  const BoardState();

  // final List<Thread> threads;

  @override
  List<Object> get props => [];

  List<Thread> get threads;
}

class BoardEmpty extends BoardState {
  List<Thread> get threads => null;
}

class BoardLoading extends BoardState {
  List<Thread> get threads => null;
}

class BoardLoaded extends BoardState {
  const BoardLoaded({
    @required this.threads,
    @required this.loadedAt,
    this.isRefreshing = false,
  }) : assert(threads != null);

  final List<Thread> threads;
  final bool isRefreshing;
  final int loadedAt;

  @override
  List<Object> get props => [threads, loadedAt, isRefreshing];
}

class BoardReloading extends BoardState {
  List<Thread> get threads => null;
}

class BoardReloaded extends BoardState {
  List<Thread> get threads => null;
}

class BoardError extends BoardState {
  const BoardError({
    this.message = "Error",
    this.reloadable = true,
  });

  final String message;
  final bool reloadable;

  @override
  List<Object> get props => [message, reloadable];

  List<Thread> get threads => null;
}

class BoardModalError extends BoardState {
  const BoardModalError({this.message = "Error"});

  final String message;

  @override
  List<Object> get props => [message];

  List<Thread> get threads => null;
}
