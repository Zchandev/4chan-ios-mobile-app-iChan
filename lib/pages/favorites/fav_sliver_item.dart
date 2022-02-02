import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/blocs/blocs.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/htmlz.dart';
import 'package:ichan/services/my.dart' as my;

class FavSliverItem extends StatefulWidget {
  const FavSliverItem({
    Key key,
    this.fav,
    this.header = '/',
    this.replaceRoute = false,
  }) : super(key: key);

  final ThreadStorage fav;
  final String header;
  final bool replaceRoute;

  @override
  _FavSliverItemState createState() => _FavSliverItemState();
}

class _FavSliverItemState extends State<FavSliverItem> {
  ThreadStorage get fav => widget.fav;

  Future<void> showMenu(ThreadStorage fav) async {
    final sheet = [
      ActionSheet(
        text: "Delete",
        color: my.theme.alertColor,
        onPressed: () {
          my.favoriteBloc.favoriteDeleted(fav);
        },
      ),
      if (fav.status != Status.deleted) ...[
        ActionSheet(
          text: fav.refresh == false ? 'Turn on refresh' : 'Turn off refresh',
          onPressed: () {
            fav.refresh = !fav.refresh;
            fav.save();
            my.favoriteBloc.favoriteUpdated();
          },
        )
      ],
      if (fav.status != Status.deleted && my.favs.hasEnoughThreads) ...[
        ActionSheet(
          text: "Increase visits count",
          onPressed: () {
            final maxVisitsFav = my.favs.box.values.maxBy((a, b) => a.visits.compareTo(b.visits));
            if (maxVisitsFav != null) {
              fav.visits = maxVisitsFav.visits + 1;
              fav.save();
            }
            my.favoriteBloc.favoriteUpdated();
          },
        ),
      ]
    ];

    return await Interactive(context).modal(sheet);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      buildWhen: (previousState, state) {
        if (state is FavoriteRefreshing) {
          return state.fav?.threadId == fav.threadId;
        }

        return false;
      },
      builder: (context, state) {
        final unreadCount = Container(
            child: Text(fav.unreadCount.toString(),
                style: TextStyle(
                    fontSize: fav.unreadCount == 0 ? 14 : 16, color: unreadCountColor())));

        final data = my.threadBloc.getThreadData(fav.id);
        final isCached = data != null && data.posts.isNotEmpty;

        final unreadIconMap = {
          Status.error:
              FaIcon(FontAwesomeIcons.exclamationTriangle, size: 12, color: my.theme.primaryColor),
          Status.deleted: FaIcon(FontAwesomeIcons.trashAlt, size: 12, color: my.theme.primaryColor),
          Status.closed: FaIcon(FontAwesomeIcons.lock, size: 12, color: my.theme.primaryColor),
          Status.refreshing: const Text("..."),
          Status.unread: unreadCount,
          Status.read: unreadCount,
          Status.disabled: Container(),
        };

        final caption = (fav.isOp || !widget.header.startsWith('/'))
            ? "/${fav.boardName}/ ${fav.threadTitle}"
            : fav.threadTitle;

        final favTitle = Text(
          Htmlz.unescape(caption),
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
              inherit: false,
              fontSize: my.prefs.postFontSize,
              color: getFavTitleColor(),
              decoration:
                  fav.status == Status.deleted ? TextDecoration.lineThrough : TextDecoration.none),
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () {
            return showMenu(fav);
          },
          onTap: () async {
            if (!isCached && fav.status == Status.deleted) {
              showMenu(fav);
            } else {
              await Routz.of(context).toThread(
                threadLink: ThreadLink.fromStorage(fav),
                replace: widget.replaceRoute,
              );

              final data = {'page': 'favorites'};
              my.prefs.put('last_screen', data);
            }
          },
          child: Container(
            color: my.theme.backgroundColor,
            height: 40,
            padding: const EdgeInsets.only(
              left: Consts.sidePadding,
              right: Consts.sidePadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: favTitle),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    if (fav.status == Status.deleted) {
                      my.favoriteBloc.favoriteDeleted(fav);
                      // fav.delete();

                      // my.favoriteBloc.favoriteUpdated();
                    } else {
                      await Routz.of(context).toThread(
                        threadLink: ThreadLink.fromStorage(fav),
                        replace: widget.replaceRoute,
                      );

                      final data = {'page': 'favorites'};
                      my.prefs.put('last_screen', data);
                    }
                  },
                  child: unreadIcon(unreadIconMap),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget unreadIcon(Map<Status, StatelessWidget> unreadIconMap) {
    if (fav.refresh == false) {
      return Container(
        padding: const EdgeInsets.only(left: 15.0),
        child: const Text("off"),
      );
    } else {
      return Container(
        padding: const EdgeInsets.only(left: 15.0),
        child: unreadIconMap[fav.status],
      );
    }
  }

  Color unreadCountColor() {
    if (fav.unreadCount == 0) {
      return my.theme.fontColor;
    } else if (fav.hasReplies) {
      return CupertinoColors.activeGreen;
    } else {
      return my.theme.primaryColor;
    }
  }

  Color getFavTitleColor() {
    final isRead = fav.unreadCount == 0;
    final isRefreshing = fav.refresh == false;
    final isNotActive = fav.status == Status.deleted || fav.status == Status.closed;

    if (isRead || isRefreshing || isNotActive) {
      return my.theme.foregroundMenuColor;
    } else {
      return my.theme.primaryColor;
    }
  }
}
