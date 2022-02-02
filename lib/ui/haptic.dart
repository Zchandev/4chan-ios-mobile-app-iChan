import 'package:flutter/services.dart';

class Haptic {
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
}
