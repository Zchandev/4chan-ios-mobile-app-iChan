import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ichan/pages/thread/thread.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/ui/haptic.dart';
import 'package:ichan/services/my.dart' as my;

class MenuTextField extends StatefulWidget {
  const MenuTextField({
    this.key,
    this.label,
    this.boxField,
    this.value = '',
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.afterSubmit,
    this.enabled = true,
    this.isFirst = false,
    this.isLast = false,
    this.fontSize = 17.0,
    this.keyboardType = TextInputType.text,
  });

  final Key key;
  final String label;
  final String boxField;
  final String value;
  final bool enabled;
  final bool isFirst;
  final bool isLast;
  final Function onChanged;
  final Function onSubmitted;
  final Function afterSubmit;
  final TextInputType keyboardType;
  final double fontSize;
  final Function onTap;

  @override
  MenuTextFieldState createState() => MenuTextFieldState();
}

class MenuTextFieldState extends State<MenuTextField> {
  bool isEdit = false;
  final controller = TextEditingController();
  bool readonly;
  dynamic initialValue;

  @override
  void initState() {
    readonly = widget.boxField == null;
    super.initState();
  }

  Border makeBorder() {
    if (widget.isFirst) {
      return Border(top: BorderSide(color: my.theme.navBorderColor));
    } else if (widget.isLast) {
      return Border(
        top: BorderSide(color: my.theme.navBorderColor),
        bottom: BorderSide(color: my.theme.navBorderColor),
      );
    } else {
      return Border(top: BorderSide(color: my.theme.navBorderColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    initialValue = _getVal();
    controller?.text = initialValue.toString();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap();
          return;
        }
        if (!widget.enabled || readonly) {
          return;
        }
        setState(() {
          Haptic.mediumImpact();
          isEdit = true;
        });
      },
      child: Container(
        height: Consts.menuItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: Consts.sidePadding * 1.5),
        decoration: BoxDecoration(
          color: my.theme.backgroundMenuColor,
          border: makeBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isEdit) ...[
              Expanded(
                child: _MenuEditField(
                  label: widget.label,
                  field: widget.boxField,
                  defaultValue: initialValue.toString(),
                  controller: controller,
                  onCanceled: () {
                    controller.text = initialValue.toString();
                    my.prefs.put(widget.boxField, initialValue);
                    setState(() {
                      isEdit = false;
                    });
                  },
                  onChanged: (val) {
                    if (widget.onChanged != null) {
                      widget.onChanged(val);
                    }
                  },
                  onSubmitted: (val) {
                    if (widget.onSubmitted == null) {
                      // save new value to prefs
                      my.prefs.put(widget.boxField, val);
                    } else {
                      // in case of override
                      widget.onSubmitted(val);
                    }

                    // exit
                    setState(() {
                      isEdit = false;
                    });

                    // callback
                    if (widget.afterSubmit != null) {
                      widget.afterSubmit();
                    }
                  },
                ),
              )
            ],
            if (!isEdit) ...[
              Text(widget.label, style: TextStyle(color: getTextColor())),
              const SizedBox(
                width: 20.0,
              ),
              Flexible(
                child: Text(
                  initialValue.toString(),
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: my.theme.postInfoFontColor,
                    fontSize: widget.fontSize,
                  ),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Color getTextColor() {
    if (widget.enabled) {
      return my.theme.foregroundMenuColor;
    } else {
      return my.theme.foregroundMenuColor.withOpacity(0.5);
    }
  }

  dynamic _getVal() {
    if (widget.value != null && widget.value.isNotEmpty) {
      return widget.value;
    } else if (widget.boxField != null) {
      return my.prefs.get(widget.boxField, defaultValue: widget.value);
    }

    return '';
  }
}

class _MenuEditField extends StatelessWidget {
  const _MenuEditField({
    this.key,
    this.label,
    this.field,
    this.controller,
    this.readOnly = false,
    this.defaultValue,
    this.onSubmitted,
    this.onCanceled,
    this.onChanged,
    this.keyboardType,
    this.enabled = true,
  });

  final Key key;
  final String label;
  final String field;
  final String defaultValue;
  final TextEditingController controller;
  final bool readOnly;
  final bool enabled;
  final Function onSubmitted;
  final Function onCanceled;
  final Function onChanged;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      key: key,
      controller: controller,
      autofocus: true,
      decoration: BoxDecoration(
        color: my.theme.backgroundMenuColor,
      ),
      // clearButtonMode: OverlayVisibilityMode.editing,

      suffix: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // my.prefs.put(field, initialVal);
          // print("initialVal = ${initialVal}");
          // onSubmitted(initialVal);
          onCanceled();
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0),
          child: Text("Cancel", style: TextStyle(fontSize: 15.0)),
        ),
      ),
      keyboardAppearance: my.theme.brightness,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: controller != null,
      placeholder: label,
      style: TextStyle(
        color: my.theme.editFieldContrastingColor.withOpacity(0.8),
      ),
      onSubmitted: (val) {
        if (onSubmitted != null) {
          onSubmitted(val);
        }
      },
      onChanged: (val) {
        if (onChanged != null) {
          onChanged(val);
        }
      },
    );
  }
}
