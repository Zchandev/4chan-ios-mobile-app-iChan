import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:device_info/device_info.dart';
import 'package:ichan/services/exports.dart';
import 'package:package_info/package_info.dart';
// import 'package:disk_space/disk_space.dart';

import 'package:path_provider/path_provider.dart';

import 'package:ichan/services/my.dart' as my;

class Consts {
  static final chatUrl = isIos ? 'https://t.me/ichan_public' : 'https://t.me/ichan_android';
  static const discordUrl = 'https://discord.gg/kNcUTJj';
  static const patreonUrl = 'https://www.patreon.com/zchandev';

  static final chatName = isIos ? '@ichan_public' : '@ichan_android';

  static const telegramRuUrl = 'https://t.me/zchanapp';
  static const telegramEnUrl = 'https://t.me/ichan_app';
  static const telegramRu = '@zchanapp';
  static const telegramEn = '@ichan_app';
  static String domain2ch = '2ch.hk';
  static const recaptchaKey = "6LeQYz4UAAAAAL8JCk35wHSv6cuEV5PyLhI6IxsM";

  // posts
  static final bodyTrimSize = isIpad ? 500 : 330;
  static const titleTrimSize = 40;
  static const navLeadingTrimSize = 7;
  static final postImageWidth = isIpad ? 100.0 : 85.0;
  static final postImageHeight = isIpad ? 100.0 : 85.0;
  static const postTitleSize = 18.0;

  static final threadImageWidth = isIpad ? 120.0 : 85.0;
  static final threadImageHeight = isIpad ? 120.0 : 85.0;

  static final youMark = isIos ? "<i>YOU</i>" : "<b>&larr; YOU</b>";

  static double get backGestureVelocity =>
      (my.prefs.getDouble('gestures_sensivity', defaultValue: 100.0) / 100.0) * 400.0;
  static const verticalGestureVelocity = 300;

  // text size
  static const errorLoadingTextSize = 20.0;
  static const postInfoFontSize = 12.0;
  static const menuFontSize = 16.0;

  static const menuItemHeight = 50.0;
  static const topNavbarHeight = 88.0;
  static const navbarOpacity = 0.85;

  // bottom nav bar
  static const bottomBarSize = 25.0;
  static const bottomBarIconSize = 23.0;

  static const sidePadding = 10.0;
  static const topPadding = 10.0;
  static const elementPadding =
      EdgeInsets.only(top: topPadding, left: sidePadding, right: sidePadding);
  static const horizontalPadding =
      EdgeInsets.only(top: topPadding, left: sidePadding, right: sidePadding);

  static const keyboardAppearance = Brightness.dark;

  // other
  static bool isPhysical;
  static String version;
  static String build;
  static String deviceName;
  static Directory appDocDir;

  static Future init() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    build = packageInfo.buildNumber;

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (isIos) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
      isPhysical = iosInfo.isPhysicalDevice;
    } else {
      final AndroidDeviceInfo info = await deviceInfo.androidInfo;

      if (build.startsWith('1') || build.startsWith('2')) {
        build = build.substring(1, 4);
      }

      isPhysical = info.isPhysicalDevice;
    }

    appDocDir = await getApplicationDocumentsDirectory();
  }

  static bool get isIpad => isIos && deviceName.toLowerCase().contains('ipad');
}
