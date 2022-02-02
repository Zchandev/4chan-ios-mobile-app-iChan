import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:ichan/models/platform.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/models/media.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/services/extensions.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/services/htmlz.dart';

class Thread {
  Thread(
    this.outerId,
    this.boardName,
    this.title,
    this.platform, [
    this.body,
    this.timestamp,
    this.postsCount,
    this.filesCount,
    this.tags,
    this.uniquePosters,
    this.mediaFiles,
    this.isSticky = false,
    this.isEndless = false,
    this.isArchive = false,
    this.isClosed = false,
    this.archiveDate = '',
  ]);

  factory Thread.empty() {
    return Thread('', '', '', Platform.dvach, '');
  }

  factory Thread.fromThreadLink(ThreadLink threadLink) {
    final _thread = Thread(
      threadLink.outerId,
      threadLink.boardName,
      threadLink.titleOrBody,
      threadLink.platform,
    );
    _thread.archiveDate = threadLink.archiveDate;

    return _thread;
  }

  factory Thread.fromThreadStorage(ThreadStorage ts) {
    return Thread(
      ts.threadId,
      ts.boardName,
      ts.threadTitle,
      ts.platform,
    );
  }

  factory Thread.fromMap(Map<String, dynamic> json) {
    return Thread(
      json['num'].toString(),
      json['board'] as String,
      json['subject'] as String,
      json['platform'],
      (json['comment'] as String) ?? '',
      json['timestamp'] as int,
      json['posts_count'] as int,
      json['files_count'] as int,
      json['tags'] as String,
      json['unique_posters'] as int,
      json['files'],
      json['sticky'] > 0,
      json['endless'] == 1,
    );
  }

  final String title;
  final String boardName;
  final String body;
  final String outerId;
  final String tags;
  final int timestamp;
  final int postsCount;
  final int filesCount;
  final int uniquePosters;
  final bool isSticky;
  final bool isEndless;
  final Platform platform;
  List<Media> mediaFiles;

  String _parsedBody;
  String _cleanBody;
  String _cleanTitle;
  String _titleOrBody;
  bool _isTitleInBody;
  bool isArchive;
  bool isClosed;
  String archiveDate;

  bool get isNotEmpty => timestamp != null;
  bool get isEmpty => !isNotEmpty;

  String get url => my.repo.getThreadUrl(this, platform);

  String get toKey => toJsonId;

  String get toJsonId => "${platform.toString()}-$boardName-$outerId";

  String get parsedBody {
    _parsedBody ??= Htmlz.parseBody(body ?? '');
    return _parsedBody;
  }

  String get cleanBody {
    _cleanBody ??= Htmlz.cleanTags(body ?? '');
    return _cleanBody;
  }

  String get cleanTitle {
    _cleanTitle ??= Htmlz.unescape(Htmlz.cleanTags(title));
    return _cleanTitle;
  }

  bool get isTitleInBody {
    if (title.isEmpty) {
      return true;
    }

    if (_isTitleInBody == null) {
      final String _body = cleanBody.takeFirst(20).replaceAll(" ", '');
      final String _title = Htmlz.cleanTags(title).takeFirst(20).replaceAll(" ", '');
      _isTitleInBody = _body.startsWith(_title);
    }

    return _isTitleInBody;
  }

  String get shortBody {
    if (parsedBody.length >= Consts.bodyTrimSize) {
      final result = "${parsedBody.substring(0, Consts.bodyTrimSize)} ...";
      return result;
    } else {
      return parsedBody;
    }
  }

  String get previewBody {
    return "<thread>${shortBody.replaceAll('<br>', '\n')}</thread>";
  }

  String trimTitle(int length, {String dots = " ..."}) {
    final _title = cleanTitle.isEmpty ? cleanBody : cleanTitle;
    if (_title.length >= length) {
      return "${_title.substring(0, length)}$dots";
    } else {
      return _title;
    }
  }

  String get fullTitle {
    if (title?.isNotEmpty == true) {
      return Htmlz.unescape(title);
    } else {
      return titleOrBody;
    }
  }

  String get titleOrBody {
    final String _title = trimTitle(Consts.titleTrimSize);
    if (_title.isEmpty && body?.isNotEmpty == true) {
      final trimSize = min(cleanBody.length, Consts.titleTrimSize);

      _titleOrBody ??= Htmlz.unescape(cleanBody.substring(0, trimSize));
      return _titleOrBody;
    } else {
      return Htmlz.unescape(_title);
    }
  }

  String datetime({bool year = true, bool compact = false}) {
    return (timestamp * 1000).formatDate(year: year, compact: compact);
  }

  String timeAgo({bool year = true, bool compact = false}) =>
      (timestamp * 1000).toHumanDate(year: year, compact: compact);

  @override
  String toString() => "Thread ${title}, files: ${mediaFiles?.length}";
}

class ThreadLink {
  const ThreadLink({
    @required this.threadId,
    @required this.threadTitle,
    @required this.boardName,
    @required this.platform,
    this.postId = '',
    this.archiveDate = '',
  });

  final String threadId;
  final String threadTitle;
  final String postId;
  final String boardName;
  final String archiveDate;
  final Platform platform;
  bool get isArchive => archiveDate.isNotEmpty;

  factory ThreadLink.fromStorage(ThreadStorage ts) {
    return ThreadLink(
      threadId: ts.threadId,
      boardName: ts.boardName,
      threadTitle: ts.threadTitle,
      platform: ts.platform,
    );
  }

  // String get domain => my.makabaApi.platform;
  String get outerId => threadId;
  String get titleOrBody => threadTitle ?? threadId;
  String get toKey => toJsonId;
  String get toJsonId => "${platform.toString()}-$boardName-$outerId";
  String get url {
    if (platform == Platform.dvach) {
      return "${my.makabaApi.domain}/$boardName/res/$threadId.html";
    } else if (platform == Platform.fourchan) {
      return "${my.fourchanApi.domain}/$boardName/thread/$threadId";
    }

    throw Exception("Invalid platform");
  }

  bool get isFavorite => ThreadStorage.findById(toJsonId).isNotEmpty;

  @override
  String toString() => url;
}
