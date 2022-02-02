import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/repositories/2ch/makaba_api.dart';
import 'package:ichan/repositories/2ch/makaba_parser.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/image_process.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:meta/meta.dart';

import '../api_proxy.dart';

class MakabaProxy implements ApiProxy {
  MakabaProxy({@required this.api}) : assert(api != null);

  final MakabaApi api;

  final defaultAnonName = 'Аноним';
  final pagedBoards = ['me', 'gd', 'd'];
  static const platform = Platform.dvach;

  Future<Map<String, dynamic>> fetchBoards() async {
    final json = await api.fetchBoards();
    final List<Board> boards = [];
    final List<String> categories = [];

    json.forEach((category, boardsGroup) {
      final regularFilter = category != "Взрослым" && category != 'Пользовательские';
      final nsfwFilter = my.prefs.getBool('dvach_nsfw') && category == 'Взрослым';
      final userboardFilter =
          my.prefs.getBool('dvach_userboards') && category == 'Пользовательские';

      if (regularFilter || nsfwFilter || userboardFilter) {
        categories.add(category);
      }

      boardsGroup.forEach((board) {
        final Map<String, dynamic> _board = board as Map<String, dynamic>;
        _board['platform'] = Platform.dvach;
        _board['nsfw'] = category == 'Взрослым';
        boards.add(Board.fromMap(_board));
      });
    });

    return {'boards': boards, 'categories': categories};
  }

  Future<List<Thread>> fetchThreads({String boardName}) async {
    print('Fetching threads in /$boardName/');
    if (pagedBoards.contains(boardName)) {
      return await fetchPagedThreads(boardName: boardName);
    }

    final undecoded = await api.fetchThreads(boardName: boardName);
    final args = {"data": undecoded, "domain": api.domain};

    if (my.prefs.getBool("async_disabled")) {
      if (!isDebug) {
        print("ASYNC OFF");
      }
      return await makabaProcessThreads(args);
    } else {
      return await compute(makabaProcessThreads, args);
    }
  }

  Future<List<Thread>> fetchPagedThreads({String boardName}) async {
    // print('Fetching paged threads in /$boardName/');
    final undecoded = await api.fetchPagedThreads(boardName: boardName);

    // if (my.prefs.getBool("async_disabled")) {
    // print("ASYNC OFF");
    return await makabaProcessPagedThreads(undecoded, boardName: boardName);
    // } else {
    //   return await compute(processThreads, undecoded);
    // }
  }

  Future<Map<String, dynamic>> deletePost(Map<String, dynamic> payload) async {
    return Future.value({});
  }

  Future<Map<String, dynamic>> fetchThreadPosts({Thread thread, String savedJson = ''}) async {
    // print('Fetching posts in thread /$boardName/$threadId');
    String undecoded =
        savedJson.isNotEmpty ? savedJson : await api.fetchThreadPosts(thread: thread);

    if (pagedBoards.contains(thread.boardName)) {
      undecoded = undecoded.replaceAll(r'\\r\\n', '');
    }

    final args = {"data": undecoded, "domain": api.domain};

    if (my.prefs.getBool("async_disabled")) {
      if (!isDebug) {
        print("ASYNC OFF");
      }
      return await makabaProcessPosts(args);
    } else {
      final result = await compute(makabaProcessPosts, args);
      return result;
    }
  }

  Future<List<Post>> fetchNewPosts(
      {@required String threadId, @required String boardName, @required String startPostId}) async {
    final start = int.tryParse(startPostId);
    final String nextPostId = (start + 1).toString();
    final response =
        await api.fetchNewPosts(threadId: threadId, boardName: boardName, startPostId: nextPostId);

    final result = json.decode(response);
    if (result.isNotEmpty == true &&
        result is Map &&
        result.containsKey("Code") &&
        result["Code"] == -404) {
      throw NotFoundException();
    }

    return (result as List).map<Post>((json) {
      json['domain'] = my.makabaApi.domain;
      json['threadId'] = threadId;
      json['board'] = boardName;
      return makabaBuildPost(json);
    }).toList();
  }

  Future<String> fetchUsercode({String passcode}) async {
    print('fetchUsercode for passcode: $passcode');

    return await api.fetchUsercode(passcode: passcode);
  }

  Future<Map<String, dynamic>> createPost(
      {Map<String, dynamic> payload, CancelToken cancelToken}) async {
    print('createPost: $payload');

    final email = payload['isSage'] ? 'sage' : '';

    final Map<String, dynamic> formData = {
      'task': 'post',
      'board': payload['boardName'],
      'thread': payload['threadId'],
      'comment': payload['body'],
      'email': email,
      'name': payload['name'] ?? '',
      'op_mark': payload['isOp'] ? '1' : '',
    };

    if (payload['g-recaptcha-response'] != null) {
      formData["captcha_type"] = "recaptcha";
      formData["captcha-key"] = payload['captcha-key'];
      formData["g-recaptcha-response"] = payload['g-recaptcha-response'];
    }

    if (payload["files"] != null) {
      formData['formimages'] = await ImageProcess.filesToUpload(payload['files'] as List<File>);
    }

    final cookies = await getCookies(payload);
    final result = await api.createPost(
      formData: formData,
      cookies: cookies,
      cancelToken: cancelToken,
    );

    if (result['ok']) {
      result['postId'] = result['data']['Num'].toString();
    }
    return result;
  }

  Future<Map<String, dynamic>> createReport({Map<String, dynamic> payload}) async {
    print('createReport: $payload');

    final Map<String, dynamic> formData = {
      'task': 'report',
      'board': payload['boardName'],
      'thread': payload['threadId'],
      'posts': payload['postId'],
      'comment': payload['comment'],
    };

    final cookies = await getCookies(payload);
    final result = await api.createReport(
      formData: formData,
      cookies: cookies,
    );

    if (result['message'] == '') {
      return {"ok": true};
    } else {
      return {"ok": false, "error": result['message']};
    }
  }

  Future<Map<String, dynamic>> createThread(
      {Map<String, dynamic> payload, CancelToken cancelToken}) async {
    print('createThread: $payload');

    final email = payload['isSage'] ? 'sage' : '';

    final Map<String, dynamic> formData = {
      'task': 'post',
      'board': payload['boardName'],
      'subject': payload['title'],
      'comment': payload['body'],
      'email': email,
      'name': payload['name'] ?? '',
      'op_mark': payload['isOp'] ? '1' : '',
    };

    if (payload['g-recaptcha-response'] != null && payload['g-recaptcha-response'].isNotEmpty) {
      formData["captcha_type"] = "recaptcha";
      formData["captcha-key"] = payload['captcha-key'];
      formData["g-recaptcha-response"] = payload['g-recaptcha-response'];
    }

    if (payload["files"] != null) {
      formData['formimages'] = await ImageProcess.filesToUpload(payload['files'] as List<File>);
    }

    try {
      final cookies = await getCookies(payload);
      final result = await api.createThread(
        formData: formData,
        cookies: cookies,
        cancelToken: cancelToken,
      );

      return result;
    } on UnavailableException catch (_) {
      return {"ok": false, "error": 'errors.unavailable'.tr()};
    } on ConnectionTimeoutException catch (_) {
      return {"ok": false, "error": 'errors.post_timeout'.tr()};
    } catch (e) {
      Log.error("Thread creating error", error: e);
      return {"ok": false, "error": e.toString()};
    }
  }

  Future<String> _passcodeCookie(Map<String, dynamic> payload) async {
    if (my.prefs.showCaptcha) {
      return Future.value('');
    }

    final String code = await _getUsercode();

    if (code.isNotEmpty) {
      return Future.value('passcode_auth=$code');
    }

    return '';
  }

  Future<List<String>> getCookies(Map<String, dynamic> payload) async {
    final List<String> cookies = [];
    final passcodeCookie = await _passcodeCookie(payload);
    if (passcodeCookie.isNotEmpty) {
      cookies.add(passcodeCookie);
    }

    if (payload['isOp'] == true) {
      final fav = ThreadStorage.find(
        threadId: payload['threadId'],
        boardName: payload['boardName'],
        platform: platform,
      );
      if (fav.isNotEmpty && fav.opCookie.isNotEmpty) {
        cookies.add(fav.opCookie);
      }
    }
    return Future.value(cookies);
  }

  Future<String> _getUsercode() async {
    String result = '';
    if (my.prefs.showCaptcha) {
      return '';
    }

    final passcode = my.prefs.getString('passcode');
    final key = "2ch/$passcode/code";

    result = await my.secstore.get('usercode');
    if (result != null && result.isNotEmpty) {
      print("Saving new passcode");
      my.secstore.put(key, result);
      my.secstore.delete('usercode');
    }

    result = await my.secstore.get(key);

    if ((result == null || result.isEmpty) && passcode.isNotEmpty) {
      final response = await fetchUsercode(passcode: passcode);
      print('fetchUsercode response = $response');
      if (response == null || response.isNotEmpty) {
        result = response;
        my.secstore.put(key, response);
      } else {
        print("Got empty usercode for $passcode");
      }
    }

    return result ?? '';
  }
}
