import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/htmlz.dart';
import 'package:ichan/services/my.dart' as my;

import 'thread.dart';

class PostQuote extends HookWidget {
  const PostQuote({
    Key key,
    @required this.post,
    @required this.thread,
  }) : super(key: key);

  final Thread thread;
  final Post post;

  void selectText(BuildContext context, TextEditingController controller) {
    final sel = controller.selection;
    final text = sel.isValid && sel.baseOffset != sel.extentOffset
        ? sel.textInside(controller.text)
        : controller.text;

    final fav = ThreadStorage.findById(thread.toJsonId);
    my.postBloc.addQuote(postId: post.outerId, text: text, fav: fav);

    final page = NewPostPage(thread: thread);
    final title = thread.trimTitle(Consts.navLeadingTrimSize);

    Routz.of(context).toPage(page, title: title).then((e) {
      if (e == true) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    controller.text = Htmlz.toHuman(post.body.replaceAll(Consts.youMark, ''));
    final lines = my.contextTools.isVerySmallHeight ? 6 : (my.contextTools.isSmallHeight ? 8 : 12);

    return HeaderNavbar(
      backgroundColor: my.theme.backgroundColor,
      middleText: "Quote",
      child: Container(
        height: context.screenHeight,
        width: context.screenWidth,
        padding: const EdgeInsets.only(
          top: Consts.topPadding,
          left: Consts.sidePadding,
          right: Consts.sidePadding,
        ),
        child: Wrap(
          runSpacing: 20,
          children: [
            CupertinoTextField(
              style: TextStyle(color: my.theme.editFieldContrastingColor),
              keyboardAppearance: my.theme.brightness,
              decoration: BoxDecoration(
                color: my.theme.formBackgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              autofocus: true,
              enableSuggestions: false,
              controller: controller,
              minLines: lines,
              maxLines: lines,
            ),
            Center(
              child: CupertinoButton(
                color: my.theme.primaryColor,
                onPressed: () {
                  selectText(context, controller);
                },
                child: const Text("Quote"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
