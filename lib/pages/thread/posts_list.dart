import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ichan/blocs/thread/barrel.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/dash_separator.dart';
import 'package:ichan/widgets/shimmer_widget.dart';
import 'package:ichan/widgets/tap_to_reload.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'thread.dart';

// ignore: must_be_immutable
class PostsList extends StatelessWidget {
  PostsList({
    Key key,
    this.thread,
    this.itemScrollController,
    this.itemPositionsListener,
  }) : super(key: key);

  final Thread thread;
  ThreadData actualData;
  ScrollData scrollData;
  int lastUnreadIndex;

  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  Future<void> scrollTo({int index, double alignment}) async {
    if (itemScrollController.isAttached) {
      itemScrollController.jumpTo(index: index, alignment: alignment);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(thread != null);

    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

    return BlocConsumer<ThreadBloc, ThreadState>(
      listenWhen: (previousState, state) {
        // final isError =
        //     state is ThreadError && state.code != 503 && state.code != 502;
        final result = ((state is ThreadMessage) || (state is StartScroll)) &&
            thread.toKey == state?.threadData?.thread?.toKey;
        if (!result) {
          // print(
          // "NOT LISTENING THREAD ${thread.title} BECAUE STATE IS $state, DATA IS ${state.threadData?.thread?.title}");
        }
        return result;
      },
      listener: (context, state) {
        if (state is ThreadError) {
          Interactive(context).message(title: "Error", content: state.message);
        }
        if (state is ThreadMessage) {
          Interactive(context).message(title: state.title, content: state.message);
        }
        if (state is StartScroll && state.index != -1) {
          scrollTo(
            index: state.index,
            alignment: calcScrollAlignment(
              posts: actualData.posts,
              scrollIndex: state.index,
            ),
          );
        }
      },
      buildWhen: (previous, state) {
        // print("Previous is ${previous.threadData?.thread?.title}");
        // print("Now is ${state.threadData?.thread?.title}");
        final result = thread.toKey == state.threadData.thread.toKey;
        if (!result) {
          // print(
          //     "NOT BUILDING THREAD ${thread.title} BECAUE STATE IS $state, DATA IS ${state.threadData?.thread?.title}");
        }
        return result;
      },
      builder: (context, state) {
        // print(
        //     "Building thread ${thread.title}, state thread is ${state.threadData?.thread?.title}");

        final errorPanel = TapToReload(
          message: state is ThreadError ? state.message : "Error.",
          onTap: () {
            if (itemScrollController != null && itemScrollController.isAttached) {
              itemScrollController.jumpTo(index: 0);
            }
            my.threadBloc.add(ThreadFetchStarted(thread: thread));
          },
        );

        if (state is ThreadEmpty) {
          return const ShimmerLoader(debugInfo: "State is empty, loading");
        }

        if (state is ThreadLoading || state is ThreadLoaded || state is ThreadError) {
          // final was = threadData?.status;
          // print("=== status WAS: $was");

          actualData = state.threadData;
          if (actualData?.thread?.outerId != thread.outerId) {
            return errorPanel;
          }
          final loadedAt = actualData.refreshedAt ?? DateTime.now().millisecondsSinceEpoch;
          scrollData = actualData.scrollData;
          scrollData.listenable = itemPositionsListener.itemPositions;

          // print("=== status NOW: ${actualData?.status}");

          List<Widget> preloadedPosts = [];
          if (actualData == null) {
            // print("Looks like we got previous state here");
            return const ShimmerLoader(debugInfo: "actualData is null, loading");
          } else {
            scrollData.unreadIndex = actualData.unreadPostIndex;
            scrollData.rememberIndex = actualData.scrollIndex;
            lastUnreadIndex ??= scrollData.unreadIndex;
            // print(
            //     "Posts: ${actualData.posts.length} unread: ${scrollData.unreadIndex}, remember:  ${scrollData.rememberIndex}");
            if (scrollData.rememberIndex <= 0) {
              scrollData.rememberIndex = 0;
            }

            preloadedPosts = buildPreloadedPosts(actualData.posts);
            _showHelp(context);
          }

          // print(
          //     'scrollIndex = ${scrollData.rememberIndex}, scrollAlignment = ${calcScrollAlignment(posts: actualData.posts, scrollIndex: scrollData.rememberIndex)}');

          final isEmpty = actualData.posts == null || actualData.posts.isEmpty;

          if (isEmpty && state is ThreadError) {
            return errorPanel;
          }

          // final unreadPostIndex = actualData.unreadPostIndex;
          // print("state is $state, Unread index is ${scrollData.unreadIndex}");
          return CupertinoScrollbar(
            // child: ScrollablePositionedList.separated(
            child: ScrollablePositionedList.separated(
              padding: EdgeInsets.only(bottom: my.contextTools.threadBarHeight),
              physics: my.prefs.scrollPhysics,
              initialScrollIndex: scrollData.rememberIndex,
              initialAlignment: calcScrollAlignment(
                  posts: actualData.posts, scrollIndex: scrollData.rememberIndex),
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
              itemCount: actualData.posts.length,
              separatorBuilder: (context, index) {
                if (state is ThreadLoaded || state is ThreadLoading) {
                  if (scrollData.unreadIndex > 0 && scrollData.unreadIndex == index) {
                    return AnimatedOpacityItem(
                      loadedAt: loadedAt,
                      child: const DashSeparator(height: 1.5),
                    );
                  }

                  if (lastUnreadIndex == index && index > 0) {
                    const delay = 1.5;
                    Future.delayed(delay.seconds).then((_) {
                      lastUnreadIndex = -1;
                    });

                    return AnimatedOpacityItem(
                      child: Stack(
                        children: [
                          AnimatedOpacityItem(
                            delay: delay,
                            child: Divider(
                              color: my.theme.dividerColor,
                              height: 1,
                              thickness: 1,
                            ),
                          ),
                          const AnimatedOpacityItem(
                            reverse: true,
                            delay: delay,
                            child: DashSeparator(height: 1.5),
                          ),
                        ],
                      ),
                    );
                  }
                }

                return AnimatedOpacityItem(
                  loadedAt: loadedAt,
                  child: Divider(
                    color: my.theme.dividerColor,
                    height: 1,
                    thickness: 1,
                  ),
                );
              },
              itemBuilder: (context, index) {
                assert(index != -1);
                assert(actualData.posts != null);

                PostItem postItem;

                postItem = preloadedPosts.elementAtOrNull(index);

                if (postItem != null) {
                  // if we open it from board with one post loaded
                  if (index == 0 && actualData.posts.length == 1) {
                    return SafeArea(
                      bottom: false,
                      left: false,
                      right: false,
                      child: Column(
                        children: [
                          postItem,
                          if (state is ThreadLoading) ...[
                            const ShimmerLoader(debugInfo: "State is loading")
                          ],
                          if (state is ThreadError) ...[
                            Container(padding: const EdgeInsets.only(top: 50.0), child: errorPanel)
                          ]
                        ],
                      ),
                    );
                  }

                  return index == 0
                      ? SafeArea(bottom: false, left: false, right: false, child: postItem)
                      : AnimatedOpacityItem(
                          loadedAt: loadedAt,
                          child: postItem,
                        );
                }

                return Container();
              },
            ),
          );
        }

        if (state is ThreadError) {
          return errorPanel;
        }

        return const Center(child: Text("No data"));
      },
    );
  }

  double calcScrollAlignment({List<Post> posts, int scrollIndex}) {
    final diff = posts.length - scrollIndex;

    double result;

    if (scrollIndex <= 0) {
      result = 0.0;
    } else if (posts.length <= 4) {
      result = 0.0;
    } else if (diff >= 10) {
      // result = my.prefs.isClassic ? 0.0 : 0.11;
      result = 0.11;
      if (actualData.searchData.isNotEmpty) {
        result += 0.1;
      }
    } else {
      final symbolsCount = posts.reversed
          .take(diff)
          .map((e) => e.mediaFiles.isEmpty ? e.cleanBody.length : e.cleanBody.length + 100)
          .sum();

      // Log.info("diff is $diff, length is $symbolsCount");

      if (symbolsCount >= 1000) {
        result = 0.0;
      } else if (symbolsCount >= 800) {
        result = 0.33;
      } else if (symbolsCount >= 700) {
        result = 0.4;
      } else if (symbolsCount >= 500) {
        result = 0.5;
      } else if (symbolsCount >= 300) {
        result = 0.58;
      } else if (symbolsCount >= 200) {
        result = 0.63;
      } else if (symbolsCount >= 150) {
        result = 0.70;
      } else if (symbolsCount >= 100) {
        result = 0.74;
      } else if (symbolsCount >= 60) {
        result = 0.77;
      } else if (symbolsCount >= 20) {
        result = 0.79;
      } else {
        result = 0.81;
      }

      // if (!my.prefs.isClassic && result == 0.0) {
      if (result == 0.0) {
        result += 0.11;
      }

      if (!isDebug) {
        Log.info("Align is $result");
      }
    }

    return result;
  }

  List<Widget> buildPreloadedPosts(List<Post> posts) {
    final List<Widget> result = [];

    int index = 0;
    for (final post in posts) {
      final postItem = PostItem(
        origin: Origin.thread,
        post: post,
        threadData: actualData,
        isFirst: index == 0,
      );

      result.add(postItem);
      index += 1;
    }
    return result;
  }

  void _showHelp(BuildContext context) {
    if (my.prefs.getBool('help.thread')) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Interactive(context).message(title: 'help.tip'.tr(), content: 'help.thread'.tr());
      my.prefs.put('help.thread', true);
    });
  }
}
