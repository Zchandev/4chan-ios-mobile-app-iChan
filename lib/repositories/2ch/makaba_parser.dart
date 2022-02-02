import 'dart:convert';
import 'package:ichan/models/media.dart';
import 'package:ichan/models/platform.dart';
import 'package:ichan/models/post.dart';
import 'package:ichan/models/thread.dart';

// DO NOT ADD MY
// import 'package:ichan/services/my.dart' as my;

Future<Map<String, dynamic>> makabaProcessPosts(Map<String, String> args) async {
  final data = json.decode(args['data']) as Map<String, dynamic>;

  final uniques = data['unique_posters'] as String;
  final decoded = data['threads'][0]['posts'] as List;
  data['platform'] = Platform.dvach;

  final thread = Thread(
    data['current_thread'].toString(),
    data['Board'] as String,
    data['title'] as String,
    data['platform'],
    data["threads"][0]["posts"][0]["comment"] ?? '',
    data["threads"][0]["posts"][0]["timestamp"] as int,
    data['posts_count'] as int,
    data['files_count'] as int,
    "",
    int.parse(uniques),
    [],
  );

  final posts = List<Post>.from(decoded.map<Post>((json) {
    json['domain'] = args['domain'];
    json['board'] = data['Board'];
    json['threadId'] = thread.outerId;
    final post = makabaBuildPost(json);
    post.threadUniques = uniques;
    return post;
  }));

  return {"posts": posts, "thread": thread};
}

Future<List<Thread>> makabaProcessThreads(Map<String, String> args) async {
  final data = json.decode(args['data']) as Map<String, dynamic>;
  final List<Thread> result = [];

  for (final threadJson in data['threads']) {
    threadJson['board'] = data['Board'];
    threadJson['platform'] = Platform.dvach;
    threadJson['files'] = makabaFilesToMedia(threadJson['files'] as List,
        domain: args['domain'], postId: threadJson['num'].toString());
    result.add(Thread.fromMap(threadJson as Map<String, dynamic>));
  }

  return result;
}

Future<List<Thread>> makabaProcessPagedThreads(String response,
    {String boardName, String domain}) async {
  final data = json.decode(response) as Map<String, dynamic>;
  final List<Thread> result = [];

  for (final threads in data['threads']) {
    final threadJson = threads['posts'][0];
    threadJson['board'] = boardName;
    threadJson['comment'] = (threadJson['comment'] as String).replaceAll(r'\r\n', '');
    threadJson['platform'] = Platform.dvach;
    threadJson['files'] = makabaFilesToMedia(threadJson['files'] as List,
        domain: domain, postId: threadJson['num'].toString());
    final thread = Thread.fromMap(threadJson as Map<String, dynamic>);
    result.add(thread);
  }

  return result;
}

List<Media> makabaFilesToMedia(List files, {String domain, String postId}) {
  List<Media> mediaFiles = [];
  if (files.isNotEmpty) {
    final List<Map<String, dynamic>> jsonFiles = files.cast<Map<String, dynamic>>();

    mediaFiles = jsonFiles.map<Media>((json) {
      json['postId'] = postId;
      return Media.fromMap(json, domain);
    }).toList();
  }
  return mediaFiles;
}

Post makabaBuildPost(Map<String, dynamic> json) {
  json['platform'] = Platform.dvach;
  json['postId'] = json['num'].toString();
  json['files'] = makabaFilesToMedia(json['files'], domain: json['domain'], postId: json['postId']);
  json['repliesParent'] = parseMakabaReplies(json['comment']);

  return Post.fromMap(json);
}

List<String> parseMakabaReplies(String body) {
  if (body == null) {
    return [];
  }
  final Iterable<RegExpMatch> matches = RegExp(r">>>(\d+)").allMatches(body);
  final List<String> result = [];

  for (final match in matches) {
    if (!result.contains(match.group(1))) {
      result.add(match.group(1));
    }
  }
  return result;
}
