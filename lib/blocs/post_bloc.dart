import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:ichan/blocs/thread/event.dart';
// import 'package:ichan/db/app_db.dart';
import 'package:ichan/models/post.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/models/thread_storage.dart';

import 'package:ichan/repositories/repositories.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/ui/haptic.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

// BLOC
class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc({@required this.repo}) : super(PostEmpty());

  final Repo repo;
  CancelableOperation cancelableOperation;
  bool toCancel = false;
  CancelToken cancelToken;

  void addQuote({String postId, String text, ThreadStorage fav}) {
    String postBody = fav.extras['body'] ?? '';
    text ??= "";

    String result = "";
    if (postId != null && postBody.contains(postId) == false) {
      result = ">>$postId";
    }
    if (text.isNotEmpty) {
      final replacedText = text
          .replaceAllMapped(RegExp(r'>>\d+(\s.{0,5})?\n'), (match) => '')
          .replaceAllMapped(RegExp(r'^(.+)$', multiLine: true), (match) => ">${match.group(1)}");

      result = "${result.trim()}\n$replacedText";
    }
    if (result.isEmpty) {
      return;
    }

    if (postBody.trim().isEmpty) {
      postBody = "$result\n";
    } else {
      postBody = "${postBody.trim()}\n$result\n";
    }

    fav.extras['body'] = postBody;
    fav.putOrSave();
  }

  void addText(String text, {ThreadStorage fav}) {
    String postBody = fav.extras['body'] ?? '';
    if (postBody.trim().endsWith(text) == false) {
      if (postBody.trim().isNotEmpty) {
        postBody += "\n";
      }
      fav.extras['body'] = "$postBody$text\n";
      fav.putOrSave();
    }
  }

  @override
  Stream<PostState> mapEventToState(PostEvent event) async* {
    if (event is PostCreateSuccess) {
      yield PostCreated();
      yield PostEmpty();
      Haptic.heavyImpact();
    } else if (event is ThreadCreateSuccess) {
      yield ThreadCreated(threadLink: event.threadLink);

      yield PostEmpty();
      Haptic.heavyImpact();
    } else if (event is CreateError) {
      yield PostError(message: event.message, files: state.files);
      Haptic.heavyImpact();
      // inProgress = false;
    } else if (event is CreateCancel) {
      cancelableOperation?.cancel();
      yield PostFill(files: state.files);
      // inProgress = false;
    } else if (event is AddFiles) {
      final currentFiles = state.files ?? [];
      if (event.url != null) {
        final List<File> _pendingFiles = currentFiles + [null];
        yield PostFill(files: _pendingFiles);
        final media = await my.cacheManager.getSingleFile(event.url);
        final _newFiles = currentFiles + [media];
        yield PostFill(files: _newFiles);
      } else if (event.sharedFiles != null) {
        final List<File> newFiles = [];
        for (final f in event.sharedFiles) {
          print('f.path = ${f.path}');
          newFiles.add(File(f.path));
        }

        yield PostFill(files: currentFiles + newFiles);
      } else if (event.files != null) {
        yield PostFill(files: currentFiles + event.files);
      }
    } else if (event is RemoveFile) {
      state.files.remove(event.file);
      yield PostFill(files: state.files, removedFile: event.file);
    } else if (event is AddProgress) {
      final percent = event.bytesSent / event.bytesTotal;
      // print('${event.bytesSent} ${event.bytesTotal}');
      // print('percent = ${percent}');
      yield PostCreating(files: state.files, percent: percent);
    } else if (event is CreateThread) {
      // try {
      yield PostCreating(files: state.files, percent: 0.0);

      cancelToken = CancelToken();
      final payload = event.payload;
      payload['files'] = state.files;

      cancelableOperation = CancelableOperation.fromFuture(
        createThread(payload, cancelToken: cancelToken),
        onCancel: () {
          cancelToken.cancel();
          toCancel = true;
        },
      );

      cancelableOperation.value.then((result) {
        if (result["ok"] == true) {
          try {
            payload['threadId'] = result['threadId'].toString();
            payload['opcode'] = result['cookie'];

            final titleOrBody = payload['title'].isEmpty ? payload['body'] : payload['title'];

            final fav = ThreadStorage(
              platform: payload['platform'],
              boardName: payload['boardName'],
              threadId: payload['threadId'],
              threadTitle: titleOrBody,
              opCookie: payload['opcode'],
              isFavorite: true,
              ownPostsCount: 1,
            );

            fav.putOrSave();
            createLocalThread(payload);

            final threadLink = ThreadLink(
              boardName: payload['boardName'],
              threadId: payload['threadId'],
              threadTitle: titleOrBody,
              platform: payload['platform'],
            );

            my.prefs.incrStats('threads_created');

            add(ThreadCreateSuccess(threadLink: threadLink));
          } catch (e) {
            Log.error("Something went wrong in after post events", error: e);
            add(const CreateError(message: "Something went wront"));
          }
        } else {
          add(CreateError(message: result["error"] as String));
        }
      });
      // } catch (error) {
      //   yield PostError(message: error as String, files: state.files);
      // }
    } else if (event is CreatePost) {
      try {
        yield PostCreating(files: state.files, percent: 0.0);
        cancelToken = CancelToken();

        final payload = event.payload;
        payload['files'] = state.files;
        if (payload['body'] != " ") {
          payload['body'] = payload['body'].trim();
        }
        if (["сажа", "сажи", "сажу", "sage"].contains(payload['body'].toLowerCase())) {
          payload['isSage'] = true;
        }

        // in case of replace postcount to russian letters
        if (_checkPostcount(payload['body'])) {
          payload['body'] = await _calcPostcount();
        }

        cancelableOperation = CancelableOperation.fromFuture(
          createPost(payload, cancelToken: cancelToken),
          onCancel: () {
            cancelToken.cancel();
            toCancel = true;
          },
        );

        cancelableOperation.value.then((result) {
          if (result["ok"] == true) {
            payload["postId"] = result['postId'];

            createLocalPost(payload);
            // to show cooldown
            my.prefs.put('last_post_ts', DateTime.now().millisecondsSinceEpoch);

            final thread = payload['form'].thread;
            final currentData = my.threadBloc.getThreadData(thread.toKey);

            if (!my.prefs.getBool('fav_on_reply_disabled') &&
                payload['isSage'] == false &&
                payload['boardName'] != 'test') {
              currentData.addFavorite();
            }

            final ts = currentData?.threadStorage;
            if (ts != null && ts.isNotEmpty) {
              ts.unreadPostId = payload["postId"];
              print("NEW  ts.unreadPostId= ${ts.unreadPostId}");
              ts.ownPostsCount += 1;
              if (payload['isSage'] && payload['body'].toLowerCase().endsWith('скрыл')) {
                ts.isHidden = true;
              }
              ts.putOrSave();
            }

            print("Creating post");
            add(PostCreateSuccess());
            my.threadBloc.add(ThreadRefreshStarted(thread: thread));
          } else {
            add(CreateError(message: result["error"] as String));
          }
        });
      } catch (error) {
        yield PostError(message: error as String, files: state.files);
      }
    } else if (event is ClearBody) {
      // postBody = "";
      yield const PostFill(files: []);
    }
  }

  bool _checkPostcount(String body) {
    return body.toLowerCase().startsWith(RegExp(r'.{0,1}/[p|р][o|о]st[c|с][o|о]unt'));
  }

  Future<String> _calcPostcount() async {
    const version = "iChan";

    final stats = """/postcount

  ${'stats.threads_visited'.tr()} ${my.prefs.stats['threads_visited']}
  ${'stats.threads_clicked'.tr()} ${my.prefs.stats['threads_clicked']}
  ${'stats.threads_created'.tr()} ${my.prefs.stats['threads_created']}
  ${'stats.posts_created'.tr()} ${my.prefs.stats['posts_created']}
  ${'stats.replies_received'.tr()} ${my.prefs.stats['replies_received']}
  ${'stats.media_views'.tr()} ${my.prefs.stats['media_views']}
  ${'stats.favs_refreshed'.tr()} ${my.prefs.stats['favs_refreshed']}
  ${'stats.hours_spent'.tr()} ${my.prefs.stats['visits'] * 3 ~/ 60}

  [i]${'stats.sent_from'.tr()} $version ${Consts.version}[/i]""";

    return stats;
  }

  Future<bool> _maybeCancel(PostState state, String postBody) async {
    double delay = 0.5;

    if (state.files != null && state.files.isNotEmpty) {
      delay += 1;
    }

    if (postBody.length >= 100) {
      delay += 1;
    }

    await Future.delayed(delay.seconds);

    if (toCancel) {
      toCancel = false;
      return Future.value(true);
    }

    return Future.value(false);
  }

  Future<Map<String, dynamic>> createPost(payload, {CancelToken cancelToken}) async {
    final isCancel = await _maybeCancel(state, payload['body']);
    if (isCancel) {
      return {};
    }

    if (!isDebug) {
      my.analytics.logEvent(
          name: 'reply',
          parameters: {'threadId': payload['threadId'], 'boardName': payload['boardName']});
    }

    Map<String, dynamic> response;
    try {
      response =
          await repo.on(payload['platform']).createPost(payload: payload, cancelToken: cancelToken);
    } on UnavailableException catch (_) {
      response = {
        "ok": false,
        "error": 'errors.unavailable'.tr(),
      };
    } on ConnectionTimeoutException catch (_) {
      response = {
        "ok": false,
        "error": 'errors.post_timeout'.tr(),
      };
    } catch (e) {
      response = {"ok": false, "error": e.toString()};
    }

    toCancel = false;
    return response;
  }

///////////////////////////////////////////////////////////////
  Future<Map<String, dynamic>> createThread(Map payload, {CancelToken cancelToken}) async {
    final isCancel = await _maybeCancel(state, payload['body']);
    if (isCancel) {
      return {};
    }

    my.analytics.logEvent(
      name: 'create_thread',
      parameters: {
        'title': payload['title'],
        'body': payload['body'],
        'boardName': payload['boardName']
      },
    );

    // final cookies = await getCookies(payload);
    final response =
        await repo.on(payload['platform']).createThread(payload: payload, cancelToken: cancelToken);

    // print("Response is $response");
    toCancel = false;
    return response;
  }

  // void rickrollCheck() {
  //   if (my.prefs.getBool('rickroll')) {
  //     final _body = postBody.toLowerCase().trim();
  //     const regexp =
  //         r'(говно|пиздец|хуй|бля|ебал|ебан|рикролл|хуй|сель|шкур|шлюх|шалав)';
  //     if ((_body.endsWith('отправлено с ichan') ||
  //             _body.endsWith('отправлено с ichan.')) &&
  //         RegExp(regexp).hasMatch(_body) == false) {
  //       print("Off");
  //       // my.player.stop();
  //       my.prefs.put('rickroll', false);
  //     } else {
  //       print("on");
  //     }
  //   }
  // }

  void createLocalPost(Map<String, dynamic> payload) {
    assert(payload['boardName'] != null);
    payload['isMine'] = true;
    final post = Post.fromPayload(payload);

    my.posts.put(post.toKey, post);
    my.prefs.incrStats('posts_created');
  }

  void createLocalThread(Map<String, dynamic> payload) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final post = Post(
      body: payload['body'],
      title: payload['title'],
      outerId: payload['postId'],
      threadId: payload['threadId'],
      boardName: payload['boardName'],
      timestamp: timestamp,
      name: payload['name'],
      isOp: payload['isOp'],
      isMine: true,
      counter: 1,
      platform: payload['platform'],
    );

    post.extras = {"opcode": payload['cookie']};

    // final thread = ThreadEntityData.fromJson(threadRecord);
    // my.db.insertThread(thread);
    my.posts.put(post.toKey, post);
  }
}

// EVENT
abstract class PostEvent extends Equatable {
  const PostEvent();

  Thread get thread => null;
}

class CreatePost extends PostEvent {
  const CreatePost(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object> get props => [payload];
}

class CreateReport extends PostEvent {
  const CreateReport(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object> get props => [payload];
}

class CreateThread extends PostEvent {
  const CreateThread(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object> get props => [payload];
}

class QuotePost extends PostEvent {
  const QuotePost({this.quotedId});

  final String quotedId;

  @override
  List<Object> get props => [quotedId];
}

class AddFiles extends PostEvent {
  const AddFiles({this.files, this.sharedFiles, this.url});

  final List<File> files;
  final List<SharedMediaFile> sharedFiles;
  final String url;

  @override
  List<Object> get props => [files, sharedFiles, url];
}

class AddProgress extends PostEvent {
  const AddProgress({this.bytesSent, this.bytesTotal});

  final int bytesSent;
  final int bytesTotal;

  @override
  List<Object> get props => [bytesSent, bytesTotal];
}

class RemoveFile extends PostEvent {
  const RemoveFile({this.file});

  final File file;

  @override
  List<Object> get props => [file];
}

class CreateCancel extends PostEvent {
  @override
  List<Object> get props => [];
}

class PostCreateSuccess extends PostEvent {
  @override
  List<Object> get props => [];
}

class ThreadCreateSuccess extends PostEvent {
  const ThreadCreateSuccess({this.threadLink});

  final ThreadLink threadLink;

  @override
  List<Object> get props => [threadLink];
}

class ClearBody extends PostEvent {
  @override
  List<Object> get props => [];
}

class CreateError extends PostEvent {
  const CreateError({this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

// STATE
abstract class PostState extends Equatable {
  const PostState({this.files});

  final List<File> files;

  double get percent => 0.0;

  @override
  List<Object> get props => [files];
}

class PostEmpty extends PostState {}

class PostFill extends PostState {
  const PostFill({this.files, this.removedFile});

  final File removedFile;
  final List<File> files;

  @override
  List<Object> get props => [files, removedFile];
}

class PostCreating extends PostState {
  const PostCreating({this.files, this.percent = 0.0});

  final List<File> files;
  final double percent;

  @override
  List<Object> get props => [files, percent];
}

class PostCreated extends PostState {}

class ThreadCreated extends PostState {
  const ThreadCreated({this.threadLink});

  final ThreadLink threadLink;

  @override
  List<Object> get props => [threadLink];
}

class PostError extends PostState {
  const PostError({this.message, this.files});

  final String message;
  final List<File> files;

  @override
  List<Object> get props => [message];
}
