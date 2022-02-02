import 'package:flutter/cupertino.dart';
import 'package:ichan/services/my.dart' as my;

class TagButton extends StatelessWidget {
  const TagButton({
    Key key,
    @required this.controller,
    this.text,
    this.child,
    this.tagName,
  }) : super(key: key);

  final TextEditingController controller;
  final String text;
  final Widget child;
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

        final startTag = "[$tagName]";
        final endTag = "[/$tagName]";
        final textWithCode = startTag + txt + endTag;
        final result = textBefore + textWithCode + textAfter;
        controller.text = result;
        newOffset = sel.baseOffset + textWithCode.length - 3 - tagName.length;

        controller.selection = sel.copyWith(baseOffset: newOffset, extentOffset: newOffset);
        // my.postBloc.updateText(controller.text);
      },
      child: Container(
        // width: (context.screenWidth - 20) / 8,
        child: child ?? Text(text, style: TextStyle(fontSize: 22, color: my.theme.primaryColor)),
      ),
    );
  }
}
