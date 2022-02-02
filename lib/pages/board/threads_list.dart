import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ichan/blocs/board_bloc.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/pages/board/image_data.dart';
import 'package:ichan/pages/board/thread_item.dart';
import 'package:ichan/pages/thread/animated_opacity_item.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/search_bar.dart';
import 'package:ichan/widgets/shimmer_widget.dart';
import 'package:ichan/widgets/tap_to_reload.dart';

class ThreadsList extends StatefulWidget {
  const ThreadsList({
    Key key,
    this.board,
    this.scrollNotifier,
    this.query = '',
  }) : super(key: key);

  final Board board;
  final String query;
  final ValueNotifier<bool> scrollNotifier;

  @override
  ThreadsListState createState() => ThreadsListState();
}

class ThreadsListState extends State<ThreadsList> {
  final scrollController = ScrollController(initialScrollOffset: my.prefs.getDouble('menu_margin'));
  final searchController = TextEditingController();
  final selectedTab = ValueNotifier<BoardFilter>(BoardFilter.all);
  final scrollListener = ValueNotifier<double>(0.0);
  final imageData = ImageData();

  bool isRefreshing = false;
  int loadedAt;
  String threadMode = my.prefs.getString('thread_mode', defaultValue: 'normal');

  void _onUpdateScroll(ScrollMetrics metrics) {
    const minPixels = 35;
    if (metrics.outOfRange && metrics.pixels.abs() > minPixels) {
      scrollListener.value = (metrics.pixels.abs() - minPixels) / 35.0;
    }
  }

  void _onEndScroll(ScrollMetrics metrics) {
    isRefreshing = false;
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    scrollListener.dispose();
    widget.scrollNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    my.boardBloc.add(BoardLoadStarted(board: widget.board, query: widget.query));
    if (widget.query.isNotEmpty) {
      searchController.text = "tag:${widget.query}";
    }
    my.analytics.setCurrentScreen(screenName: 'boards');
    widget.scrollNotifier.addListener(() {
      scrollController.jumpTo(0.0);
    });
  }

  void searchStart(String val) {
    my.boardBloc.add(BoardSearchTyped(query: val));
  }

  int calcItemsCount(Orientation orientation) {
    if (Consts.isIpad) {
      return orientation == Orientation.landscape ? 6 : 5;
    } else if (my.contextTools.isVerySmallHeight) {
      return orientation == Orientation.landscape ? 3 : 2;
    } else {
      return orientation == Orientation.landscape ? 4 : 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageData.width == null) {
      if (Consts.isIpad) {
        imageData.height = context.screenWidth / 6;
        imageData.width = context.screenWidth / 4;
      } else {
        imageData.height = context.screenWidth / 4;
        imageData.width = context.screenWidth / 2;
      }
    }

    final Widget content = BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        if (state is BoardError) {
          return TapToReload(
              enabled: state.reloadable,
              message: state.message,
              onTap: () => my.boardBloc.add(BoardLoadStarted(board: widget.board)));
        }

        if (state is BoardLoaded) {
          const extraItems = 3;
          loadedAt = DateTime.now().millisecondsSinceEpoch;

          final searchBar = Padding(
            padding: const EdgeInsets.symmetric(horizontal: Consts.sidePadding),
            child: SearchBar(
              placeholder: "Search",
              onChanged: searchStart,
              controller: searchController,
            ),
          );

          final segmentedControl = CupertinoSegmentedControl(
            groupValue: threadMode,
            padding: const EdgeInsets.symmetric(
                vertical: Consts.sidePadding, horizontal: Consts.sidePadding),
            selectedColor: my.theme.primaryColor,
            unselectedColor: my.theme.backgroundColor,
            onValueChanged: (val) {
              setState(() {
                loadedAt = DateTime.now().millisecondsSinceEpoch;
                threadMode = val;
                my.prefs.put("thread_mode", val);
              });
            },
            children: const <String, Widget>{
              'normal': Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Normal',
                    style: TextStyle(fontSize: 15.0),
                  )),
              'compact': Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Compact',
                    style: TextStyle(fontSize: 15.0),
                  )),
              'catalog': Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Catalog',
                    style: TextStyle(fontSize: 15.0),
                  )),
            },
          );

          final pullToRefresh = ValueListenableBuilder<double>(
              valueListenable: scrollListener,
              builder: (BuildContext context, value, Widget child) {
                final height = isIos
                    ? my.contextTools.hasHomeButton
                        ? 65.0
                        : 90.0
                    : 70.0;

                if (value >= 1.0 || isRefreshing) {
                  if (!isRefreshing && searchController.text.isEmpty) {
                    FocusScope.of(context).unfocus();
                    isRefreshing = true;
                    Haptic.lightImpact();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      my.boardBloc.add(ReloadThreads(board: widget.board));
                    });
                  }
                  return Container(height: height, child: const CupertinoActivityIndicator());
                }
                return Container(
                  height: height,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoActivityIndicator.partiallyRevealed(progress: value),
                    ],
                  ),
                );
              });

          final gridView = OrientationBuilder(
            builder: (context, orientation) {
              return CustomScrollView(
                semanticChildCount: state.threads.length,
                controller: scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      pullToRefresh,
                      searchBar,
                      if (!my.prefs.getBool('thread_mode_disabled'))
                        segmentedControl
                      else
                        const SizedBox(height: 10),
                    ]),
                  ),
                  SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: calcItemsCount(orientation),
                      childAspectRatio: 6.5 / 10,
                    ),
                    // delegate: SliverChildListDelegate(buildGridItems(state.threads)),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final thread = state.threads[index];
                        final fav = ThreadStorage.fromThread(thread);

                        return ThreadItem(
                          thread: thread,
                          board: widget.board,
                          threadStorage: fav,
                          searchController: searchController,
                          imageData: imageData,
                        );
                      },
                      childCount: state.threads.length,
                    ),
                  ),
                ],
              );
            },
          );

          final listView = ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.only(top: 0.0),
            physics: my.prefs.scrollPhysics,
            itemCount: state.threads.length + extraItems,
            semanticChildCount: state.threads.length,
            addSemanticIndexes: false,
            itemBuilder: (context, index) {
              if (index == 0) {
                return pullToRefresh;
                // return SizedBox(height: 90.0);
              }
              if (index == 1) {
                return searchBar;
              }
              if (index == 2) {
                if (my.prefs.getBool('thread_mode_disabled')) {
                  return const SizedBox(width: 0, height: 10);
                } else {
                  return segmentedControl;
                }
              }
              if (state.threads.isEmpty) {
                return Container();
              }

              final thread = state.threads[index - extraItems];
              final fav = ThreadStorage.fromThread(thread);

              return ThreadItem(
                thread: thread,
                board: widget.board,
                threadStorage: fav,
                searchController: searchController,
              );
            },
          );
          final result = AnimatedOpacityItem(
            loadedAt: loadedAt,
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollStartNotification) {
                  // _onStartScroll(scrollNotification.metrics);
                } else if (scrollNotification is ScrollUpdateNotification) {
                  _onUpdateScroll(scrollNotification.metrics);
                } else if (scrollNotification is ScrollEndNotification) {
                  _onEndScroll(scrollNotification.metrics);
                }
                return true;
              },
              child: CupertinoScrollbar(
                child: threadMode == 'catalog' ? gridView : listView,
              ),
            ),
          );
          return result;
        }

        return const Center(
          child: ShimmerLoader(),
        );
      },
    );

    return content;
  }
}
