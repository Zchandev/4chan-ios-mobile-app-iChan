import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HeaderNavbar(
      middleText: "History",
      backGesture: false,
      child: ValueListenableBuilder(
        valueListenable: my.favs.box.listenable(),
        builder: (context, val, snapshot) {
          final visitedAt = my.prefs.getInt('visited_cleared_at');
          if (visitedAt == 0) {
            my.prefs.put('visited_cleared_at', DateTime.now().millisecondsSinceEpoch);
          }

          final items = my.favs.box.values
              .where((e) => e.visitedAt > visitedAt)
              .sortedByNum((e) => e.visitedAt * -1)
              .toList();

          if (items.isEmpty) {
            return Center(
                child: FaIcon(FontAwesomeIcons.ghost, size: 60, color: my.theme.inactiveColor));
          } else {
            return CupertinoScrollbar(
              child: ListView.separated(
                itemCount: items.length,
                padding: Consts.horizontalPadding,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: my.theme.dividerColor,
                  thickness: 1,
                ),
                itemBuilder: (context, index) {
                  return SafeArea(
                      top: index == 0,
                      bottom: index == items.length - 1,
                      left: false,
                      right: false,
                      child: SizedBox(
                        height: 55,
                        child: HistoryRow(item: items[index]),
                      ));
                },
              ),
            );
          }
        },
      ),
      trailing: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Interactive(context).modalDelete().then((confirmed) {
              if (confirmed) {
                my.favoriteBloc.clearVisited();
              }
            });
          },
          child: Text("Clean", style: TextStyle(color: my.theme.navbarFontColor))),
    );
  }
}

class HistoryRow extends StatelessWidget {
  const HistoryRow({Key key, this.item, this.myPosts = false}) : super(key: key);

  final ThreadStorage item;
  final bool myPosts;

  static final slideableController = SlidableController();

  static const platformNames = {
    Platform.dvach: "2ch",
    Platform.fourchan: "4chan",
    Platform.zchan: "Zchan",
  };

  @override
  Widget build(BuildContext context) {
    final platforms = my.prefs.platforms;

    final platformName = platformNames[item.platform];
    final text = platforms.length == 1 ? item.boardName : '$platformName: /${item.boardName}/';

    if (item.savedJson == null) {
      item.savedJson = '';
      item.save();
    }
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
              my.favoriteBloc.clearVisited(item);
            },
          );
        },
      ),
      child: GestureDetector(
        key: UniqueKey(),
        behavior: HitTestBehavior.translucent,
        onLongPress: () {
          Interactive(context).modalDelete().then((confirmed) {
            if (confirmed) {
              my.favoriteBloc.clearVisited(item);
            }
          });
        },
        onTap: () {
          Routz.of(context).toThread(
            threadLink: ThreadLink.fromStorage(item),
            previousPageTitle: "History",
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          color: my.theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.isFavorite) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0),
                          child: FaIcon(FontAwesomeIcons.solidStar, size: 12),
                        )
                      ],
                      if (item.savedJson.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0),
                          child: FaIcon(FontAwesomeIcons.save, size: 12),
                        )
                      ],
                      if (item.ownPostsCount > 0) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0),
                          child: FaIcon(FontAwesomeIcons.pen, size: 12),
                        )
                      ],
                    ],
                  ),
                  Flexible(
                    child: Text(
                      item.threadTitle,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        color: my.theme.foregroundMenuColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: Consts.sidePadding * 1.5, right: Consts.sidePadding),
              child: FaIcon(FontAwesomeIcons.chevronRight, size: 18),
            )
          ],
        ),
      ),
    );
  }
}
