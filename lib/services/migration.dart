import 'package:ichan/models/board.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/services/enums.dart';
import 'package:ichan/services/my.dart' as my;

class Migration {
  static const current = 8;

  static Future migrate() async {
    try {
      int lvl = my.prefs.getInt('migration');
      while (lvl < current) {
        await run(lvl);
        print("Migrated to $lvl");
        lvl += 1;
      }
      my.prefs.put('migration', current);
    } catch (e) {
      print("Error is $e");
    }
  }

  static Future run(int step) async {
    if (step == 0) {
      final favs = my.favs.box.toMap();
      favs.forEach((key, fav) {
        fav.isFavorite ??= true;
        fav.refreshedAt ??= DateTime.now().millisecondsSinceEpoch;
        fav.visitedAt ??= DateTime.now().millisecondsSinceEpoch;
        fav.hasReplies ??= false;
        fav.rememberPostId ??= '';
        fav.save();
      });
    }

    if (step == 1) {
      final favs = my.favs.box.toMap();
      favs.forEach((key, fav) {
        fav.ownPostsCount = 0;
        fav.save();
      });
    }

    if (step == 2) {
      final favs = my.favs.box.toMap();
      favs.forEach((key, fav) {
        fav.isHidden = false;
        fav.save();
      });
    }

    if (step == 3) {
      final favs = my.favs.box.toMap();
      favs.forEach((key, fav) {
        fav.temp = false;
        fav.opCookie = '';
        fav.extras = {};
        fav.save();
      });

      final usercode = my.prefs.getString('usercode');

      if (usercode.isNotEmpty) {
        final passcode = my.prefs.getString('passcode');
        print("Migrating usercode $usercode to secstore");
        my.secstore.put('2ch/$passcode/code', usercode);
        my.prefs.box.delete('usercode');
      }
    }

    if (step == 4) {
      // print("NOT NOW");
      // return;
      final favBoards = my.prefs.get("boards");
      if (favBoards != null) {
        final Map<String, dynamic> fetchedBoards = await my.repo.on(Platform.dvach).fetchBoards();
        final List<Board> boardsList = fetchedBoards['boards'];

        final List<Board> newBoards = [];
        for (final board in favBoards) {
          final _board = boardsList.firstWhere((e) => e.id == board,
              orElse: () => Board(
                    board,
                    name: board,
                    platform: Platform.dvach,
                    category: '',
                  ));
          _board.isFavorite = true;
          newBoards.add(_board);
        }
        my.prefs.put('favorite_boards', newBoards);
        my.prefs.delete('boards');
      }

      final favThreads = my.favs.box.values;
      final defaultStats = {
        "threads_visited": 0,
        "threads_clicked": 0,
        "threads_created": 0,
        "posts_created": 0,
      };

      final Map<String, int> stats = Map.from(my.prefs.get("stats", defaultValue: defaultStats));
      for (final ts in favThreads) {
        stats['threads_visited'] += 1;
        stats['threads_clicked'] += ts.visits;
        if (ts.isOp) {
          stats['threads_created'] += 1;
        }
        if (ts.isFavorite) {
          final newTs = ThreadStorage(
            threadId: ts.threadId,
            boardName: ts.boardName,
            threadTitle: ts.threadTitle,
            platform: Platform.dvach,
            unreadPostId: ts.unreadPostId,
            rememberPostId: ts.rememberPostId,
            unreadCount: ts.unreadCount,
            visits: ts.visits,
            ownPostsCount: ts.ownPostsCount,
            refresh: ts.refresh,
            isHidden: ts.isHidden,
            hasReplies: ts.hasReplies,
            isFavorite: ts.isFavorite,
            temp: ts.temp,
            opCookie: ts.opCookie ?? '',
            savedJson: '',
          );

          newTs.visitedAt = ts.visitedAt;
          newTs.extras = ts.extras;
          print("Saving thread");
          newTs.putOrSave();
          if (ts.platform == null) {
            ts.delete();
          }
        } else {
          print("Deleting thread");
          ts.delete();
        }
      }

      my.favs.box.compact();
      my.prefs.put('stats', stats);
      my.prefs.put('platform', [Platform.dvach]);

      print('MIGRATED TO VERSION 5');
    }

    if (step == 5) {
      // SQLite removed
      // Some users would be fucked up
      // Sad for them

      // final myPostsList = await my.db.getMyPosts();
      // await my.posts.box.clear();
      // for (final post in myPostsList) {
      //   final platform = post.platform == Platform.all ? Platform.dvach : post.platform;

      //   final newPost = Post(
      //     body: post.body,
      //     threadId: post.threadId,
      //     outerId: post.outerId,
      //     timestamp: post.timestamp,
      //     boardName: post.boardName,
      //     platform: platform,
      //     title: '',
      //     name: post.name ?? '',
      //     tripcode: post.tripcode ?? '',
      //     isMine: post.my,
      //     isToMe: false,
      //     isUnread: false,
      //     isSage: post.sage,
      //     isOp: post.op,
      //     counter: post.counter ?? 0,
      //     mediaFiles: [],
      //   );

      //   newPost.extras = {};
      //   newPost.replies = [];
      //   newPost.repliesParent = [];
      //   my.posts.box.put(newPost.toKey, newPost);
      // }

      // final length = my.posts.values.length;
      // my.prefs.setStats('posts_created', length);

    }

    if (step == 6) {
      final replies = my.posts.replies.length;
      my.prefs.setStats('replies_received', replies);

      final favsRefreshed = (my.prefs.stats['threads_clicked'] * 0.75).round();
      my.prefs.setStats('favs_refreshed', favsRefreshed);

      final mediaViews = (my.prefs.stats['threads_clicked'] * 0.55).round();
      my.prefs.setStats('media_views', mediaViews);
    }

    if (step == 7) {
      final favs = List<ThreadStorage>.from(my.favs.values);
      for (final fav in favs) {
        if (fav.refreshedAt == null || fav.extras == null || fav.extras.isEmpty) {
          fav.refreshedAt ??= DateTime.now().millisecondsSinceEpoch;
          fav.extras['last_post_ts'] ??= DateTime.now().millisecondsSinceEpoch;
          fav.save();
        }
      }

      final List<Board> boards = my.prefs.get("favorite_boards").cast<Board>();
      int i = 0;
      for (final board in boards) {
        board.index = i;
        i += 1;
      }
      my.prefs.put("favorite_boards", boards);
    }
  }
}
