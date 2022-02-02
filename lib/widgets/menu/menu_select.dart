import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ichan/pages/thread/thread.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/services/my.dart' as my;

class MenuSelect extends StatelessWidget {
  const MenuSelect({
    this.labels,
    this.values,
    this.field,
    this.defaultValue,
    this.onChanged,
    this.enabled = true,
  });

  final List<String> labels;
  final List<String> values;
  final String field;
  final String defaultValue;
  final Function(String) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Consts.menuItemHeight,
      child: ValueListenableBuilder(
        valueListenable: my.prefs.box.listenable(keys: [field]),
        builder: (context, box, widget) {
          final currentVal = my.prefs.getString(field, defaultValue: defaultValue);
          return ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: values.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  if (!enabled) {
                    return;
                  }

                  if (onChanged != null) {
                    final result = onChanged(values[index]);
                    if (result != false) {
                      box.put(field, values[index]);
                    }
                  } else {
                    box.put(field, values[index]);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.5),
                  color: my.theme.backgroundMenuColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: enabled
                              ? my.theme.foregroundMenuColor
                              : my.theme.foregroundMenuColor.withOpacity(0.5),
                        ),
                      ),
                      Opacity(
                          opacity: values[index] == currentVal ? 1.0 : 0.0,
                          child: const FaIcon(FontAwesomeIcons.check, size: 18))
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
          );
        },
      ),
    );
  }
}
