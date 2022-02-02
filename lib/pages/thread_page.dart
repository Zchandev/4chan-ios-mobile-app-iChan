import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ichan/blocs/blocs.dart';
import 'package:ichan/blocs/thread/barrel.dart';
import 'package:ichan/pages/thread/thread.dart';
import 'package:ichan/services/exports.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ichan/widgets/media/media_actions.dart';
import 'package:ichan/widgets/pip_window.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/foundation.dart';
import 'package:ichan/services/my.dart' as my;

class ThreadPage extends StatefulWidget {
  const ThreadPage({
    Key key,
    this.threadData,
    this.previousPageTitle,
  }) : super(key: key);

  static const routeName = '/thread';

  final ThreadData threadData;
  final String previousPageTitle;

  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> with MediaActions {
  ItemScrollController itemScrollController;
  ItemPositionsListener itemPositionsListener;

  Thread get thread => widget.threadData.thread;

  @override
  void initState() {
    // WidgetsBinding.instance.addObserver(this);
    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Positioned menuBar;
    EdgeInsets threadPadding;

    my.threadBloc.add(
      ThreadFetchStarted(thread: thread, scrollPostId: widget.threadData.rememberPostId ?? ''),
    );

    if (my.prefs.getBool('disable_autoturn')) {
      System.setAutoturn('portrait');
    }

    final data = {
      'page': 'thread',
      'threadId': thread.outerId,
      'key': thread.toKey,
      'platform': thread.platform,
    };
    my.prefs.put('last_screen', data);

    final threadNavBar = ThreadNavBar(thread: thread);

    if (my.contextTools.isPhone || my.prefs.getBool('bottom_menu')) {
      menuBar = Positioned(bottom: 0, right: 0, left: 0, child: threadNavBar);
      threadPadding = EdgeInsets.zero;
    } else if (my.prefs.getBool('right_menu')) {
      menuBar = Positioned(right: 0, top: 0, bottom: 0, child: threadNavBar);
      threadPadding = EdgeInsets.only(right: my.contextTools.threadBarWidth);
    } else {
      menuBar = Positioned(left: 0, top: 0, bottom: 0, child: threadNavBar);
      threadPadding = EdgeInsets.only(left: my.contextTools.threadBarWidth);
    }

    final threadHeaderBloc = BlocBuilder<ThreadBloc, ThreadState>(
      buildWhen: (previous, state) => thread.outerId == state.threadData?.thread?.outerId,
      builder: (context, state) {
        return Text(
          threadHeader(thread, state.threadData),
          softWrap: false,
          overflow: TextOverflow.fade,
          style: TextStyle(color: my.theme.navbarFontColor),
        );
      },
    );

    return Stack(
      children: [
        HeaderNavbar(
          transparent: true,
          onStatusBarTap: () => itemScrollController.jumpTo(index: 0),
          previousPageTitle: widget.previousPageTitle,
          backgroundColor: my.theme.postBackgroundColor,
          middle: GestureDetector(
            onTap: () {
              Interactive(context).modalList(['Go to board', 'Scroll to top']).then((val) {
                if (val == "scroll to top") {
                  my.threadBloc.add(ThreadScrollStarted(to: 'first', thread: thread));
                } else if (val == "go to board") {
                  Routz.of(context).toBoard(
                    Board(thread.boardName, platform: thread.platform),
                    replace: true,
                  );
                }
              });
            },
            child: threadHeaderBloc,
          ),
          trailing: GestureDetector(
            onTap: () => showMenu(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 15.0),
              child: Icon(CupertinoIcons.share, size: 30),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: threadPadding,
                child: PostsList(
                  thread: thread,
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                ),
              ),
              menuBar,
            ],
          ),
        ),
        const PipWindow()
      ],
    );
  }

  Future<void> showMenu(BuildContext context) async {
    final sheets = [
      const ActionSheet(text: 'Open in browser', value: 'open'),
      const ActionSheet(text: 'Copy link', value: 'copy'),
      const ActionSheet(text: 'Save thread', value: 'save'),
      const ActionSheet(text: 'Save all images', value: 'save_images'),
    ];

    final result = await Interactive(context).modal(sheets);

    if (result == 'copy') {
      Haptic.lightImpact();
      return Clipboard.setData(ClipboardData(text: thread.url));
    } else if (result == 'save') {
      final savedJson = await my.repo.on(thread.platform).api.fetchThreadPosts(thread: thread);
      final threadData = my.threadBloc.getThreadData(thread.toKey);
      final ts = threadData.threadStorage;
      ts.savedJson = savedJson;
      ts.isFavorite = true;
      ts.putOrSave();
      // print('listSize = ${widget.threadData.thread.mediaFiles.length}');
      // print('listSize = ${my.threadBloc.current.mediaList.length}');
      // for (final media in threadData.mediaList) {
      //   print('Downloading media...');
      //   // await my.mediaCache.getSingleFile(media.url);
      //   await my.mediaCache.getSingleFile(media.thumbnailUrl);
      //   await Future.delayed(0.1.seconds);
      //   print('Download finished');
      // }
      Interactive(context).message(content: "Saved to Favorites/Saved");
    } else if (result == 'save_images') {
      Haptic.mediumImpact();
      final mediaList = my.threadBloc.getThreadData(thread.toKey).mediaList;

      for (final media in mediaList) {
        if (media.isImage) {
          // print('Downloading media...');
          await saveMedia(media);
          // await Future.delayed(0.1.seconds);
        }

        // await my.mediaCache.getSingleFile(media.url);
        // await my.mediaCache.getSingleFile(media.thumbnailUrl);
      }
      Interactive(context).message(content: "Images has been saved");
    } else if (result == 'open') {
      return await System.launchUrl(thread.url);
    }
  }

  String threadHeader(Thread thread, ThreadData current) {
    if (thread.outerId == current?.thread?.outerId) {
      return current.thread.titleOrBody;
    }

    if (thread.titleOrBody?.isNotEmpty == true) {
      return thread.titleOrBody;
    } else {
      return thread.outerId;
    }
  }
}
