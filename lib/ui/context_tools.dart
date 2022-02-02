import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ichan/services/exports.dart';

class ContextTools {
  static const platform = MethodChannel('zchandev/homebutton');

  BuildContext _context;
  Size _size;

  // iPhone 5S, SE
  bool isVerySmallHeight;

  // iPhone 6-7, SE 2020
  bool isSmallWidth;
  bool isSmallHeight;

  // iPhone XS MAX, 11 PRO MAX, 7 Plus, 8 Plus
  bool isLargeHeight;

  bool isPhone;
  bool hasHomeButton;

  double screenRatio;
  double threadBarHeight;
  double threadBarWidth;

  EdgeInsets navButtonPadding;

  void init(BuildContext context) async {
    _context = context;
    _size = MediaQuery.of(_context).size;

    isVerySmallHeight = _checkVerySmallHeight();
    isSmallWidth = _checkSmallWidth();
    isSmallHeight = _checkSmallHeight();
    isLargeHeight = _checkLargeHeight();
    screenRatio = _getScreenRatio();

    isPhone = screenRatio >= 1.5;

    if (isIos) {
      hasHomeButton = await platform.invokeMethod('hasHomeButton');
      threadBarHeight = hasHomeButton ? 50.0 : 80.0;
    } else {
      hasHomeButton = screenRatio <= 1.8;
      threadBarHeight = 50.0;
    }
    threadBarWidth = isPhone ? double.infinity : 50.0;

    navButtonPadding = hasHomeButton ? EdgeInsets.zero : const EdgeInsets.only(top: 10.0);
  }

  bool _checkVerySmallHeight() => _size.longestSide <= 580;

  bool _checkSmallWidth() => _size.shortestSide <= 380;
  bool _checkSmallHeight() => _size.longestSide <= 680;

  bool _checkLargeHeight() => _size.longestSide >= 850;

  double _getScreenRatio() => _size.longestSide / _size.shortestSide;
}
