import 'dart:convert';
import 'package:ichan/models/media.dart';
import 'package:ichan/models/platform.dart';
import 'package:ichan/models/post.dart';
import 'package:ichan/models/thread.dart';

List<Media> fourchanFilesToMedia(Map json) {
  if (json['filename'] == null) {
    return [];
  }

  final name = json['filename'] as String;
  final ext = json['ext'].toString().replaceFirst('.', '');

  assert(json['postId'] != null);

  final list = [
    {
      "filename": json['filename'] as String,
      "fullname": json['filename'] as String,
      "name": '$name.$ext',
      "path": '/${json["board"]}/${json["tim"]}.$ext',
      "thumbnail": '/${json["board"]}/${json["tim"]}s.jpg',
      "md5": json['md5'] as String,
      "nsfw": 0,
      "postId": json['postId'],
      "ext": ext,
      "size": json['fsize'] ~/ 1024,
      "width": json['w'],
      "height": json['h'],
    }
  ];

  return list.map<Media>((e) => Media.fromMap(e, json['domain'])).toList();
}

Future<Map<String, dynamic>> fourchanProcessPosts(Map<String, String> args,
    {int startPostId}) async {
  final data = json.decode(args['data']) as Map<String, dynamic>;

  List<dynamic> decoded = data['posts'] as List;
  data['platform'] = Platform.fourchan;

  if (startPostId != null) {
    decoded = decoded.where((e) => startPostId < e['no']).toList();
    if (decoded.isEmpty) {
      return {"posts": [], "thread": Thread.empty()};
    }
  }

  final thread = Thread(
    decoded[0]['no'].toString(),
    args['board'],
    decoded[0]['sub'] as String ?? '',
    Platform.fourchan,
    decoded[0]['com'] as String ?? '',
    decoded[0]['time'] as int,
    decoded[0]['replies'] as int,
    decoded[0]['images'] as int,
    "",
    decoded[0]['unique_ips'] as int,
    [],
  );
  thread.isClosed = decoded[0]['closed'] == 1;

  int counter = 1;
  final posts = List<Post>.from(decoded.map<Post>((postJson) {
    postJson['board'] = args['board'];
    postJson['domain'] = args['domain'];
    postJson['threadId'] = thread.outerId;
    postJson['number'] = counter;
    final post = fourchanBuildPost(postJson);
    counter += 1;
    return post;
  }));

  // thread.mediaFiles = posts.first.mediaFiles;

  return {"posts": posts, "thread": thread};
}

Future<List<Thread>> fourchanProcessThreads(Map<String, String> args) async {
  final data = json.decode(args['data']) as List;
  final List<Thread> result = [];

  for (final page in data) {
    for (final json in page["threads"]) {
      json['board'] = args['board'];
      json['domain'] = args['domain'];
      json['postId'] = json['no'].toString();
      final files = fourchanFilesToMedia(json);

      final threadMap = {
        "num": json['no'],
        "sticky": json['sticky'] ?? 0,
        "closed": json['closed'] ?? 0,
        "board": json['board'],
        "subject": json['sub'] ?? '',
        "comment": json['com'] ?? '',
        "posts_count": json['replies'] ?? 0,
        "files_count": json['images'] ?? 0,
        "timestamp": json['time'],
        'files': files,
        'platform': Platform.fourchan,
      };

      final thread = Thread.fromMap(threadMap);

      result.add(thread);
    }
  }

  return result;
}

Post fourchanBuildPost(Map<String, dynamic> json) {
  json['postId'] = json['no'].toString();

  final title = json['sub'] ?? '';
  final body = json['com'] ?? '';
  const regex =
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})(<|$)';
  String parsedBody =
      body.replaceAll('<wbr>', '').replaceAllMapped(RegExp(regex, multiLine: true), (match) {
    final url = match.group(1).replaceAll('<br>', '');
    return '<a href="$url">$url</a>${match.group(2)}';
  });

  parsedBody = parsedBody.replaceAll(";${json['threadId']}<", ';${json['threadId']} (OP)<');

  final postJson = {
    'postId': json['postId'],
    'threadId': json['threadId'],
    'subject': title,
    'board': json['board'],
    'comment': parsedBody,
    'name': json['name'] ?? '',
    'parent': '',
    'trip': json['trip'] ?? '',
    'timestamp': json['time'],
    'op': 0,
    'banned': 0,
    'email': '',
    'number': json['number'],
    'isSage': json['name'] == 'sage',
    'files': fourchanFilesToMedia(json),
    'repliesParent': fourchanParseReplies(json['com'], threadId: json['threadId']),
    'platform': Platform.fourchan,
  };

  return Post.fromMap(postJson);
}

List<String> fourchanParseReplies(String body, {String threadId}) {
  if (body == null || body.isEmpty) {
    return [];
  }
  final Iterable<RegExpMatch> matches = RegExp(r">&gt;&gt;(\d+)<").allMatches(body);
  final List<String> result = [];

  for (final match in matches) {
    final id = match.group(1);
    if (!result.contains(id)) {
      result.add(id);
    }
  }
  return result;
}
