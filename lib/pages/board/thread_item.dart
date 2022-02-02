import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/blocs/board_bloc.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/pages/board/image_data.dart';
import 'package:ichan/pages/board/thread_image.dart';
import 'package:ichan/pages/thread/post_body.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/htmlz.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/media/media_row.dart';

class ThreadItem extends StatefulWidget {
  const ThreadItem({
    Key key,
    this.thread,
    this.board,
    this.threadStorage,
    this.searchController,
    this.imageData,
  }) : super(key: key);

  final Thread thread;
  final Board board;
  final ThreadStorage threadStorage;
  final TextEditingController searchController;
  final ImageData imageData;

  @override
  _ThreadItemState createState() => _ThreadItemState();
}

class _ThreadItemState extends State<ThreadItem> {
  Thread get thread => widget.thread;

  bool showFullDate = false;
  bool isFull = false;
  String get threadMode => my.prefs.getString('thread_mode', defaultValue: 'normal');

  @override
  Widget build(BuildContext context) {
    Widget item;
    if (widget.threadStorage.isHidden) {
      item = hiddenThreadItem();
    } else {
      if (threadMode == 'catalog') {
        item = catalogThreadItem();
      } else {
        item = (threadMode == 'compact') && !isFull ? compactThreadItem() : modernThreadItem();
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: item,
      onLongPress: () {
        showThreadMenu();
      },
      onTap: () async {
        FocusScope.of(context).unfocus();
        if (widget.searchController.text.isNotEmpty) {
          cleanQuery();
        }
        await Routz.of(context).toThread(thread: thread);

        final data = {'page': 'board', 'board': widget.board};
        my.prefs.put('last_screen', data);
      },
    );
  }

  void cleanQuery() {
    Future.delayed(3.minutes).then((value) {
      final currentScreen = my.prefs.get("last_screen").cast<String, dynamic>();
      if (currentScreen['page'] != 'board') {
        my.boardBloc.add(const BoardSearchTyped(query: ""));
        widget.searchController.clear();
      }
    });
  }

  Future showThreadMenu() async {
    final text = widget.threadStorage.isHidden ? "Show" : "Hide";
    return Interactive(context).modal([
      const ActionSheet(text: "Copy link"),
      ActionSheet(text: text),
    ]).then((result) {
      if (result == text.toLowerCase()) {
        my.boardBloc.add(BoardThreadHidden(thread: thread, fav: widget.threadStorage));
      } else if (result == "copy link") {
        Haptic.lightImpact();
        return Clipboard.setData(ClipboardData(text: thread.url));
      }
    });
  }

  Widget hiddenThreadItem() {
    return Container(
      key: UniqueKey(),
      decoration: BoxDecoration(
          color: my.theme.threadBackgroundColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.0)),
      margin: const EdgeInsets.symmetric(
          horizontal: Consts.sidePadding, vertical: Consts.sidePadding / 2),
      padding: const EdgeInsets.symmetric(
          horizontal: Consts.sidePadding, vertical: Consts.sidePadding / 4),
      child: Row(
        children: <Widget>[
          Flexible(
            flex: 1,
            child: Container(
              height: Consts.threadImageHeight / 1.5,
              width: Consts.threadImageWidth / 1.5,
              alignment: Alignment.center,
              child: FaIcon(FontAwesomeIcons.eyeSlash, color: my.theme.postInfoFontColor, size: 25),
            ),
          ),
          const SizedBox(width: 10.0),
          Flexible(
            flex: 6,
            child: Text(
              thread.titleOrBody,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                inherit: false,
                fontSize: 15,
                color: my.theme.postInfoFontColor,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget imagesCounter(Thread thread, double fontSize) {
    return Row(children: [
      FaIcon(
        FontAwesomeIcons.images,
        size: fontSize,
        color: my.theme.inactiveColor,
      ),
      const SizedBox(width: 3),
      Text(
        thread.filesCount.toString(),
        style: TextStyle(
          fontSize: fontSize,
          color: my.theme.inactiveColor,
        ),
      ),
    ]);
  }

  Widget postsCounter(Thread thread, double fontSize) {
    return Row(children: [
      FaIcon(
        FontAwesomeIcons.commentAlt,
        size: fontSize,
        color: my.theme.inactiveColor,
      ),
      const SizedBox(width: 3),
      Text(
        thread.postsCount.toString(),
        style: TextStyle(
          fontSize: fontSize,
          color: my.theme.inactiveColor,
        ),
      ),
    ]);
  }

  String humanDate(Thread thread, {bool compact = false}) {
    final compact = my.contextTools.isSmallWidth;
    return my.prefs.getBool('absolute_time')
        ? thread.datetime(compact: compact)
        : thread.timeAgo(compact: compact);
  }

  Widget compactThreadItem() {
    final postTitle = Text(
      thread.cleanTitle,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: TextStyle(
        fontSize: Consts.postTitleSize,
        color: my.theme.fontColor,
        fontWeight: FontWeight.bold,
      ),
    );

    double fontSize;
    if (Consts.isIpad) {
      fontSize = 14.0;
    } else if ((thread.postsCount >= 10 && thread.filesCount >= 1000) ||
        (thread.postsCount >= 1000 && thread.filesCount >= 10)) {
      fontSize = 12.0;
    } else if (thread.postsCount <= 99 && thread.filesCount <= 99) {
      fontSize = 14.0;
    } else {
      fontSize = 13.0;
    }

    return Container(
      key: UniqueKey(),
      decoration: BoxDecoration(
          color: my.theme.threadBackgroundColor, borderRadius: BorderRadius.circular(8.0)),
      margin: const EdgeInsets.symmetric(
          horizontal: Consts.sidePadding, vertical: Consts.sidePadding / 2),
      padding: const EdgeInsets.only(
        top: Consts.sidePadding / 2,
        bottom: Consts.sidePadding / 2,
      ),
      child: Container(
        height: Consts.isIpad ? 150 : 115,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!my.prefs.getBool('disable_media')) ...[
              const SizedBox(width: Consts.sidePadding / 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  threadImage(width: Consts.threadImageWidth),
                  const SizedBox(height: 12.5),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      setState(() {
                        showFullDate = !showFullDate;
                      });
                    },
                    child: Container(
                      width: Consts.threadImageWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (showFullDate) ...[
                            Expanded(
                              child: Text(
                                humanDate(thread),
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: TextStyle(fontSize: 13, color: my.theme.inactiveColor),
                              ),
                            ),
                          ],
                          if (!showFullDate) ...[
                            postsCounter(thread, fontSize),
                            imagesCounter(thread, fontSize),
                          ]
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ],
            const SizedBox(width: Consts.sidePadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!thread.isTitleInBody) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: postTitle,
                    ),
                    const SizedBox(height: 5.0)
                  ],
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PostBody(
                        thread: thread,
                        body: thread.previewBody,
                        padding: const EdgeInsets.only(right: 10.0),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() {
                            isFull = true;
                          });
                        },
                        child: SizedBox(
                          height: 40,
                          width: context.screenWidth,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget catalogThreadItem() {
    final postTitle = Text(
      thread.cleanTitle,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: TextStyle(
        fontSize: 14,
        color: my.theme.fontColor,
        fontWeight: FontWeight.bold,
      ),
    );

    return Container(
      key: UniqueKey(),
      decoration: BoxDecoration(
          color: my.theme.threadBackgroundColor, borderRadius: BorderRadius.circular(8.0)),
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.only(bottom: Consts.sidePadding / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!my.prefs.getBool('disable_media')) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const SizedBox(height: 10),
                threadImage(width: widget.imageData.width, height: widget.imageData.height),
                const SizedBox(height: 5.0),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      postsCounter(thread, 14.0),
                      imagesCounter(thread, 14.0),
                    ],
                  ),
                ),
                const SizedBox(height: 5.0),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() {
                      showFullDate = !showFullDate;
                    });
                  },
                  child: Container(
                    width: Consts.threadImageWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (showFullDate) ...[
                          Expanded(
                            child: Text(
                              humanDate(thread),
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(fontSize: 13, color: my.theme.inactiveColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
          const SizedBox(width: Consts.sidePadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!thread.isTitleInBody) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: postTitle,
                  ),
                  const SizedBox(height: 5.0)
                ],
                Expanded(
                  child: Text(
                    Htmlz.toHuman(thread.body),
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      inherit: true,
                      fontSize: 13,
                      color: my.theme.fontColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget modernThreadItem() {
    final width = context.screenWidth - 30;
    final fontSize = my.contextTools.isVerySmallHeight ? 13.0 : 14.0;

    final postTitle = Container(
      padding: const EdgeInsets.only(left: 10.0),
      width: width,
      child: Text(
        thread.cleanTitle,
        style: TextStyle(
          fontSize: Consts.postTitleSize,
          color: my.theme.fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Container(
      key: UniqueKey(),
      decoration: BoxDecoration(
          color: my.theme.threadBackgroundColor, borderRadius: BorderRadius.circular(8.0)),
      margin: const EdgeInsets.symmetric(
          horizontal: Consts.sidePadding, vertical: Consts.sidePadding / 2),
      padding: const EdgeInsets.only(
        top: Consts.sidePadding,
        bottom: Consts.sidePadding / 2,
      ),
      child: Wrap(
        direction: Axis.vertical,
        spacing: 10.0,
        children: [
          Container(
            padding: const EdgeInsets.only(left: Consts.sidePadding / 2),
            width: width,
            child: DefaultTextStyle(
              style: TextStyle(color: my.theme.postInfoFontColor, fontSize: fontSize),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const SizedBox(width: 5.0),
                      FaIcon(FontAwesomeIcons.clock,
                          size: fontSize - 1, color: my.theme.postInfoFontColor),
                      const SizedBox(width: 5.0),
                      Text(humanDate(thread)),
                      const Text("  •  "),
                      FaIcon(FontAwesomeIcons.commentAlt,
                          size: fontSize - 1.5, color: my.theme.postInfoFontColor),
                      const SizedBox(width: 5.0),
                      Text(thread.postsCount.toString()),
                      const Text("  •  "),
                      FaIcon(FontAwesomeIcons.images,
                          size: fontSize - 1.1, color: my.theme.postInfoFontColor),
                      const SizedBox(width: 5.0),
                      Text(thread.filesCount.toString()),
                    ],
                  ),
                  // Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      showThreadMenu();
                    },
                    child: Icon(
                      CupertinoIcons.ellipsis,
                      size: fontSize + 2,
                      color: my.theme.primaryColor,
                    ),
                  )
                ],
              ),
            ),
          ),
          Container(
            width: context.screenWidth,
            padding: const EdgeInsets.only(left: Consts.sidePadding),
            child: Row(
              children: [
                Expanded(
                  child: MediaRow(
                    origin: Origin.board,
                    items: thread.mediaFiles,
                    threadData: ThreadData(thread: thread),
                  ),
                ),
              ],
            ),
          ),
          if (!thread.isTitleInBody) ...[postTitle],
          if (thread.shortBody.isNotEmpty) ...[
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PostBody(
                    thread: thread,
                    body: isFull ? thread.parsedBody : thread.shortBody,
                    padding: const EdgeInsets.only(
                        left: Consts.sidePadding, right: Consts.sidePadding * 2)),
                if (!isFull && thread.shortBody.length > Consts.bodyTrimSize) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      setState(() {
                        isFull = true;
                      });
                    },
                    child: SizedBox(
                      height: 40,
                      width: context.screenWidth,
                    ),
                  )
                ],
              ],
            )
          ],
        ],
      ),
    );
  }

  Widget threadImage({double width, double height}) {
    if (my.prefs.getBool('enable_media') == false || thread.mediaFiles.isEmpty) {
      return Container();
    } else {
      return ThreadImage(
          thread: thread, width: width ?? Consts.threadImageWidth, height: height ?? width);
    }
  }
}
