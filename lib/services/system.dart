import 'package:cookie_jar/cookie_jar.dart';
import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:ichan/repositories/2ch/makaba_api.dart';
import 'package:ichan/services/exports.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ichan/services/my.dart' as my;

class System {
  static void cleanCache() {
    FilePicker.clearTemporaryFiles();
    my.cacheManager.emptyCache();
    clearDiskCachedImages();
  }

  static Future<bool> launchUrl(String url) async {
    if (await canLaunch(url)) {
      return await launch(url);
    } else {
      return Future.value(false);
    }
  }

  static Map<String, String> headersForPath(String path) {
    final cookieJar = PersistCookieJar(dir: Consts.appDocDir.path);

    final uri = Uri.https("2ch.hk", '/');
    final cookies = cookieJar.loadForRequest(uri);
    final usercodeCookie = cookies.firstWhere((e) => e.name == 'usercode_auth', orElse: () => null);

    if (usercodeCookie != null) {
      return {'cookie': '${usercodeCookie.name}=${usercodeCookie.value}'};
    } else {
      return {'cookie': MakabaApi.nsfwCookie};
    }
  }

  static Future<void> setAutoturn(String mode) async {
    switch (mode) {
      case "portrait":
        return await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      case "landscape":
        return await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      case "auto":
        return await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
    }
  }
}
