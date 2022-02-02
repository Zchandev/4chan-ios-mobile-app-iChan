import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/adapter.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/blocs/post_bloc.dart';
import 'package:ichan/services/exceptions.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:ichan/models/models.dart';

class MakabaApi {
  MakabaApi({@required this.domain});

  String domain;
  String get imageDomain => domain;
  String get webDomain => domain;

  static const nsfwCookie = 'usercode_auth=6e88330e8fb3548e79ceeb1f6ab28543';

  Dio dio({List<String> cookies, int timeout, String proxy}) {
    if (proxy == null) {
      timeout ??= my.prefs.getBool('slow_connection') ? 15000 : 7000;
    } else {
      timeout = 30000;
    }

    final options = BaseOptions(
      baseUrl: domain,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      receiveDataWhenStatusError: true,
      responseType: ResponseType.plain,
    );

    final dio = Dio(options);
    if (cookies == null || cookies.isEmpty) {
      final cookieJar = PersistCookieJar(dir: Consts.appDocDir.path);
      final uri = Uri.https("2ch.hk", '/');
      final cookies = cookieJar.loadForRequest(uri);
      final usercodeCookie =
          cookies.firstWhere((e) => e.name == 'usercode_auth', orElse: () => null);

      if (usercodeCookie == null) {
        dio.options.headers['cookie'] = nsfwCookie;
      } else {
        dio.interceptors.add(CookieManager(cookieJar));
      }
    } else {
      dio.options.headers['cookie'] = cookies.join("; ");
    }

    if (proxy != null) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.findProxy = (uri) => "PROXY $proxy";
      };
    }

    // dio.interceptors.add(InterceptorsWrapper(
    //   onRequest: (RequestOptions options) async {
    //     // Do something before request is sent
    //     if (options.path.contains('posting')) {
    //       print('headers = ${options.headers}');
    //       print('options.contentType = ${options.contentType}');
    //       inspect(options);
    //     }
    //     return options; //continue
    //     // If you want to resolve the request with some custom data，
    //     // you can return a `Response` object or return `dio.resolve(data)`.
    //     // If you want to reject the request with a error message,
    //     // you can return a `DioError` object or return `dio.reject(errMsg)`
    //   },
    // ));
    return dio;
  }

  Future<String> fetchThreads({String boardName}) async {
    final uri = '$domain/$boardName/catalog.json';

    return await _safeRequest(uri);
  }

  Future<String> fetchPagedThreads({String boardName, int page = 0}) async {
    final uri = '$domain/$boardName/${page == 0 ? 'index' : page}.json';

    return await _safeRequest(uri);
  }

  Future<Map<String, dynamic>> fetchBoards() async {
    const cacheKey = '2ch/categories';
    final cachedBody = my.prefs.getJsonCache(cacheKey);

    if (cachedBody.isNotEmpty) {
      return json.decode(cachedBody) as Map<String, dynamic>;
    }

    final response = await http.get('$domain/makaba/mobile.fcgi?task=get_boards');
    if (response.statusCode == 200) {
      my.prefs.putJsonCache(cacheKey, response.body);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<String> fetchThreadPosts(
      {String threadId, String boardName, String archiveDate = '', Thread thread}) async {
    if (thread != null) {
      threadId = thread.outerId;
      boardName = thread.boardName;
      archiveDate = thread.archiveDate;
    }
    final String uri = archiveDate.isNotEmpty
        ? '$domain/$boardName/arch/$archiveDate/res/$threadId.json'
        : '$domain/$boardName/res/$threadId.json';

    try {
      return await _safeRequest(uri);
    } on NotFoundException catch (_) {
      return await _fetchArchiveThread(uri);
    }
  }

  Future<String> fetchNewPosts({String threadId, String boardName, String startPostId}) async {
    final String uri =
        '$domain/makaba/mobile.fcgi?task=get_thread&board=$boardName&thread=$threadId&num=$startPostId';

    final response = await _safeRequest(uri);
    return response;
  }

  Future<String> fetchUsercode({String passcode}) async {
    final String uri = '$domain/makaba/makaba.fcgi?task=auth&json=1&usercode=$passcode';
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = json.decode(response.body) as Map<String, dynamic>;
      return Future.value(decoded["hash"] as String);
    } else {
      print('fetchUsercode error: response = $response');
    }

    return "";
  }

  Future<Map<String, dynamic>> createPost(
      {Map<String, dynamic> formData, List<String> cookies, CancelToken cancelToken}) async {
    const String uri = '/makaba/posting.fcgi';

    try {
      if (domain.endsWith('.pm')) {
        cancelToken = null;
      }

      final _dio = dio(cookies: cookies, timeout: 15000, proxy: _getProxy(formData['board']));

      final plainResponse = await _dio.post(
        uri,
        cancelToken: cancelToken,
        data: FormData.fromMap(formData),
        onSendProgress: (int sent, int total) {
          my.postBloc.add(AddProgress(bytesSent: sent, bytesTotal: total));
        },
      );

      final data = json.decode(plainResponse.data as String);

      Map<String, dynamic> result;
      if (data["Status"] == "OK") {
        result = {"ok": true, "data": data};
      } else {
        result = {"ok": false, "error": data["Reason"], "data": data};
      }

      return result;
    } on DioError catch (e) {
      print("Dio error is $e, message is ${e.message}");

      if (e.type == DioErrorType.CONNECT_TIMEOUT) {
        throw ConnectionTimeoutException();
        // } else if (e.type == DioErrorType.RESPONSE && e.error) {

      } else {
        throw MyException('Server error ${e?.response?.statusCode}');
      }
    }
  }

  Future<Map<String, dynamic>> createReport(
      {Map<String, dynamic> formData, List<String> cookies}) async {
    const String uri = '/makaba/makaba.fcgi?json=1';

    try {
      final plainResponse =
          await dio(cookies: cookies, timeout: 15000).post(uri, data: FormData.fromMap(formData));

      return json.decode(plainResponse.data as String);
    } on DioError catch (e) {
      print("Dio error is $e, message is ${e.message}");

      if (e.type == DioErrorType.CONNECT_TIMEOUT) {
        throw ConnectionTimeoutException();
      } else {
        throw MyException('Server error ${e?.response?.statusCode}');
      }
    }
  }

  Future<Map<String, dynamic>> createThread(
      {Map<String, dynamic> formData, List<String> cookies, CancelToken cancelToken}) async {
    const String uri = '/makaba/posting.fcgi';

    try {
      // pm does not work with http2
      if (domain.endsWith('.pm')) {
        cancelToken = null;
      }

      final _dio = dio(cookies: cookies, timeout: 15000, proxy: _getProxy(formData['board']));

      final plainResponse = await _dio.post(
        uri,
        cancelToken: cancelToken,
        data: FormData.fromMap(formData),
        onSendProgress: (int sent, int total) {
          my.postBloc.add(AddProgress(bytesSent: sent, bytesTotal: total));
        },
      );

      final data = json.decode(plainResponse.data as String);

      if (data["Status"] == "Redirect") {
        final cookie = plainResponse.headers['set-cookie'].first;
        return {"ok": true, "cookie": cookie, "threadId": data['Target']};
      } else {
        return {"ok": false, "error": data["Reason"], "data": data};
      }
    } on DioError catch (e) {
      print("Dio error is $e, message is ${e.message}");

      if (e.type == DioErrorType.CONNECT_TIMEOUT) {
        throw ConnectionTimeoutException();
      } else {
        throw MyException('Server error ${e?.response?.statusCode}');
      }
    }
  }

  Future<String> _safeRequest(String uri) async {
    try {
      final response = await dio().get(uri);
      // print('response = ${response}');
      return Future.value(response.data as String);
    } on DioError catch (e) {
      print("Got dio error: ${e.toString()}");
      if (e.type == DioErrorType.DEFAULT) {
        if (e.message.startsWith("SocketException")) {
          throw NoConnectionException();
        } else {
          throw MyException('Server error: ${e.message}');
        }
      } else if (e.type == DioErrorType.CONNECT_TIMEOUT) {
        throw UnavailableException();
      } else if (e.type == DioErrorType.RESPONSE) {
        final response = e.response;

        if (response.statusCode == 403) {
          throw ForbiddenException();
        } else if (response.statusCode == 404) {
          throw NotFoundException();
        } else if (response.statusCode == 500) {
          throw ServerErrorException();
        } else if (response.statusCode == 503 || response.statusCode == 502) {
          throw UnavailableException();
        } else {
          throw MyException('Server error: ${response?.statusCode}');
        }
      } else {
        throw MyException('Server error: ${e.toString()}');
      }
    }
  }

  Future<String> _fetchArchiveThread(String uri) async {
    final archiveUri = uri.replaceFirst('.json', '.html');
    try {
      final response = await dio().get(archiveUri);
      if (response.statusCode == 200) {
        final newUri = response.realUri.toString().replaceFirst('.html', '.json');
        return await _safeRequest(newUri);
      } else {
        throw NotFoundException();
      }
    } catch (e) {
      throw NotFoundException();
    }
  }

  String _getProxy(String boardName) {
    if (!my.prefs.getBool('dvach_proxy_enabled')) {
      return null;
    }
    final boards = my.prefs.getString('dvach_proxy_boards').replaceAll(' ', ',').split(',');
    if (boards.isEmpty || boards.contains(boardName)) {
      return my.prefs.getString('dvach_proxy').replaceFirst(RegExp(r'https?://'), '');
    }

    return null;
  }
}
