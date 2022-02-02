import 'package:flutter/cupertino.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

import '../new_post_page.dart';

class FormTextArea extends StatelessWidget {
  const FormTextArea({
    Key key,
    @required this.controller,
    this.form,
  }) : super(key: key);

  final TextEditingController controller;
  final FormUI form;

  @override
  Widget build(BuildContext context) {
    final lines = getLines();
    return CupertinoTextField(
      keyboardAppearance: my.theme.brightness,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      autofocus: true,
      style: TextStyle(color: my.theme.editFieldContrastingColor),
      decoration: BoxDecoration(
          color: my.theme.formBackgroundColor, borderRadius: BorderRadius.circular(6)),
      controller: controller,
      minLines: lines,
      maxLines: lines,
    );
  }

  int getLines() {
    int lines;
    final passcodeEnabled = form.passcodeEnabled;

    if (my.contextTools.isPhone == false) {
      lines = passcodeEnabled ? 15 : 10;
      return lines;
    }

    if (my.contextTools.isVerySmallHeight) {
      lines = passcodeEnabled ? 4 : 3;
    } else if (my.contextTools.isSmallHeight) {
      lines = passcodeEnabled ? 6 : 4;
    } else if (my.contextTools.isLargeHeight) {
      lines = passcodeEnabled ? 10 : 8;
    } else {
      lines = passcodeEnabled ? 8 : 5;
    }

    if (!form.showImages) {
      if (my.contextTools.isVerySmallHeight) {
        lines += 2;
      } else {
        lines += 3;
      }
    }

    if (form.isExpanded) {
      lines += 4;
    }
    return lines;
  }
}
