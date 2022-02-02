import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/models/platform.dart';
import 'package:ichan/services/exports.dart';

import 'package:ichan/services/my.dart' as my;

class ThreadParser {
  ThreadParser({this.threadData, this.threadStorage});
  final ThreadData threadData;
  final ThreadStorage threadStorage;

  final youMark = my.prefs.getString('you_mark', defaultValue: Consts.youMark);

  Platform get platform => threadData?.thread?.platform ?? threadStorage.platform;
  String get matchPost => platform == Platform.dvach ? ">>" : '&gt;&gt;';
  ThreadStorage get ts => threadData?.threadStorage ?? threadStorage;

  Future<void> appendPosts(List<Post> posts) async {
    int lastCounter = _getLastCounter();
    final lastPostId = _getLastPostId();

    for (final post in posts) {
      // print("Post is ${post.outerId}, files: ${post.mediaFiles.length}, lastPostId: $lastPostId");
      if (int.parse(post.outerId) > lastPostId) {
        if (lastCounter != null) {
          lastCounter += 1;
          post.counter = lastCounter;
        }

        _maybeMarkMine(post);
        for (final postId in post.repliesParent) {
          _processReply(post, postId);
          if (threadData != null) {
            _addReplyToParent(postId, post);
          }
        }

        if (threadData != null) {
          _appendToThreadData(post);
        }
      }
      // else {
      //   if (threadData != null && post.outerId == threadData.thread.outerId) {
      //     threadData.thread.mediaFiles += post.mediaFiles;
      //   }
      // }
    }
  }

  void _appendToThreadData(Post post) {
    if (post.mediaFiles.isNotEmpty) {
      threadData.thread.mediaFiles += post.mediaFiles;
    }
    threadData.posts.add(post);
  }

  void _maybeMarkMine(Post post) {
    final myPost = my.posts.get(post.toKey) as Post;
    if (myPost != null && myPost.isMine) {
      post.isMine = true;
      if (myPost.body != post.body) {
        my.posts.put(post.toKey, post);
      }
    }
  }

  // If there is a new reply for us, mark both thread and post and save it
  void _processReply(Post post, String postId) {
    final myPost = my.posts.get("${post.platform.toString()}-${post.boardName}-$postId") as Post;
    if (myPost != null && myPost.isMine == true) {
      ts.hasReplies = true;
      ts.putOrSave();
      if (!post.isPersisted) {
        post.isToMe = true;
        post.isUnread = true;
        my.posts.put(post.toKey, post);
        my.prefs.incrStats('replies_received');
      }

      post.body = post.body.replaceAll('$matchPost$postId<', '<b>$matchPost$postId </b>$youMark<');
    }
  }

  void _addReplyToParent(String postId, Post post) {
    final parentPost = threadData.posts?.firstWhere((e) => e.outerId == postId, orElse: () => null);
    if (parentPost != null && !parentPost.replies.contains(post.outerId)) {
      parentPost.replies.add(post.outerId);
    }
  }

  int _getLastCounter() {
    if (threadData == null) {
      return null;
    }
    return threadData.posts.isEmpty ? 0 : threadData.posts.last.counter;
  }

  int _getLastPostId() {
    if (threadData == null) {
      return int.tryParse(threadStorage.unreadPostId) ?? 0;
    } else {
      if (threadData.posts.isEmpty) {
        return 0;
      }

      return int.tryParse(threadData.posts.last.outerId);
    }
  }
}
