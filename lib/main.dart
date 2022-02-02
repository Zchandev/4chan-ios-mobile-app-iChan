import 'dart:async';

import 'package:firebase_analytics/observer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/migration.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:easy_localization/easy_localization.dart';

import 'blocs/blocs.dart';
import 'pages/home_page.dart';
import 'pages/welcome_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ThreadStorageAdapter());
  Hive.registerAdapter(PlatformAdapter());
  Hive.registerAdapter(BoardAdapter());
  Hive.registerAdapter(MediaAdapter());
  Hive.registerAdapter(PostAdapter());

  await Hive.openBox('prefs');
  await Hive.openBox<ThreadStorage>('favs');
  await Hive.openBox<Post>('posts');
}

void updateHiveDefaults() {
  if (my.prefs.getBool("clean_cache")) {
    DefaultCacheManager().emptyCache();
  }

  void setDefault(String field, dynamic value) {
    final val = my.prefs.get(field);
    if (val == null) {
      my.prefs.put(field, value);
    }
  }

  setDefault('domain', '2ch.hk');
  setDefault('enable_media', true);
  setDefault('medium_image_size', 2.0);
  setDefault('big_image_size', 5.0);
  setDefault('medium_video_size', 5.0);
  setDefault('big_video_size', 20.0);
  if (isIos) {
    setDefault('menu_margin', 38.0);
  } else {
    setDefault('menu_margin', 0.0);
  }
  setDefault('font_size', 15.0);

  setDefault('clean_exif', true);
  setDefault('convert_png_to_jpg', true);
  setDefault('compress_images', true);
  setDefault('compress_quality', 'very_high');
  setDefault('compress_image_resolution', 2048);

  setDefault('migration', Migration.current);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1
  await initHive();
  // 2
  await my.setupSingletons();
  // 3
  await Consts.init();

  updateHiveDefaults();
  await Migration.migrate();
  if (!isDebug) {
    System.cleanCache();
  }

  if (isProd && !my.prefs.getBool('paranoia_mode')) {
    FlutterError.onError = Crashlytics.instance.recordFlutterError;
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThreadBloc>(create: (BuildContext context) => my.threadBloc),
        BlocProvider<BoardBloc>(create: (BuildContext context) => my.boardBloc),
        BlocProvider<CategoryBloc>(create: (BuildContext context) => my.categoryBloc),
        BlocProvider<PostBloc>(create: (BuildContext context) => my.postBloc),
        BlocProvider<FavoriteBloc>(create: (BuildContext context) => my.favoriteBloc),
        BlocProvider<PlayerBloc>(create: (BuildContext context) => my.playerBloc),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ru')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        preloaderColor: Colors.black,
        child: const App(),
      ),
    ),
  );
}

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
      my.postBloc.add(AddFiles(sharedFiles: value));
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isProd && !my.prefs.getBool('paranoia_mode')) {
      my.analytics.setAnalyticsCollectionEnabled(isProd);
      _logAppOpen();
    }

    return ValueListenableBuilder(
      valueListenable:
          my.prefs.box.listenable(keys: ['theme', 'theme_primary_color', 'theme_background_color']),
      builder: (context, val, widget) {
        if (!isIos) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: my.theme.navbarBackgroundColor.withOpacity(Consts.navbarOpacity)));
        }

        rebuildAllChildren(context);

        return RefreshConfiguration(
          footerTriggerDistance: 15,
          dragSpeedRatio: 0.91,
          headerBuilder: () => const ClassicHeader(),
          footerBuilder: () => const ClassicFooter(),
          enableLoadingWhenNoData: false,
          shouldFooterFollowWhenNotFull: (state) => false,
          autoLoad: true,
          child: CupertinoApp(
            navigatorKey: navigatorKey,
            showPerformanceOverlay: my.prefs.getBool("profiler"),
            navigatorObservers: getObservers(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                primaryColor: my.theme.primaryColor,
                navActionTextStyle: TextStyle(
                  inherit: false,
                  // fontFamily: '.SF Pro Text',
                  fontSize: 17.0,
                  letterSpacing: -0.41,
                  color: my.theme.navbarFontColor,
                  decoration: TextDecoration.none,
                ),
                navLargeTitleTextStyle: TextStyle(
                  inherit: false,
                  // fontFamily: '.SF Pro Display',
                  fontSize: 34.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.41,
                  color: my.theme.navbarFontColor,
                ),
                navTitleTextStyle: TextStyle(
                  inherit: false,
                  fontSize: 17.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.41,
                  color: my.theme.navbarFontColor,
                ),
                textStyle: TextStyle(
                  letterSpacing: -0.41,
                  fontSize: 17.0,
                  color: my.theme.fontColor,
                  fontWeight: my.prefs.fontWeight,
                ),
              ),
              brightness: my.theme.brightness,
              scaffoldBackgroundColor: my.theme.secondaryBackgroundColor,
              barBackgroundColor: my.theme.navbarBackgroundColor,
              // bar
              primaryColor: my.theme.primaryColor,
              primaryContrastingColor: my.theme.primaryContrastingColor,
            ),
            routes: {
              "/": (context) => my.prefs.platforms.isNotEmpty ? const HomePage() : WelcomePage(),
            },
          ),
        );
      },
    );
  }

  Future<void> _logAppOpen() async {
    return await my.analytics.logAppOpen();
  }

  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  List<NavigatorObserver> getObservers() {
    if (!isProd || !my.prefs.getBool('paranoia_mode')) {
      return [];
    } else {
      final observer = FirebaseAnalyticsObserver(analytics: my.analytics);
      return [observer];
    }
  }
}
