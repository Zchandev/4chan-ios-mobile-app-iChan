import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ichan/blocs/thread/barrel.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/blur_filter.dart';

import 'thread.dart';

class PostReplies extends HookWidget {
  const PostReplies({
    Key key,
    this.replies,
    this.threadData,
    this.highlightPostId = '',
    this.origin = Origin.thread,
  }) : super(key: key);
  final List<Post> replies;
  final ThreadData threadData;
  final String highlightPostId;
  final Origin origin;

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    controller.addListener(() {
      if (controller.offset <= -70) {
        Routz.of(context).backToThread();
      }
    });

    _showHelp(context);

    final isCentered = !my.prefs.getBool('replies_on_top');
    final blurEnabled = isCentered && origin == Origin.thread;
    final containerColor = isCentered
        ? my.theme.backgroundColor.withOpacity(blurEnabled ? 0.6 : 1)
        : my.theme.backgroundColor;

    final divider = Divider(color: my.theme.dividerColor, height: 1, thickness: 1);

    // final topPadding = isCentered ? (replies.length <= 10 ? 25.0 : 0.0) : 0.0;
    final padding = replies.length <= 3 ? 15.0 : 0.0;

    final child = SafeArea(
      bottom: false,
      top: true,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity >= Consts.verticalGestureVelocity) {
            Routz.of(context).backToThread();
          }
        },
        child: Stack(
          alignment: isCentered ? Alignment.center : Alignment.topCenter,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                Navigator.pop(context);
              },
              child: BlurFilter(
                withOpacity: false,
                sigma: 7.5,
                enabled: blurEnabled,
                child: Container(color: containerColor),
              ),
            ),
            Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.startToEnd,
              movementDuration: const Duration(milliseconds: 300),
              resizeDuration: null,
              onDismissed: (direction) {
                Navigator.pop(context);
              },
              child: ListView.builder(
                shrinkWrap: replies.length <= 10,
                physics: my.prefs.scrollPhysics,
                itemCount: replies.length,
                controller: controller,
                padding: EdgeInsets.symmetric(vertical: padding),
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      if (isCentered) divider,
                      PostItem(
                        origin: Origin.reply,
                        post: replies[index],
                        threadData: threadData,
                        highlightPostId: highlightPostId,
                      ),
                      if (index == replies.length - 1) divider
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    return HeaderNavbar(
      backgroundColor: Colors.transparent,
      transparent: true,
      child: child,
      middleText: "Replies",
      trailing: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Routz.of(context).backToThread();
        },
        child: const Icon(CupertinoIcons.clear_thick),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    if (my.prefs.getBool('help.replies')) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Interactive(context).message(title: 'help.tip'.tr(), content: 'help.replies'.tr());
      my.prefs.put('help.replies', true);
    });
  }
}
