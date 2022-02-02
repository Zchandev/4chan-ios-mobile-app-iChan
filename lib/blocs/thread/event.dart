import 'package:flutter/cupertino.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:equatable/equatable.dart';
import 'package:ichan/models/post.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/models/thread_storage.dart';

//////////////////////////////
/////////  EVENTS  ///////////
//////////////////////////////
abstract class ThreadEvent extends Equatable {
  const ThreadEvent();
}

class ThreadFetchStarted extends ThreadEvent {
  const ThreadFetchStarted({
    @required this.thread,
    this.scrollPostId = '',
    this.force = false,
  });

  final Thread thread;
  final String scrollPostId;
  final bool force;

  @override
  List<Object> get props => [thread, scrollPostId, force];
}

class ThreadPostsAppended extends ThreadEvent {
  const ThreadPostsAppended({@required this.posts, this.fav});

  final ThreadStorage fav;
  final List<Post> posts;

  @override
  List<Object> get props => [posts, fav];
}

class ThreadRefreshStarted extends ThreadEvent {
  const ThreadRefreshStarted({
    @required this.thread,
    this.scroll = false,
    this.delay,
  });

  final Thread thread;
  final bool scroll;
  final Duration delay;

  @override
  List<Object> get props => [thread];
}

class ThreadScrollStarted extends ThreadEvent {
  const ThreadScrollStarted({
    this.to,
    this.postId,
    this.index,
    @required this.thread,
  });

  final String to;
  final String postId;
  final int index;
  final Thread thread;

  @override
  List<Object> get props => [to, postId, index, thread];
}

class ThreadReturned extends ThreadEvent {
  const ThreadReturned({this.threadData});

  final ThreadData threadData;

  @override
  List<Object> get props => [threadData];
}

class SearchPost extends ThreadEvent {
  const SearchPost({this.query});

  final String query;

  @override
  List<Object> get props => [query];
}

class ThreadClosed extends ThreadEvent {
  const ThreadClosed({this.threadData});

  final ThreadData threadData;

  @override
  List<Object> get props => [threadData];
}

class ThreadCacheDisabled extends ThreadEvent {
  const ThreadCacheDisabled();

  @override
  List<Object> get props => [];
}

class ThreadReportPressed extends ThreadEvent {
  const ThreadReportPressed(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object> get props => [payload];
}

class ThreadDeletePressed extends ThreadEvent {
  const ThreadDeletePressed({this.post});

  final Post post;

  @override
  List<Object> get props => [post];
}

class ThreadSearchStarted extends ThreadEvent {
  const ThreadSearchStarted({
    @required this.thread,
    @required this.query,
    this.pos = 1,
  });

  final Thread thread;
  final String query;
  final int pos;

  @override
  List<Object> get props => [thread, query, pos];
}
