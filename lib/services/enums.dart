export 'package:iChan/models/platform.dart';

enum ThreadStatus {
  empty, // first time visit thread only by link
  partial, // when we have first post
  cached, // when we already have posts but not fresh one
  loaded, // when we already have all posts
}

enum Origin {
  board,
  thread,
  gallery,
  reply,
  search,
  mediaInfo,
  activity,
  navigator,
  favorites,
  example,
}
