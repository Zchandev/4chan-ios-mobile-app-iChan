import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ichan/blocs/thread/barrel.dart';
// import 'package:ichan/db/app_db.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/ui/haptic.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/media/media_row.dart';
import 'thread.dart';

class PostItem extends HookWidget {
  const PostItem({
    Key key,
    @required this.post,
    @required this.threadData,
    this.isFirst = false,
    this.isLast = false,
    this.origin = Origin.thread,
    this.highlightPostId = '',
    this.highlightMedia,
  }) : super(key: key);

  final Post post;
  final ThreadData threadData;
  final bool isFirst;
  final bool isLast;
  final Origin origin;
  final String highlightPostId;
  final Media highlightMedia;

  Thread get thread => threadData.thread;
  bool get showThreadLink => origin == Origin.activity || origin == Origin.navigator;

  static String spacer = '  •  ';

  String highlighted(String body) {
    if (highlightPostId.isEmpty || origin != Origin.reply) {
      return body;
    }

    final linkCount = 'post-reply-link'.allMatches(body).length;

    if (linkCount <= 1) {
      return body;
    }

    return body.replaceAll('>>$highlightPostId', '<u>>>$highlightPostId</u>');
  }

  void quoteAction(BuildContext context, {String body}) {
    my.postBloc.addText(body, fav: threadData.threadStorage);

    Routz.of(context)
        .toPage(NewPostPage(thread: thread), title: thread.trimTitle(Consts.navLeadingTrimSize));
  }

  List<Post> createReplies(replies) {
    final List<Post> result = [];
    // final posts = threadData.posts;

    for (final id in replies) {
      try {
        final _posts = threadData.posts.firstWhere((e) => e.outerId == id, orElse: () => null);

        if (_posts != null) {
          result.add(_posts);
        }
      } catch (e) {
        print("COUND NOT CREATE REPLY");
      }
    }
    return result;
  }

  Future showReportDialog(BuildContext context, {TextEditingController controller}) {
    final action = CupertinoDialogAction(
      isDefaultAction: true,
      child: const Text("Report"),
      onPressed: () {
        final payload = {
          "boardName": thread.boardName,
          "threadId": thread.outerId,
          "postId": post.outerId,
          "comment": controller.text,
        };

        my.threadBloc.add(ThreadReportPressed(payload));
        Navigator.of(context).pop();
      },
    );

    return Interactive(context).modalTextField(
      controller: controller,
      header: "Comment",
      action: action,
    );
  }

  void showReplies(BuildContext context, List<Post> replies) {
    final page = PostReplies(
      replies: replies,
      threadData: threadData,
      highlightPostId: post.outerId,
      origin: origin,
    );
    if (my.prefs.getBool('replies_on_top')) {
      Routz.of(context).toPage(page, title: "Replies");
    } else {
      final opaque = origin != Origin.thread;
      Routz.of(context).fadeToPage(page, title: "Replies", opaque: opaque);
    }
  }

  void replyCallback(BuildContext context, {ThreadLink threadLink}) async {
    final currentThread = thread;

    if (currentThread.outerId == threadLink.threadId) {
      final _posts = threadData.posts.where((e) {
        return e.outerId == threadLink.postId;
      }).toList();
      if (_posts.isNotEmpty) {
        showReplies(context, _posts);
      } else {
        Interactive(context).message(title: "Post not found");
      }
    } else {
      await Routz.of(context).toThread(threadLink: threadLink);
      return;
    }
  }

  Future<void> showPostDialog(BuildContext context, {TextEditingController controller}) async {
    if (origin == Origin.example) {
      return;
    }

    final actionSheets = [
      const ActionSheet(text: "Reply"),
      const ActionSheet(text: "Quote"),
      // const ActionSheet(text: "Set unread", value: "mark_unread"),
      if (origin == Origin.reply || origin == Origin.mediaInfo) ...[
        const ActionSheet(text: "Go to post")
      ],
      if (post.isMine && post.platform == Platform.fourchan) ...[
        ActionSheet(text: "Delete", color: my.theme.alertColor),
      ],
      if (!post.isMine) ...[
        ActionSheet(text: "Report", color: my.theme.alertColor),
      ]
    ];

    final result = await Interactive(context).modal(actionSheets);

    if (result == 'reply') {
      return quoteAction(context, body: '>>${post.outerId}');
    } else if (result == "go to post") {
      Haptic.mediumImpact();
      Routz.of(context).backToThread();
      my.threadBloc.add(ThreadScrollStarted(postId: post.outerId, thread: thread));
    } else if (result == "delete") {
      my.threadBloc.add(ThreadDeletePressed(post: post));
    } else if (result == "report") {
      showReportDialog(context, controller: controller);
    } else if (result == "quote") {
      return Routz.of(context).toPage(PostQuote(thread: thread, post: post));
    } else if (result == "mark_unread") {
      final actualData = my.threadBloc.getThreadData(thread.toKey);
      final ts = actualData.threadStorage;
      ts.unreadPostId = post.outerId;
      ts.rememberPostId = post.outerId;
      final newCount = actualData.posts.length - actualData.postIdToIndex(post.outerId) - 1;
      if (newCount >= 0) {
        ts.unreadCount = newCount;
      } else {
        ts.unreadCount = 0;
      }
    }

    return;
  }

  Color postBackgroundColor() {
    if (post.isMine && !showThreadLink) {
      return my.theme.myPostBackgroundColor;
    } else {
      return my.theme.postBackgroundColor;
    }
  }

  Color countersColor() {
    if (post.isMine) {
      return my.theme.foregroundBrightColor;
    } else if (post.isOp) {
      return CupertinoColors.activeGreen;
    } else {
      return my.theme.postInfoFontColor;
    }
  }

  Widget postCounters(ValueNotifier postChanged, BuildContext context) {
    String text;
    text = '#${post.counter}';
    text += "$spacer${post.outerId}";
    if (post.isMine) {
      text += " (Y)";
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final modalList = [
          const ActionSheet(text: 'Copy link', value: 'copy'),
          const ActionSheet(text: 'Mark unread', value: 'unread'),
          if (post.isMine)
            ActionSheet(text: 'Not mine', value: 'not_mine', color: my.theme.alertColor)
          else
            const ActionSheet(text: 'Mark as mine', value: 'mine'),
        ];
        Interactive(context).modal(modalList).then((val) {
          if (val == "copy") {
            Haptic.lightImpact();
            return Clipboard.setData(ClipboardData(text: post.url(thread)));
          } else if (val == "unread") {
            threadData.markUnread(post.outerId);
          } else if (val == "not_mine") {
            post.isMine = false;
            my.posts.put(post.toKey, post);
            postChanged.value = !postChanged.value;

            final ThreadStorage thread = my.favs.get(post.toKey);
            if (thread != null && thread.isOp) {
              thread.opCookie = '';
              thread.save();
            }
          } else if (val == "mine") {
            post.isMine = true;
            my.posts.put(post.toKey, post);
            postChanged.value = !postChanged.value;
          }
        });
      },
      child: Text(
        text,
        style: TextStyle(
          fontWeight: post.isOp ? FontWeight.w600 : FontWeight.normal,
          color: countersColor(),
        ),
      ),
    );
  }

  Widget threadInfo(ValueNotifier postChanged, BuildContext context) {
    String text;
    text = '/${thread.boardName}/ – ${thread.trimTitle(20)}';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        toThread(context);
      },
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: my.theme.foregroundBrightColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postChanged = ValueNotifier<bool>(false);
    final reportCommentController = useTextEditingController();
    final repliesCondition = post.replies != null && post.replies.isNotEmpty;

    final postBottom = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (post.replies != null && post.replies.isNotEmpty) {
          final replies = createReplies(post.replies);
          showReplies(context, replies);
        }
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 5.0, top: 7.0),
        child: Row(
          mainAxisAlignment: my.prefs.getBool('time_at_right')
              ? MainAxisAlignment.start
              : MainAxisAlignment.spaceBetween,
          children: [
            if (!my.prefs.getBool('time_at_right')) ...[
              Text(
                my.prefs.getBool('absolute_time') ? post.datetime : post.timeAgo,
                style: TextStyle(
                  color: my.theme.postInfoFontColor,
                  fontSize: Consts.postInfoFontSize,
                ),
              )
            ],
            if (repliesCondition && origin != Origin.navigator) ...[
              AnimatedOpacityItem(
                loadedAt: threadData.refreshedAt,
                child: Text(
                  'reply'.plur(post.replies.length),
                  style: TextStyle(
                    color: my.theme.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
            if (origin == Origin.navigator) ...[
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  post.isUnread = false;
                  if (post.isInBox) {
                    post.save();
                  }
                  my.favoriteBloc.updateUnreadReplies();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0, top: 5.0),
                  child: FaIcon(FontAwesomeIcons.times,
                      color: my.theme.inactiveColor.withOpacity(0.8), size: 12),
                ),
              )
            ]
          ],
        ),
      ),
    );

    Widget filesList = Container();

    if (post.mediaFiles?.isNotEmpty == true && my.prefs.getBool('enable_media')) {
      filesList = Container(
        margin: EdgeInsets.only(bottom: post.body.isEmpty ? 0.0 : 10.0),
        child: MediaRow(
          origin: origin,
          items: post.mediaFiles,
          threadData: threadData,
          highlightMedia: highlightMedia,
        ),
      );
    }

    Widget postBody = PostBody(
      thread: thread,
      body: highlighted(post.parsedBody),
      replyCallback: replyCallback,
    );

    if (showThreadLink) {
      postBody = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          toThreadMenu(context);
        },
        child: postBody,
      );
    }

    return ValueListenableBuilder(
      valueListenable: postChanged,
      builder: (context, val, widget) {
        return Container(
          decoration: BoxDecoration(
            color: postBackgroundColor(),
            border: postBorder(),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Consts.sidePadding,
            vertical: 2.5,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: () {
                return showPostDialog(context);
              },
              child: Wrap(
                children: [
                  buildPostInfo(context, postChanged, reportCommentController),
                  filesList,
                  if (post.parsedBody.isNotEmpty) ...[postBody],
                  postBottom
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildPostInfo(BuildContext context, ValueNotifier<bool> postChanged,
      TextEditingController reportCommentController) {
    double fontSize = Consts.postInfoFontSize;
    if (my.contextTools.isVerySmallHeight) {
      fontSize = post.tripcode.isNotEmpty && post.name.isNotEmpty ? 10.0 : fontSize;
      spacer = ' • ';
    }

    final showEmail =
        my.prefs.getBool('time_at_right') == false && post.email.isNotEmpty && post.isSage == false;

    // final showUniques = isFirst && post.threadUniques?.isNotEmpty == true;
    final showUniques = isFirst && threadData.thread?.uniquePosters != null;

    final showOp = post.isOp &&
        post.tripcode.isEmpty &&
        post.name == my.repo.on(post.platform).defaultAnonName;

    return Container(
      child: DefaultTextStyle(
        style: TextStyle(color: my.theme.postInfoFontColor, fontSize: fontSize),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                if (showThreadLink)
                  threadInfo(postChanged, context)
                else
                  postCounters(postChanged, context),
                AnimatedOpacityItem(
                  loadedAt: threadData.refreshedAt,
                  child: Row(
                    children: [
                      if (showOp) ...[
                        const Text("  •  OP",
                            style: TextStyle(
                                color: CupertinoColors.activeGreen, fontWeight: FontWeight.w600))
                      ],
                      if (showUniques) ...[
                        Wrap(
                          spacing: 5,
                          children: [
                            const Text('  • '),
                            FaIcon(FontAwesomeIcons.users, size: 12, color: my.theme.linkColor),
                            Text(threadData.thread.uniquePosters.toString(),
                                style: TextStyle(
                                    color: my.theme.linkColor, fontWeight: FontWeight.w600)),
                          ],
                        )
                      ],
                      if (post.isSage) ...[
                        const Text('  •  '),
                        const Text("SAGE",
                            style: TextStyle(
                                color: CupertinoColors.destructiveRed, fontWeight: FontWeight.w600))
                      ],
                      if (showEmail) ...[
                        const Text('  •  '),
                        Text(post.email,
                            style: const TextStyle(
                                color: CupertinoColors.activeBlue, fontWeight: FontWeight.w600))
                      ],
                      if (post.tripcode.isNotEmpty) ...[
                        const Text('  •  '),
                        Text(post.tripcode,
                            style: const TextStyle(color: CupertinoColors.systemPurple))
                      ],
                      if (post.nameToOutput.isNotEmpty) ...[
                        const Text('  •  '),
                        Text(post.nameToOutput,
                            style: const TextStyle(color: CupertinoColors.systemPurple)),
                      ],
                      if (post.isBanned) ...[
                        const Text('  •  '),
                        const Text('BAN',
                            style: TextStyle(
                                color: CupertinoColors.destructiveRed, fontWeight: FontWeight.bold))
                      ]
                    ],
                  ),
                ),
              ],
            ),
            if (my.prefs.getBool('time_at_right')) ...[
              Text(my.prefs.getBool('absolute_time') ? post.datetime : post.timeAgo),
            ],
            buildEllipsis(
              onTap: () => showPostDialog(context, controller: reportCommentController),
            )
          ],
        ),
      ),
    );
  }

  Widget buildEllipsis({Function onTap}) {
    assert(post.isToMe != null);

    return Flexible(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => onTap(),
        child: Container(
          padding: const EdgeInsets.only(bottom: 10.0, left: 10.0, top: 0.0),
          child: Icon(CupertinoIcons.ellipsis,
              size: 16, color: post.isToMe ? my.theme.linkColor : my.theme.primaryColor),
        ),
      ),
    );
  }

  Border postBorder() {
    if (post.isToMe && !showThreadLink) {
      return Border(
        left: BorderSide(
          color: my.theme.linkColor,
          style: BorderStyle.solid,
          width: 2,
        ),
      );
    }
    return null;
  }

  void toThreadMenu(BuildContext context) {
    final modalList = [
      const ActionSheet(text: 'Go to thread', value: 'to_thread'),
    ];
    Interactive(context).modal(modalList).then((val) {
      if (val == "to_thread") {
        toThread(context);
      }
    });
  }

  void toThread(BuildContext context) {
    final threadLink = ThreadLink(
      boardName: thread.boardName,
      threadId: thread.outerId,
      threadTitle: thread.title,
      postId: post.outerId,
      platform: thread.platform,
    );
    Routz.of(context).toThread(threadLink: threadLink);
  }
}
