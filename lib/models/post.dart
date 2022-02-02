import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/services/enums.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/htmlz.dart';
import 'package:ichan/services/my.dart' as my;
import 'media.dart';

part 'post.g.dart';

@HiveType(typeId: 5)
class Post extends HiveObject {
  Post({
    @required this.body,
    @required this.outerId,
    @required this.timestamp,
    @required this.boardName,
    @required this.threadId,
    this.title = '',
    this.name = '',
    this.tripcode = '',
    this.isOp = false,
    this.isBanned = false,
    this.counter = 0,
    this.email = '',
    this.isSage = false,
    this.isDeleted = false,
    this.isMine = false,
    this.isToMe = false,
    this.isUnread = false,
    this.mediaFiles,
    this.platform,
    this.repliesParent,
  });

  // required parse: replies, postId
  factory Post.fromMap(Map<String, dynamic> json) {
    final String _email = json['email'].replaceAll('mailto:', '');
    assert(json['threadId'] != null);
    assert(json['board'] != null);

    final _post = Post(
      title: json['subject'] as String,
      body: json['comment'] as String,
      threadId: json['threadId'] as String,
      boardName: json['board'] as String,
      name: json['name'] as String,
      tripcode: json['trip'] as String,
      timestamp: json['timestamp'] as int,
      isOp: json['op'] as int == 1,
      isBanned: json['banned'] as int == 1,
      outerId: json['postId'],
      counter: (json['number'] as int) ?? 0,
      email: _email,
      isSage: _email.toLowerCase() == "sage",
      mediaFiles: json['files'] ?? [],
      platform: json['platform'],
      repliesParent: json['repliesParent'] ?? [],
    );
    _post.replies = [];
    _post.extras = {};
    return _post;
  }

  factory Post.fromThread(Thread thread) {
    final _post = Post(
      title: thread.title,
      body: thread.body.isEmpty ? thread.title : thread.body,
      threadId: thread.outerId,
      boardName: thread.boardName,
      timestamp: thread.timestamp,
      outerId: thread.outerId,
      counter: 1,
      mediaFiles: thread.mediaFiles ?? [],
      platform: thread.platform,
      repliesParent: [],
    );
    _post.replies = [];
    _post.extras = {};
    return _post;
  }

  factory Post.fromPayload(Map<String, dynamic> payload) {
    final timestamp = payload['timestamp'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    assert(payload['boardName'] != null);

    final _post = Post(
      body: payload['body'],
      outerId: payload['postId'],
      threadId: payload['threadId'],
      boardName: payload['boardName'],
      timestamp: timestamp,
      name: payload['name'],
      isOp: payload['isOp'],
      isMine: payload['isMine'],
      isToMe: payload['isToMe'] ?? false,
      isUnread: payload['isUnread'] ?? false,
      platform: payload['platform'],
      mediaFiles: [],
    );

    _post.replies = [];
    _post.repliesParent = [];
    _post.extras = {};
    return _post;
  }

  @HiveField(0)
  String body;

  @HiveField(1)
  final String outerId;

  @HiveField(2)
  final int timestamp;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String name;

  @HiveField(5)
  final Platform platform;

  @HiveField(6)
  final String tripcode;

  @HiveField(7)
  final String email;

  @HiveField(8)
  final bool isOp;

  @HiveField(9)
  final bool isBanned;

  @HiveField(10)
  final bool isSage;

  @HiveField(11)
  int counter;

  @HiveField(12)
  List<Media> mediaFiles;

  @HiveField(13)
  List<String> repliesParent;

  @HiveField(14)
  List<String> replies;

  @HiveField(15)
  bool isDeleted;

  @HiveField(16)
  bool isMine;

  @HiveField(17)
  String boardName;

  @HiveField(18)
  String threadId;

  @HiveField(19)
  Map<String, dynamic> extras;

  @HiveField(20)
  bool isToMe;

  @HiveField(21)
  bool isUnread;

  String _cleanBody;
  String _nameToOutput;
  String threadUniques;

  bool isHighlighted = false;

  String get nameToOutput => _nameToOutput ??= setNameToOutput();

  String setNameToOutput() {
    String result;
    if (name.contains('span')) {
      final cleanedName = name
          .replaceAll('Аноним', '')
          .replaceAll(' based', '')
          .replaceAll('Google Android', 'Android')
          .replaceAll('Microsoft Windows', 'Windows');

      result = Htmlz.cleanTags(Htmlz.unescape(cleanedName));
    } else if (name.startsWith("ID")) {
      result = Htmlz.unescape(name).replaceAll('Аноним ', '');
    } else if (!name.contains(my.repo.on(platform).defaultAnonName)) {
      result = name;
    } else {
      result = '';
    }

    if (my.contextTools.isVerySmallHeight && result.length >= 10) {
      result = result.takeFirst(25, dots: "...");
    }

    return result;
  }

  String url(Thread thread) => "${thread.url}#$outerId";

  String toString() => "Title: $title, body: $body, outerId: $outerId";
  String get toKey => "${platform.toString()}-$boardName-$outerId";
  String get toThreadKey => "${platform.toString()}-$boardName-$threadId";

  bool get isNotEmpty => outerId != null;
  bool get isEmpty => !isNotEmpty;

  String get datetime => (timestamp * 1000).formatDate();
  String get cleanBody => _cleanBody ??= Htmlz.cleanTags(body);
  String get parsedBody => Htmlz.parseBody(body);
  String get quotedBody => cleanBody;
  String get nextId => (int.parse(outerId) + 1).toString();

  String get timeAgo => (timestamp * 1000).toHumanDate();

  bool get isPersisted {
    return my.posts.box.get(toKey) != null;
  }
}
