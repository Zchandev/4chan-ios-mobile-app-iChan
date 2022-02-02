import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/models/board.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

class CategoryRow extends StatelessWidget {
  const CategoryRow({
    Key key,
    this.board,
    this.searchController,
    this.focusNode,
  }) : super(key: key);

  final Board board;
  final TextEditingController searchController;
  final FocusNode focusNode;

  void openBoard(BuildContext context, Board board) async {
    focusNode.unfocus();
    FocusScope.of(context).unfocus();
    Routz.of(context).toBoard(board, previousPageTitle: 'Boards').then((value) {
      final data = {'page': 'categories'};
      my.prefs.put('last_screen', data);
    });
    if (searchController.text.isNotEmpty) {
      await Future.delayed(300.milliseconds);
      searchController.clear();
      my.categoryBloc.search('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      width: double.infinity,
      child: GestureDetector(
        key: UniqueKey(),
        behavior: HitTestBehavior.translucent,
        onLongPress: () {
          final favorites = my.categoryBloc.platformFavorites();

          if (favorites.any((e) => e.equalsTo(board))) {
            Interactive(context).modalDelete(text: "Unfavorite").then((confirmed) {
              if (confirmed) {
                my.categoryBloc.unfavoriteBoard(board);
              }
            });
          } else {
            Interactive(context).modalList(['Add to favorites']).then((confirmed) {
              if (confirmed == "add to favorites") {
                my.categoryBloc.favoriteBoard(board: board);
              }
            });
          }
        },
        onTap: () {
          openBoard(context, board);
        },
        child: Padding(
          key: UniqueKey(),
          padding: const EdgeInsets.only(left: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(board.id,
                        style: TextStyle(
                          color: my.theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        )),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            board.name,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              color: my.theme.foregroundMenuColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: Consts.sidePadding),
                child: FaIcon(FontAwesomeIcons.chevronRight, size: 18),
              )
            ],
          ),
        ),
      ),
    );
  }
}
