import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

const myOrange = Color(0xffFE9500);
const myLightBlue = Color(0xff95ACC2);

abstract class MyTheme {
  String name;
  Brightness get brightness;
  Brightness get menuBrightness;
  Color primaryColor;
  Color customPrimaryColor;
  Color primaryContrastingColor;
  Color fontColor;
  Color backgroundColor;
  Color customBackgroudColor;
  Color secondaryBackgroundColor;
  Color bottomBarBackground;
  Color navbarBackgroundColor;
  Color postBackgroundColor;
  Color threadBackgroundColor;
  Color navbarFontColor;
  Color postInfoFontColor;
  Color linkColor;
  Color myPostBackgroundColor;
  Color inactiveColor;
  Color alertColor;
  Color foregroundBrightColor;
  Color foregroundMenuColor;
  Color backgroundMenuColor;
  Color alphaBackground;
  Color quoteColor;
  Color dividerColor;
  Color lightDividerColor;
  Color editFieldTextColor;
  Color editFieldContrastingColor;
  Color formBackgroundColor;
  Color spoilerBackgroundColor;
  Color placeholderColor;
  Color buttonTextColor;
  Color progressBarColor;
  Color navBorderColor;
  CupertinoDynamicColor clearButtonColor;

  String captchaBackground;

  bool get isDark;
}

class DarkTheme extends MyTheme {
  final name = "dark";
  final brightness = Brightness.dark;
  final menuBrightness = Brightness.dark;
  final primaryColor = myOrange;
  final linkColor = myOrange;
  final Color fontColor = const Color(0xffC6C6C8);
  final primaryContrastingColor = CupertinoColors.white;
  final backgroundColor = CupertinoColors.darkBackgroundGray;
  final secondaryBackgroundColor = CupertinoColors.black;
  final postInfoFontColor = Colors.white38;
  final myPostBackgroundColor = const Color(0xff242424);
  final inactiveColor = CupertinoColors.inactiveGray;
  final alertColor = CupertinoColors.destructiveRed;
  final foregroundBrightColor = const Color(0xffDCDDE2);
  final foregroundMenuColor = const Color(0xffDCDDE2);
  final backgroundMenuColor = CupertinoColors.darkBackgroundGray;
  final alphaBackground = const Color(0xff1E1E1E);
  final quoteColor = const Color(0xff3AA510);
  final dividerColor = Colors.grey.withOpacity(0.3);
  final lightDividerColor = const Color(0xff333333);
  final editFieldTextColor = CupertinoColors.black;
  final editFieldContrastingColor = CupertinoColors.white;
  final formBackgroundColor = CupertinoColors.white.withOpacity(0.05);
  final spoilerBackgroundColor = CupertinoColors.systemGrey.withAlpha(150);
  final placeholderColor = CupertinoColors.opaqueSeparator;
  final buttonTextColor = CupertinoColors.white;
  final navBorderColor = const Color(0xff333438).withOpacity(0.6);

  final captchaBackground = "#171717";

  final clearButtonColor = const CupertinoDynamicColor.withBrightness(
    color: Color(0xFF636366),
    darkColor: Color(0xFFAEAEB2),
  );

  Color get navbarFontColor => primaryColor;

  Color get postBackgroundColor => backgroundColor;
  Color get threadBackgroundColor => inactiveColor.withOpacity(0.05);

  Color get navbarBackgroundColor => backgroundColor;
  Color get bottomBarBackground => backgroundColor;

  Color get progressBarColor => isDark ? primaryColor : myOrange;

  final Map<String, Color> colorsMap = {
    "black": CupertinoColors.black,
    "dark_gray": CupertinoColors.darkBackgroundGray,
    "green": CupertinoColors.activeGreen,
    "red": CupertinoColors.systemRed,
    "purple": CupertinoColors.systemPurple,
    "blue": CupertinoColors.systemBlue,
    "pink": CupertinoColors.systemPink,
    "white": CupertinoColors.white,
    "gray": CupertinoColors.inactiveGray,
    "light_blue": myLightBlue,
    "orange": myOrange,
    "default": myOrange,
  };

  bool get isDark => brightness == Brightness.dark;
  bool get isLight => !isDark;
}

class DarkGreenTheme extends DarkTheme {
  @override
  final primaryColor = const Color(0xff1EBE46);

  @override
  Color get linkColor => primaryColor;

  @override
  Color get progressBarColor => primaryColor;
}

class DarkBlueTheme extends DarkTheme {
  @override
  final primaryColor = myLightBlue;

  @override
  final backgroundColor = const Color(0xff2D3034);

  @override
  final secondaryBackgroundColor = const Color(0xff1D1F21);

  @override
  final alphaBackground = const Color(0xff222326);

  @override
  final postBackgroundColor = const Color(0xff28292D);

  @override
  final backgroundMenuColor = const Color(0xff282A2E);

  @override
  final captchaBackground = "#2D3034";

  @override
  Color get linkColor => primaryColor;

  @override
  Color get progressBarColor => primaryColor;
}

class OrangeWhiteTheme extends DarkTheme {
  @override
  final name = "futaba";

  @override
  final brightness = Brightness.light;

  @override
  final primaryColor = myOrange;

  @override
  final backgroundColor = CupertinoColors.white;

  @override
  final secondaryBackgroundColor = const Color(0xffF2F2F2);

  @override
  final postBackgroundColor = CupertinoColors.white;

  @override
  final fontColor = CupertinoColors.black;

  @override
  final postInfoFontColor = Colors.black38;

  @override
  final myPostBackgroundColor = const Color(0xffEBEDED);

  @override
  final bottomBarBackground = CupertinoColors.white;

  @override
  final foregroundBrightColor = CupertinoColors.black;

  @override
  final foregroundMenuColor = CupertinoColors.black;

  @override
  final backgroundMenuColor = CupertinoColors.white;

  @override
  final alphaBackground = const Color(0xffEDEEF3);

  @override
  final placeholderColor = CupertinoColors.lightBackgroundGray;

  @override
  final buttonTextColor = CupertinoColors.white;

  @override
  final navbarFontColor = CupertinoColors.white;

  @override
  final formBackgroundColor = CupertinoColors.black.withOpacity(0.05);

  @override
  final navBorderColor = const Color(0xff868686).withOpacity(0.25);

  @override
  final lightDividerColor = Colors.grey.withOpacity(0.3);

  @override
  Color get navbarBackgroundColor => primaryColor;

  @override
  final captchaBackground = "#FFFFFF";

  @override
  Color get editFieldContrastingColor => fontColor;

  @override
  Color get progressBarColor => CupertinoColors.systemGrey;
}

class BlackWhiteTheme extends OrangeWhiteTheme {
  @override
  final name = "black_white";

  @override
  final primaryColor = CupertinoColors.black;

  @override
  final primaryContrastingColor = CupertinoColors.white;

  @override
  Color get navbarBackgroundColor => primaryColor;

  @override
  Color get navbarFontColor => primaryContrastingColor;

  @override
  Color get progressBarColor => myOrange;
}

abstract class IconTheme {
  IconData arrowDown;
  IconData pencil;
  IconData refresh;
  IconData solidFavorite;
  IconData emptyFavorite;
  IconData gallery;
  IconData search;
}

class DefaultIconTheme extends IconTheme {
  final arrowDown = FlutterIcons.arrow_down_faw;
  final pencil = FlutterIcons.pencil_alt_faw5s;
  final refresh = FlutterIcons.sync_alt_faw5s;
  final solidFavorite = FlutterIcons.star_faw5s;
  final emptyFavorite = FlutterIcons.star_faw5;
  final gallery = FlutterIcons.images_faw5;
}
