import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/pages/board/threads_list.dart';
import 'package:ichan/pages/thread/thread.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

class BoardPage extends StatelessWidget {
  BoardPage({
    Key key,
    this.board,
    this.query = '',
    this.previousPageTitle,
  }) : super(key: key);

  static const routeName = '/board';

  final Board board;
  final String query;
  final String previousPageTitle;
  final scrollNotifier = ValueNotifier<bool>(false);

  Widget build(BuildContext context) {
    if (my.prefs.getBool('disable_autoturn')) {
      System.setAutoturn('portrait');
    }

    final data = {
      'page': 'board',
      'board': board,
    };
    my.prefs.put('last_screen', data);

    return HeaderNavbar(
      transparent: true,
      previousPageTitle: previousPageTitle,
      child: ThreadsList(
        board: board,
        query: query,
        scrollNotifier: scrollNotifier,
      ),
      onStatusBarTap: () {
        scrollNotifier.value = !scrollNotifier.value;
      },
      middle: GestureDetector(
        onTap: () {
          scrollNotifier.value = !scrollNotifier.value;
        },
        child: Text(
          "/${board.id}/",
          style: TextStyle(color: my.theme.navbarFontColor),
        ),
      ),
      trailing: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Routz.of(context).toPage(NewPostPage(board: board), title: "/${board.id}/");
        },
        child: Icon(CupertinoIcons.add, color: my.theme.navbarFontColor, size: 24),
      ),
    );
  }
}
