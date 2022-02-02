import 'package:ichan/models/thread.dart';
import 'package:ichan/repositories/api_proxy.dart';
import 'package:ichan/services/enums.dart';

class Repo {
  Repo(this.reposMap);

  final Map<Platform, ApiProxy> reposMap;

  ApiProxy on(Platform platform) {
    if (platform == Platform.all) {
      print("PLATFORM == ALL!!!");
      return reposMap[Platform.dvach];
    }
    if (!reposMap.containsKey(platform)) {
      throw Exception("PLATFORM NOT FOUND: $platform");
    }
    return reposMap[platform];
  }

  // todo: add url to thread;
  String getThreadUrl(Thread thread, Platform platform) {
    if (platform == Platform.dvach) {
      return "${on(platform).api.webDomain}/${thread.boardName}/res/${thread.outerId}.html";
    } else if (platform == Platform.fourchan) {
      return "${on(platform).api.webDomain}/${thread.boardName}/thread/${thread.outerId}";
    }
    throw Exception("Unknown platform");
  }
}
