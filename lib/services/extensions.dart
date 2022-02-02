import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';

String numToPluralKey(num val) {
  final p10 = val % 10;
  final p100 = val % 100;

  if (p10 == 1 && p100 != 11) {
    return 'one';
  } else if ([2, 3, 4].contains(p10) && ![12, 13, 14].contains(p100)) {
    return 'few';
  } else if (p10 == 0 || [5, 6, 7, 8, 9].contains(p10) || [11, 12, 13, 14].contains(p100)) {
    return 'many';
  }
  return 'other';
}

extension StringExtension on String {
  String get presence {
    if (this == null || isEmpty) {
      return null;
    } else {
      return this;
    }
  }

  String takeFirst(int number, {String dots}) {
    if (length <= number) {
      return this;
    } else {
      String result = substring(0, number);
      if (dots != null) {
        result = "${result.trim()}$dots";
      }
      return result;
    }
  }

  String plur(num val) {
    final key = numToPluralKey(val);
    return '$this.$key'.tr(args: [val.toString()]);
  }

  bool get blank => this == null || isEmpty;
  bool get present => !blank;
}

extension ListPresence<T> on List<T> {
  List<T> get presence {
    if (this == null || isEmpty) {
      return null;
    } else {
      return this;
    }
  }

  bool get blank => this == null || isEmpty;
  bool get present => !blank;
}

extension Screen on BuildContext {
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;
}

extension DateExtension on int {
  int get timeDiff => DateTime.now().millisecondsSinceEpoch - this;
  int get timeDiffInSeconds => timeDiff ~/ 1000;
  double get timeDiffInMinutes => timeDiffInSeconds / 60;
  double get timeDiffInHours => timeDiffInMinutes / 60;

  String formatDate({bool year = true, bool compact = false}) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(this);
    String str;

    if (compact) {
      if (timeDiffInSeconds <= 24 * 3600) {
        str = 'HH:mm';
      } else {
        str = 'dd.MM.yy';
      }
    } else {
      str = year ? 'dd.MM.yy HH:mm' : 'dd.MM HH:mm';
    }
    return DateFormat(str).format(date).toString();
  }

  String toHumanDate({bool year = true, bool compact = false}) {
    final elapsed = timeDiff;

    final suffix = 'ago'.tr();

    final num seconds = elapsed / 1000;
    final num minutes = seconds / 60;
    final num hours = minutes / 60;

    final keys = compact
        ? {'min': 'date.compact_minute', 'hour': 'date.compact_hour'}
        : {'min': 'date.minute', 'hour': 'date.hour'};

    String result;
    if (seconds < 10) {
      return 'now'.tr();
    } else if (seconds < 45) {
      result = keys['min'].plur(1);
    } else if (seconds < 90) {
      result = keys['min'].plur(1);
    } else if (minutes <= 60) {
      result = keys['min'].plur(minutes.round());
    } else if (hours < 24) {
      final wholeHours = minutes ~/ 60;
      final minutesLeft = (minutes - wholeHours * 60).round();
      if (minutesLeft <= 30) {
        result = keys['hour'].plural(wholeHours);
      } else {
        result = keys['hour'].plural(wholeHours + 1);
      }
    } else {
      return formatDate(year: year, compact: compact);
    }

    return [result, suffix].where((str) => str != null && str.isNotEmpty).join(' ');
  }
}
