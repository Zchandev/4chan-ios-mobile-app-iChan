import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MediaCacheManager extends BaseCacheManager {
  static const key = "myCache";

  static MediaCacheManager _instance;

  factory MediaCacheManager() {
    _instance ??= MediaCacheManager._();
    return _instance;
  }

  MediaCacheManager._() : super(key, maxAgeCacheObject: null);

  Future<String> getFilePath() async {
    final directory = await getTemporaryDirectory();
    return p.join(directory.path, key);
  }
}
