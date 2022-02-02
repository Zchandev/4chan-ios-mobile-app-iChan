import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

class QuoteButton extends StatelessWidget {
  const QuoteButton({
    Key key,
    @required this.controller,
    this.text,
    this.tagName,
  }) : super(key: key);

  final TextEditingController controller;
  final String text;
  final String tagName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final sel = controller.selection;
        final txt = sel.textInside(controller.text);
        final textBefore = sel.textBefore(controller.text);
        final textAfter = sel.textAfter(controller.text);

        int newOffset;

        final result =
            txt.replaceAllMapped(RegExp(r'^(.+)$', multiLine: true), _parse).presence ?? ">";

        controller.text = textBefore + result + textAfter;
        newOffset = min(controller.text.length, sel.extentOffset + (result.length - txt.length));
        controller.selection = sel.copyWith(baseOffset: newOffset, extentOffset: newOffset);
      },
      child: Text(text, style: TextStyle(fontSize: 22, color: my.theme.primaryColor)),
    );
  }

  String _parse(Match match) {
    if (match.group(1).startsWith('>') == true) {
      return match.group(1);
    } else {
      return '>${match.group(1)}';
    }
  }
}
