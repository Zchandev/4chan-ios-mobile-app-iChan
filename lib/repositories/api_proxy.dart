import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/models/post.dart';
import 'package:ichan/models/thread.dart';

abstract class ApiProxy {
  Future<Map<String, dynamic>> fetchBoards();

  Future<List<Thread>> fetchThreads({String boardName});

  Future<List<Thread>> fetchPagedThreads({String boardName});

  Future<Map<String, dynamic>> fetchThreadPosts({Thread thread, String savedJson});

  Future<List<Post>> fetchNewPosts(
      {@required String threadId, @required String boardName, @required String startPostId});

  Future<String> fetchUsercode({String passcode});

  Future<Map<String, dynamic>> createPost({Map<String, dynamic> payload, CancelToken cancelToken});

  Future<Map<String, dynamic>> createReport({Map<String, dynamic> payload});

  Future<Map<String, dynamic>> createThread(
      {Map<String, dynamic> payload, CancelToken cancelToken});

  Future<Map<String, dynamic>> deletePost(Map<String, dynamic> payload);

  dynamic get api => null;
  String get defaultAnonName => null;
}
