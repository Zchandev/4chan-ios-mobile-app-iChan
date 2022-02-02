import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:ichan/models/platform.dart';
import 'package:ichan/services/box_proxy.dart';

import 'exports.dart';

class PrefsBox extends BoxProxy {
  PrefsBox({this.box});

  final isSafe = const String.fromEnvironment('SAFE') == "1";
  final updaterOn = const String.fromEnvironment('UPDATER') != "0";

  final Box box;

  final defaultStats = {
    "threads_visited": 0,
    "threads_clicked": 0,
    "threads_created": 0,
    "posts_created": 0,
    "visits": 0,
    "favs_refreshed": 0,
    "replies_received": 0,
    "media_views": 0,
  };

  bool get isTester => getBool('tester');

  ScrollPhysics get scrollPhysics => const BouncingScrollPhysics();

  double get postFontSize => getDouble('font_size', defaultValue: 15.0);

  bool get showCaptcha {
    return getBool('passcode_enabled') == false;
  }

  bool get passcodeOn => getBool('passcode_enabled');
  bool get passcodeOff => !passcodeOn;

  List<Platform> get platforms => (get('platforms') ?? []).cast<Platform>();

  FontWeight get fontWeight {
    final val = box.get('light_font', defaultValue: false) as bool;
    return val ? FontWeight.w300 : FontWeight.normal;
  }

  void incrStats(String field, {int to = 1}) {
    final Map<String, int> stats = Map.from(get("stats", defaultValue: defaultStats));
    stats[field] ??= 0;
    stats[field] += to;
    put("stats", stats);
  }

  void setStats(String field, int val) {
    final Map<String, int> stats = Map.from(get("stats", defaultValue: defaultStats));
    stats[field] = val;
    put("stats", stats);
  }

  Map<String, int> get stats => Map<String, int>.from(get('stats', defaultValue: defaultStats));

  String getJsonCache(String key) {
    final cache = get('json_cache', defaultValue: {}).cast<String, String>();
    return cache[key] ?? '';
  }

  void putJsonCache(String key, String value) {
    final cache = get('json_cache', defaultValue: {}).cast<String, String>();
    cache[key] = value;
    put('json_cache', cache);
  }
}
