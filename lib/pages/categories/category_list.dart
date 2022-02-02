import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ichan/blocs/blocs.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/pages/categories/separated_sliver_list.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/routz.dart';
import 'package:ichan/widgets/search_bar.dart';
import 'package:ichan/widgets/shimmer_widget.dart';
import 'package:ichan/widgets/tap_to_reload.dart';

import 'category_row.dart';

const headerHeight = 45.0;
const categoryHeight = 40.0;

class CategoryList extends StatelessWidget {
  const CategoryList({this.searchController, this.focusNode});
  final TextEditingController searchController;
  final FocusNode focusNode;
  static final slideableController = SlidableController();

  SliverPersistentHeader makeHeader(String headerText) {
    return SliverPersistentHeader(
      delegate: _SliverAppBarDelegate(
        minHeight: headerHeight,
        maxHeight: headerHeight,
        child: Container(
          color: my.theme.alphaBackground,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            headerText,
            style: TextStyle(
              color: my.theme.foregroundMenuColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget makeItems(List<Board> boards, BuildContext context) {
    final items = List<Widget>.from(
      boards.map<Widget>(
        (board) => CategoryRow(
          board: board,
          searchController: searchController,
          focusNode: focusNode,
        ),
      ),
    );

    return SeparatedSliverList(items: items);
  }

  Widget makeRemovableItems(List<Board> boards, BuildContext context) {
    final items = List<Widget>.from(
      boards.map<Widget>(
        (board) {
          return Slidable.builder(
            controller: slideableController,
            actionPane: const SlidableDrawerActionPane(),
            actionExtentRatio: 0.25,
            secondaryActionDelegate: SlideActionBuilderDelegate(
              actionCount: 1,
              builder: (context, i, slideAnimation, renderingMode) {
                return IconSlideAction(
                  color: renderingMode == SlidableRenderingMode.slide
                      ? Colors.red.withOpacity(slideAnimation.value)
                      : Colors.red,
                  iconWidget: Container(
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  onTap: () {
                    my.categoryBloc.unfavoriteBoard(board);
                  },
                );
              },
            ),
            child: CategoryRow(
              board: board,
              searchController: searchController,
              focusNode: focusNode,
            ),
          );
        },
      ),
    );

    return SeparatedSliverList(items: items);
  }

  SliverFixedExtentList makeFixedList(List<Widget> items) {
    return SliverFixedExtentList(
      itemExtent: categoryHeight,
      delegate: SliverChildListDelegate(items),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryError) {
          return TapToReload(message: state.message, onTap: () => my.categoryBloc.fetchBoards());
        }
        if (state is CategoryLoaded) {
          final List<Widget> data = [];
          data.add(
            makeFixedList(
              [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Consts.sidePadding / 2,
                    horizontal: Consts.sidePadding,
                  ),
                  child: SearchBar(
                    placeholder: 'Search',
                    onChanged: (val) {
                      my.categoryBloc.search(val);
                    },
                    onSubmitted: (val) async {
                      focusNode.unfocus();
                      FocusScope.of(context).unfocus();
                      Routz.of(context)
                          .toBoard(
                              Board(val.toLowerCase(), platform: my.categoryBloc.selectedPlatform),
                              previousPageTitle: "Categories")
                          .then((_) {
                        final data = {'page': 'categories'};
                        my.prefs.put('last_screen', data);
                      });

                      await Future.delayed(300.milliseconds);
                      searchController.clear();
                      my.categoryBloc.search('');
                    },
                    controller: searchController,
                    focusNode: focusNode,
                  ),
                ),
                if (my.prefs.getList('platforms').length > 1) ...[
                  PlatformSelector(controller: searchController),
                ]
              ],
            ),
          );

          if (state.favoriteBoards.isNotEmpty) {
            data.add(makeHeader('Favorites'));
            data.add(makeRemovableItems(state.favoriteBoards, context));
          }

          for (final category in state.categories) {
            final List<Board> _boards =
                state.boards.where((board) => board.category == category).toList();
            if (_boards.isNotEmpty) {
              data.add(makeHeader(category));
            }
            data.add(makeItems(_boards, context));
          }

          const footer = [
            SizedBox(height: categoryHeight),
            SizedBox(height: categoryHeight),
            SizedBox(height: categoryHeight),
          ];

          data.add(makeFixedList(footer));

          return CustomScrollView(slivers: data);
        }

        return const Center(
          child: ShimmerLoader(),
        );
      },
    );
  }
}

class PlatformSelector extends StatefulWidget {
  const PlatformSelector({Key key, this.controller}) : super(key: key);
  final TextEditingController controller;

  @override
  _PlatformSelectorState createState() => _PlatformSelectorState();
}

class _PlatformSelectorState extends State<PlatformSelector> {
  @override
  Widget build(BuildContext context) {
    return CupertinoSegmentedControl(
      groupValue: my.categoryBloc.selectedPlatform,
      selectedColor: my.theme.primaryColor,
      unselectedColor: my.theme.backgroundColor,
      onValueChanged: (val) async {
        my.categoryBloc.selectedPlatform = val;
        await my.categoryBloc.fetchBoards(val);
        if (widget.controller.text.isNotEmpty) {
          my.categoryBloc.search(widget.controller.text);
        }
        setState(() {});
      },
      children: const <Platform, Widget>{
        Platform.dvach: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            '2ch',
            style: TextStyle(fontSize: 15.0),
          ),
        ),
        Platform.fourchan: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            '4chan',
            style: TextStyle(fontSize: 15.0),
          ),
        ),
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    @required this.minHeight,
    @required this.maxHeight,
    @required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
