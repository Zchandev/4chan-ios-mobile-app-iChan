import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ichan/models/board.dart';
import 'package:ichan/models/platform.dart';
import 'package:ichan/models/post.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/repositories/4chan/fourchan_api.dart';
import 'package:ichan/repositories/4chan/fourchan_parser.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/image_process.dart';
import 'package:ichan/services/my.dart' as my;

import '../api_proxy.dart';

class FourchanProxy implements ApiProxy {
  FourchanProxy({this.api});
  FourchanApi api;

  final defaultAnonName = 'Anonymous';
  static const platform = Platform.fourchan;

  Future<Map<String, dynamic>> deletePost(Map<String, dynamic> payload) async {
    print('deletePost: $payload');

    final Map<String, dynamic> formData = {
      'board': payload['boardName'],
      'mode': 'usrdel',
      'res': payload['threadId'],
      'pwd': '',
      payload['postId']: 'delete',
    };

    final cookies = await getCookies();
    final result = await api.deletePost(formData, cookies: cookies);
    return result;
  }

  Future<Map<String, dynamic>> createPost(
      {Map<String, dynamic> payload, CancelToken cancelToken}) async {
    print('createPost: $payload');

    final email = payload['isSage'] ? 'sage' : '';

    final Map<String, dynamic> formData = {
      'mode': 'regist',
      'board': payload['boardName'],
      'resto': payload['threadId'],
      'com': payload['body'],
      'email': email,
      'name': payload['name'] ?? '',
    };

    if (payload['g-recaptcha-response'] != null) {
      formData["g-recaptcha-response"] = payload['g-recaptcha-response'];
    }

    if (payload["files"] != null) {
      final files = payload['files'] as List<File>;
      formData['upfile'] = await ImageProcess.fileToUpload(files.first);
    }

    final cookies = await getCookies();
    final result = await api.createPost(
      formData: formData,
      cookies: cookies,
      cancelToken: cancelToken,
    );

    if (result.containsKey('cookie') && result['cookie'].isNotEmpty) {
      my.prefs.put('4chan_cookie', result['cookie']);
    }

    return result;
  }

  @override
  Future<Map<String, dynamic>> createReport(
      {Map<String, dynamic> payload, CancelToken cancelToken}) async {
    // TODO: implement createReport
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> createThread(
      {Map<String, dynamic> payload, CancelToken cancelToken}) {
    // TODO: implement createThread
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchBoards() async {
    final json = await api.fetchBoards();
    final List<Board> boards = [];
    final List<String> categories = ["Boards"];

    if (my.prefs.getBool('fourchan_nsfw')) {
      categories.add("NSFW Boards");
    }

    for (final board in json['boards']) {
      final nsfw = board['ws_board'] == 0;
      boards.add(Board.fromMap({
        'id': board['board'],
        'name': board['title'],
        'category': nsfw ? 'NSFW Boards' : 'Boards',
        'bump_limit': board['bump_limit'],
        'platform': Platform.fourchan,
        'nsfw': nsfw,
      }));
    }

    return {'boards': boards, 'categories': categories};
  }

  @override
  Future<List<Post>> fetchNewPosts(
      {@required String threadId, @required String boardName, @required String startPostId}) async {
    final start = int.tryParse(startPostId);
    final nextPostId = start + 1;
    final undecoded = await api.fetchThreadPosts(threadId: threadId, boardName: boardName);

    final args = {
      "data": undecoded,
      "domain": FourchanApi.imageDomain,
      "board": boardName,
    };

    final decoded = await fourchanProcessPosts(args, startPostId: nextPostId);
    if ((decoded['thread'] as Thread).isClosed) {
      print("CLOSED");
    }
    return decoded['posts'].cast<Post>();
  }

  @override
  Future<List<Thread>> fetchPagedThreads({String boardName}) {
    // TODO: implement fetchPagedThreads
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchThreadPosts({Thread thread, String savedJson = ''}) async {
    print('4chan: Fetching posts in thread /${thread.boardName}/${thread.outerId}');

    final undecoded = savedJson.isNotEmpty
        ? savedJson
        : await api.fetchThreadPosts(threadId: thread.outerId, boardName: thread.boardName);

    final args = {
      "data": undecoded,
      "domain": FourchanApi.imageDomain,
      "board": thread.boardName,
    };

    if (my.prefs.getBool('async_disabled')) {
      if (!isDebug) {
        print('ASYNC OFF');
      }
      return await fourchanProcessPosts(args);
    } else {
      final result = await compute(fourchanProcessPosts, args);
      return result;
    }
  }

  @override
  Future<List<Thread>> fetchThreads({String boardName}) async {
    print('4CHAN: fetching threads in /$boardName/');
    final undecoded = await api.fetchThreads(boardName: boardName);
    final args = {"data": undecoded, "domain": FourchanApi.imageDomain, "board": boardName};

    if (my.prefs.getBool("async_disabled")) {
      if (!isDebug) {
        print("ASYNC OFF");
      }
      return await fourchanProcessThreads(args);
    } else {
      return await compute(fourchanProcessThreads, args);
    }
  }

  @override
  Future<String> fetchUsercode({String passcode}) {
    // TODO: implement fetchUsercode
    throw UnimplementedError();
  }

  Future<List<String>> getCookies() async {
    final List<String> cookies = [];
    // cookies.add(
    //     '4chan_pass=Aenqq27zn0tdOThljHmGecXzS01f80tNX_NLTV9_SVFfhRpNdV92BUyo59yEVcsy7lDEacmdriiKFfDfNxRAFjuT7d1uWtQFqijqfrEsnXkn2KA50-NNgJHOZxgi');

    return Future.value(cookies);
  }
}
