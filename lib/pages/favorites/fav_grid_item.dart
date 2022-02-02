import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/blocs/blocs.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

class FavGridItem extends StatelessWidget {
  const FavGridItem({Key key, this.fav}) : super(key: key);

  final ThreadStorage fav;

  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      buildWhen: (previousState, state) {
        if (state is FavoriteRefreshing) {
          return state.fav?.threadId == fav.threadId;
        }
        return false;
      },
      builder: (context, state) {
        // TODO: REFACTOR
        // print("Thread is ${favItem.threadId}, state is $state");

        final unreadCount = Container(
            child: Text(fav.unreadCount.toString(),
                style: TextStyle(
                    fontSize: fav.unreadCount == 0 ? 13 : 18,
                    color: fav.unreadCount == 0 ? my.theme.fontColor : my.theme.primaryColor)));

        final unreadIconMap = {
          Status.error:
              FaIcon(FontAwesomeIcons.exclamationTriangle, size: 12, color: my.theme.primaryColor),
          Status.deleted: FaIcon(FontAwesomeIcons.trashAlt, size: 12, color: my.theme.primaryColor),
          Status.refreshing: const Text("..."),
          Status.unread: unreadCount,
          Status.read: const Text("0"),
          Status.disabled: Container(),
        };

        final unreadIcon =
            fav.refresh == false ? Container() : Container(child: unreadIconMap[fav.status]);

        final maxLength = my.contextTools.isVerySmallHeight ? 17 : 30;

        final favTitle = fav.shortTitle.takeFirst(maxLength, dots: "...");

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            Routz.of(context).toThread(
              threadLink: ThreadLink.fromStorage(fav),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Text(favTitle,
                    style: TextStyle(
                      inherit: false,
                      fontSize: 15.0,
                      color: my.theme.fontColor,
                    )),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Text(
                      "/${fav.boardName}/",
                      style: TextStyle(
                          inherit: false,
                          fontSize: 15.0,
                          color: fav.unreadCount == 0 ? my.theme.fontColor : my.theme.primaryColor),
                    ),
                  ),
                  if (fav.refresh != false) ...[unreadIcon]
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
