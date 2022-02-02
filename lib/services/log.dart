import 'dart:developer';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

class Log {
  static List<String> all = [];
  static bool _enabled;
  static const minLevel = 1;

  static void clean() {
    all = [];
  }

  static void debug(String text) {
    _add(text, 0);
  }

  static void info(String text) {
    _add(text, 1);
  }

  static void warn(String text) {
    _add(text, 2);
  }

  static void error(String text, {Object error}) {
    _add(text, 3, error: error);
  }

  static void _add(String text, int level, {Object error}) {
    _enabled ??= isDebug || my.prefs.getBool('tester');
    if (!_enabled || level < minLevel) {
      return;
    }

    log(text, level: level);
    all.add(text);
  }

  static int get length => all.length;
}
