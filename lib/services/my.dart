// import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:ichan/blocs/blocs.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/repositories/4chan/fourchan_api.dart';
import 'package:ichan/repositories/2ch/makaba_api.dart';
import 'package:ichan/repositories/proxy.dart';
import 'package:ichan/repositories/repo.dart';
import 'package:ichan/services/box_proxy.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/media_cache_manager.dart';
import 'package:ichan/services/posts_box.dart';
import 'package:ichan/ui/context_tools.dart';
import 'package:ichan/services/prefs.dart';
import 'package:ichan/services/secstore.dart';
import 'package:ichan/ui/theme_manager.dart';
import 'package:ichan/ui/themes.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

String getDomain(String domain) {
  final String result = domain
      .replaceAll('www.', '')
      .replaceAll('http://', '')
      .replaceAll('https://', '')
      .replaceAll('/', '');
  return 'https://$result';
}

Future setupSingletons() async {
  final prefs = PrefsBox(box: Hive.box('prefs'));
  final domain = prefs.getString('domain', defaultValue: Consts.domain2ch);
  final fourchanDomain =
      prefs.getString('fourchan_domain', defaultValue: FourchanApi.defaultDomain);
  final makabaApi = MakabaApi(domain: getDomain(domain));
  final fourchanApi = FourchanApi(domain: getDomain(fourchanDomain));

  final makabaProxy = MakabaProxy(api: makabaApi);
  final fourchanProxy = FourchanProxy(api: fourchanApi);

  final secstore = Secstore(const FlutterSecureStorage());

  final Map<Platform, ApiProxy> reposMap = {
    Platform.dvach: makabaProxy,
    Platform.fourchan: fourchanProxy,
  };

  final repo = Repo(reposMap);

  // exts
  getIt.registerSingleton(FirebaseAnalytics());

  // apis
  getIt.registerSingleton(repo);

  getIt.registerSingleton(ContextTools());
  getIt.registerSingleton<MakabaApi>(makabaApi);
  getIt.registerSingleton<FourchanApi>(fourchanApi);

  // blocs
  getIt.registerSingleton(FavoriteBloc(repo: repo));
  getIt.registerSingleton(ThreadBloc(repo: repo));
  getIt.registerSingleton(PostBloc(repo: repo));
  getIt.registerSingleton(CategoryBloc(repo: repo));
  getIt.registerSingleton(BoardBloc(repo: repo));
  getIt.registerSingleton(PlayerBloc());

  getIt.registerSingleton(FavsBox(box: Hive.box<ThreadStorage>('favs')));
  getIt.registerSingleton(PostsBox(box: Hive.box<Post>('posts')));
  getIt.registerSingleton<PrefsBox>(prefs);
  getIt.registerSingleton<Secstore>(secstore);
  getIt.registerSingleton<MediaCacheManager>(MediaCacheManager());

  final themeManager = ThemeManager(prefs: prefs);
  themeManager.updateTheme();
  themeManager.syncTheme();

  getIt.registerSingleton<ThemeManager>(themeManager);

  getIt.registerSingleton<IconTheme>(DefaultIconTheme());
}

final analytics = getIt<FirebaseAnalytics>();
final repo = getIt<Repo>();

final contextTools = getIt<ContextTools>();

final favoriteBloc = getIt<FavoriteBloc>();
final postBloc = getIt<PostBloc>();
final threadBloc = getIt<ThreadBloc>();
final categoryBloc = getIt<CategoryBloc>();
final boardBloc = getIt<BoardBloc>();
final playerBloc = getIt<PlayerBloc>();

final secstore = getIt<Secstore>();
final favs = getIt<FavsBox>();
final prefs = getIt<PrefsBox>();
final posts = getIt<PostsBox>();
final makabaApi = getIt<MakabaApi>();
final fourchanApi = getIt<FourchanApi>();

final IconTheme icons = getIt<IconTheme>();

final cacheManager = DefaultCacheManager();
final mediaCache = getIt<MediaCacheManager>();

final themeManager = getIt<ThemeManager>();

MyTheme get theme => themeManager.theme;
