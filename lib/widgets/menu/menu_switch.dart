import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ichan/pages/thread/thread.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/ui/interactive.dart';

class MenuSwitch extends StatelessWidget {
  const MenuSwitch({
    @required this.label,
    @required this.field,
    this.defaultValue,
    this.hint,
    this.onChanged,
    this.isFirst = false,
    this.isLast = false,
    this.enabled = true,
  });

  final String label;
  final String field;
  final String hint;
  final bool defaultValue;
  final Function(bool) onChanged;
  final bool isFirst;
  final bool isLast;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (hint != null) {
          Interactive(context).message(content: hint);
        }
      },
      child: Container(
        height: Consts.menuItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: Consts.sidePadding * 1.5),
        decoration: BoxDecoration(color: my.theme.backgroundMenuColor, border: makeBorder()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: textColor())),
            ValueListenableBuilder(
              valueListenable: my.prefs.box.listenable(keys: [field]),
              builder: (context, box, widget) {
                return CupertinoSwitch(
                    value: box.get(field, defaultValue: defaultValue) as bool,
                    onChanged: (val) {
                      if (!enabled) {
                        return;
                      }
                      if (onChanged == null) {
                        box.put(field, val);
                      } else {
                        onChanged(val);
                      }
                    });
              },
            ),
          ],
        ),
      ),
    );
  }

  Color textColor() {
    if (enabled) {
      return my.theme.foregroundBrightColor;
    } else {
      return my.theme.foregroundBrightColor.withOpacity(0.5);
    }
  }

  Border makeBorder() {
    if (isFirst) {
      return Border(top: BorderSide(color: my.theme.navBorderColor));
    } else if (isLast) {
      return Border.symmetric(vertical: BorderSide(color: my.theme.navBorderColor));
    } else {
      return Border(top: BorderSide(color: my.theme.navBorderColor));
    }
  }
}
