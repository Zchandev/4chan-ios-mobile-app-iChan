import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:ichan/blocs/thread/barrel.dart';
// import 'package:ichan/pages/thread/gallery_page.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/blur_filter.dart';
import 'package:ichan/widgets/my/my_cupertino_button.dart';
import 'package:ichan/widgets/search_bar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'thread.dart';

enum ButtonStatus { active, inactive, error }

class ThreadNavBar extends StatefulWidget {
  const ThreadNavBar({Key key, this.thread}) : super(key: key);

  final Thread thread;

  @override
  _ThreadNavBarState createState() => _ThreadNavBarState();
}

class _ThreadNavBarState extends State<ThreadNavBar> {
  bool searchMode = false;
  TextEditingController searchController;

  @override
  void initState() {
    searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollButton = CupertinoButton(
      padding: my.contextTools.navButtonPadding,
      onPressed: () {
        my.threadBloc.add(ThreadScrollStarted(thread: widget.thread, to: 'last'));
      },
      child: FaIcon(
        my.icons.arrowDown,
        color: my.theme.primaryColor,
        size: Consts.bottomBarIconSize,
      ),
    );

    return BlocBuilder<ThreadBloc, ThreadState>(
      buildWhen: (previous, state) {
        if (state?.threadData == null) {
          // print("NOT BUILDING NAV BAR");
          return false;
        }

        final result = widget.thread.toKey == state.threadData?.thread?.toKey;
        if (!result) {
          // print("NOT BUILDING NAV BAR");
        }
        return result;
      },
      builder: (context, state) {
        final threadData = state.threadData;
        if (threadData?.thread?.outerId != widget.thread.outerId) {
          return Container();
        }

        // print("query is ${threadData.searchData.query}");

        final isClosed = threadData?.thread?.isClosed == true;
        final postButton = CupertinoButton(
          padding: my.contextTools.navButtonPadding,
          onPressed: () {
            if (isClosed) {
              Interactive(context).message(content: "Thread is closed");
              return;
            }
            if (threadData?.thread != null) {
              my.threadBloc.add(
                ThreadClosed(threadData: threadData),
              );
            }

            Routz.of(context).toPage(
              NewPostPage(thread: threadData.thread),
              title: threadData.thread.trimTitle(Consts.navLeadingTrimSize),
            );
          },
          child: FaIcon(
            my.icons.pencil,
            color: isClosed ? my.theme.inactiveColor : my.theme.primaryColor,
            size: Consts.bottomBarIconSize,
          ),
        );

        // print(
        //     "NAVBAR state is $state, listenable is ${threadData?.scrollData?.listenable?.value?.length}");

        // print("State is $state");

        final favoriteButton = CupertinoButton(
          padding: my.contextTools.navButtonPadding,
          onPressed: () {
            if (threadData.isFavorite) {
              threadData.removeFavorite();
            } else {
              threadData.addFavorite();
            }
            my.favoriteBloc.favoriteUpdated();
          },
          child: ValueListenableBuilder<Box<ThreadStorage>>(
            valueListenable: my.favs.box.listenable(keys: [widget.thread.toKey]),
            builder: (context, box, child) {
              final ts = box.get(widget.thread?.toKey) ?? ThreadStorage.empty();

              return FaIcon(
                ts.isFavorite ? my.icons.solidFavorite : my.icons.emptyFavorite,
                color: my.theme.primaryColor,
                size: Consts.bottomBarIconSize,
              );
            },
          ),
        );

        // final galleryButton = CupertinoButton(
        //   padding: my.contextTools.navButtonPadding,
        //   onPressed: () {
        //     if (threadData.isReadable == false) {
        //       return;
        //     }
        //     Navigator.push(
        //       context,
        //       CupertinoPageRoute(
        //         builder: (context) => GalleryPage(threadData: threadData),
        //       ),
        //     );
        //   },
        //   child: FaIcon(
        //     my.icons.gallery,
        //     color: my.theme.primaryColor,
        //     size: Consts.bottomBarIconSize,
        //   ),
        // );

        final searchButton = CupertinoButton(
          padding: my.contextTools.navButtonPadding,
          onPressed: () {
            setState(() {
              searchMode = true;
            });
          },
          child: FaIcon(
            FontAwesomeIcons.search,
            color: my.theme.primaryColor,
            size: Consts.bottomBarIconSize,
          ),
        );

        if (searchMode) {
          final searchData = threadData.searchData;

          if (searchController.text.isNotEmpty && searchData.isEmpty) {
            Haptic.lightImpact();
          }

          // print('searchData.results: ${searchData.results.length}');

          return Container(
            padding: const EdgeInsets.fromLTRB(
                Consts.sidePadding, Consts.sidePadding, Consts.sidePadding, 0),
            decoration: BoxDecoration(
              color: my.theme.backgroundColor,
              border: Border(top: BorderSide(color: my.theme.navBorderColor)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                        flex: 8,
                        child: SearchBar(
                          controller: searchController,
                          onChanged: (val) {
                            my.threadBloc.add(
                              ThreadSearchStarted(thread: widget.thread, query: val),
                            );
                          },
                          autofocus: true,
                        )),
                    const SizedBox(width: 10.0),
                    Flexible(
                      flex: 1,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() {
                            searchMode = false;
                          });
                          threadData.searchData.reset();
                          searchController.text = '';
                        },
                        child: const Text(
                          "Close",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (searchController.text.isNotEmpty) ...[
                      if (searchData.isEmpty) ...[
                        const Flexible(flex: 8, child: Text('Not found'))
                      ],
                      if (searchData.isNotEmpty) ...[
                        Flexible(
                            flex: 8,
                            child: Text("${searchData.pos} of ${searchData.results.length}"))
                      ],
                    ],
                    if (searchController.text.isEmpty) ...[
                      const Spacer(),
                    ],
                    Container(
                      width: 85.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              final newPos = searchData.pos - 1;
                              if (newPos <= 0) {
                                Haptic.lightImpact();
                                return;
                              }
                              my.threadBloc.add(
                                ThreadSearchStarted(
                                  thread: widget.thread,
                                  query: searchController.text,
                                  pos: newPos,
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: FaIcon(FontAwesomeIcons.chevronUp),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              final newPos = searchData.pos + 1;
                              if (newPos >= searchData.results.length + 1) {
                                Haptic.lightImpact();
                                return;
                              }
                              my.threadBloc.add(
                                ThreadSearchStarted(
                                  thread: widget.thread,
                                  query: searchController.text,
                                  pos: newPos,
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: FaIcon(FontAwesomeIcons.chevronDown),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        }

        return BlurFilter(
          child: Container(
            alignment: (my.contextTools.isPhone && my.contextTools.hasHomeButton == false) ||
                    my.prefs.getBool('bottom_menu')
                ? Alignment.topCenter
                : Alignment.center,
            height: my.contextTools.threadBarHeight,
            width: my.contextTools.threadBarWidth,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: my.theme.navBorderColor)),
              color: my.theme.bottomBarBackground,
            ),
            child: Flex(
              direction: my.contextTools.isPhone || my.prefs.getBool('bottom_menu')
                  ? Axis.horizontal
                  : Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: scrollButton),
                Expanded(child: postButton),
                Expanded(child: UnreadRefreshButton(thread: widget.thread, state: state)),
                Expanded(child: favoriteButton),
                // Expanded(child: galleryButton),
                Expanded(child: searchButton),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ActiveButton extends StatelessWidget {
  const ActiveButton({
    Key key,
    this.status = ButtonStatus.active,
    this.onPressed,
    this.onLongPress,
  }) : super(key: key);

  final ButtonStatus status;
  final Function onPressed;
  final Function onLongPress;

  @override
  Widget build(BuildContext context) {
    if (status == ButtonStatus.inactive) {
      return MyCupertinoButton(
        padding: my.contextTools.navButtonPadding,
        onPressed: () => false,
        child: LoopAnimation<double>(
          tween: 0.0.tweenTo(math.pi * 12),
          duration: 10.seconds,
          curve: Curves.linear,
          builder: (context, child, value) {
            return Transform.rotate(
              angle: value,
              child: FaIcon(my.icons.refresh,
                  size: Consts.bottomBarIconSize, color: my.theme.inactiveColor),
            );
          },
        ),
      );
    } else {
      final colorMap = {
        ButtonStatus.error: my.theme.alertColor.withOpacity(0.75),
        ButtonStatus.inactive: my.theme.primaryColor,
        ButtonStatus.active: my.theme.primaryColor,
      };

      return MyCupertinoButton(
        padding: my.contextTools.navButtonPadding,
        onPressed: () => onPressed(),
        onLongPress: () => onLongPress == null ? null : onLongPress(),
        child: FaIcon(
          my.icons.refresh,
          size: Consts.bottomBarIconSize,
          color: colorMap[status],
        ),
      );
    }
  }
}

class UnreadRefreshButton extends StatelessWidget {
  const UnreadRefreshButton({Key key, this.thread, this.state}) : super(key: key);

  final Thread thread;
  final ThreadState state;
  static int lastScrollTo = 0;
  static int cooldown = 0;

  @override
  Widget build(BuildContext context) {
    final threadData = state?.threadData;
    final status = state is ThreadError
        ? ButtonStatus.error
        : (state is ThreadLoading || state is ThreadEmpty)
            ? ButtonStatus.inactive
            : ButtonStatus.active;

    final refreshButton = ActiveButton(
      status: status,
      onLongPress: () {
        Haptic.mediumImpact();
        my.threadBloc.add(ThreadClosed(threadData: threadData));
        my.threadBloc.add(ThreadFetchStarted(thread: thread, force: true));
      },
      onPressed: () {
        Haptic.lightImpact();
        my.threadBloc.add(ThreadRefreshStarted(thread: thread));
      },
    );

    final showRefresh = state is ThreadLoading || threadData?.scrollData?.listenable == null;

    if (showRefresh) {
      return refreshButton;
    } else {
      return ValueListenableBuilder<Iterable<ItemPosition>>(
        key: ValueKey("listenable-${thread.toKey}"),
        valueListenable: threadData?.scrollData?.listenable,
        builder: (context, val, snapshot) {
          if (val.isEmpty) {
            return refreshButton;
          }

          final pos = val.last.index + 1;
          final count = threadData.posts.length - pos;
          final ts = threadData.threadStorage;

          // Wtf
          if (ts.unreadCount < 0) {
            ts.unreadCount = 0;
          }
          final justReadNewPost = count < ts.unreadCount;

          int unreadCount = count;
          if (justReadNewPost) {
            ts.unreadCount = unreadCount;
            if (unreadCount == 0) {
              my.threadBloc.add(ThreadRefreshStarted(thread: thread));
              ts.unreadPostId = threadData.posts.last.outerId;
              ts.hasReplies = false;
              ts.putOrSave().then((value) {
                my.favoriteBloc.updateUnreadThreads();
              });

              cooldown = DateTime.now().millisecondsSinceEpoch;
            }
          } else {
            unreadCount = ts.unreadCount;
          }

          if (unreadCount == 0) {
            final pullToRefresh =
                pos >= threadData.posts.length && val.last.itemTrailingEdge <= 0.8;

            // print(
            //     'pos = ${pos}, threadData.posts.length = ${threadData.posts.length}, val.last.itemTrailingEdge = ${val.last.itemTrailingEdge}');
            // print('System.timeDiff(cooldown) = ${System.timeDiff(cooldown)}');
            final cooldowned = cooldown.timeDiff >= 2000;

            if (pullToRefresh && cooldowned) {
              cooldown = DateTime.now().millisecondsSinceEpoch;
              // print("Haptic");
              Haptic.lightImpact();
              my.threadBloc.add(ThreadRefreshStarted(thread: thread, delay: 0.5.seconds));
            }
            return refreshButton;
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () {
              Haptic.lightImpact();
              my.threadBloc.add(ThreadRefreshStarted(thread: thread));
            },
            onTap: () {
              if (unreadCount == count) {
                final index = threadData.posts.length - count - 1;
                onCounterTap(index, threadData);
              } else {
                final index = threadData.posts.length - unreadCount - 4;
                onCounterTap(index, threadData);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Padding(
                    padding: my.contextTools.navButtonPadding,
                    child: Container(
                      height: 35,
                      alignment: Alignment.center,

                      // decoration: BoxDecoration(
                      //     color: my.theme.primaryColor.withOpacity(0.6),
                      //     borderRadius: BorderRadius.circular(15.0)),
                      child: Text(
                        "$unreadCount",
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: my.theme.primaryColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void onCounterTap(int index, ThreadData threadData) {
    final lastIndex = threadData.posts.length - 2;

    if (index >= lastIndex) {
      my.threadBloc.add(ThreadScrollStarted(to: 'last', thread: thread));
      return;
    }

    if (lastScrollTo == index) {
      index += 1;
    }
    lastScrollTo = index;
    my.threadBloc.add(ThreadScrollStarted(to: 'index', index: index, thread: thread));
  }
}
