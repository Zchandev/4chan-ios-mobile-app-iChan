import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ichan/models/thread.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/pages/activity_page.dart';
import 'package:ichan/services/exports.dart';

import 'package:ichan/pages/favorites_page.dart';
import 'package:ichan/pages/settings_page.dart';
import 'package:ichan/pages/categories_page.dart';
import 'package:ichan/services/my.dart' as my;

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  CupertinoTabController controller;
  bool needUpdate = false;
  bool activityDisabled = false;
  List<Widget> tabs;

  void tabChange(index) {
    my.themeManager.syncTheme();

    if (index == 0) {
      final data = {'page': 'categories'};
      my.prefs.put('last_screen', data);
    } else if (index == 1) {
      my.favoriteBloc.favoriteUpdated();
      my.favoriteBloc.refresh(auto: true);

      final data = {'page': 'favorites'};
      my.prefs.put('last_screen', data);
    }
  }

  void initState() {
    controller = CupertinoTabController();

    my.categoryBloc.setPlatform();

    setTabs();

    if (my.prefs.getBool('remember_screen')) {
      openLastScreen();
    }
    controller.addListener(() => tabChange(controller.index));

    super.initState();
  }

  void setTabs() {
    tabs = [
      const CategoriesPage(),
      const FavoritesPage(),
      if (!activityDisabled) ...[
        ActivityPage(),
      ],
      SettingsPage(),
    ];
  }

  void openLastScreen() {
    final lastScreen = my.prefs.get('last_screen', defaultValue: {}).cast<String, dynamic>();

    if (lastScreen != null && lastScreen.isNotEmpty) {
      controller = CupertinoTabController(initialIndex: 1);
      if (lastScreen['page'] == 'categories') {
        controller = CupertinoTabController(initialIndex: 0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (lastScreen['page'] == 'board') {
          Routz.of(context).toBoard(lastScreen['board']);
        } else if (lastScreen['page'] == 'thread') {
          try {
            final ts = ThreadStorage.findById(lastScreen['key']);
            final thread = Thread.fromThreadStorage(ts);
            await my.repo.on(thread.platform).fetchThreadPosts(thread: thread);
            Routz.of(context).toThread(threadLink: ThreadLink.fromStorage(ts));
          } catch (e) {
            print("openLastScreen: thread not loaded: $e");
          }
        }

        my.favoriteBloc.refresh(auto: true);
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    my.contextTools.init(context);

    final backgroundColor = my.theme.bottomBarBackground.withOpacity(Consts.navbarOpacity);

    return ValueListenableBuilder(
      valueListenable: my.prefs.box.listenable(keys: ['activity_disabled']),
      builder: (context, val, widget) {
        activityDisabled = my.prefs.getBool('activity_disabled');

        if (activityDisabled && controller.index == 3) {
          controller.index = 2;
        }

        setTabs();

        return CupertinoTabScaffold(
          controller: controller,
          tabBar: CupertinoTabBar(
            backgroundColor: backgroundColor,
            border: Border(top: BorderSide(color: my.theme.navBorderColor)),
            items: [
              const BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.list, size: Consts.bottomBarIconSize),
              ),
              const BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.star, size: Consts.bottomBarIconSize)),
              if (!activityDisabled) ...[
                BottomNavigationBarItem(
                  icon: ValueListenableBuilder(
                      valueListenable: my.posts.box.listenable(),
                      builder: (context, val, widget) {
                        final hasUnreads = my.posts.replies.where((e) => e.isUnread).isNotEmpty;

                        return Stack(
                          alignment: AlignmentDirectional.topEnd,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(7),
                              child: FaIcon(
                                FontAwesomeIcons.commentAlt,
                                size: Consts.bottomBarIconSize,
                              ),
                            ),
                            if (hasUnreads) ...[
                              const FaIcon(
                                FontAwesomeIcons.solidCircle,
                                size: 7,
                                color: CupertinoColors.destructiveRed,
                              )
                            ],
                          ],
                        );
                      }),
                )
                // const BottomNavigationBarItem(
                //     icon: FaIcon(FontAwesomeIcons.commentAlt, size: Consts.bottomBarIconSize))
              ],
              BottomNavigationBarItem(
                icon: Stack(
                  alignment: AlignmentDirectional.topEnd,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(5),
                      child: FaIcon(
                        FontAwesomeIcons.cog,
                        size: Consts.bottomBarIconSize,
                      ),
                    ),
                    if (needUpdate) ...[
                      const FaIcon(
                        FontAwesomeIcons.solidCircle,
                        size: 7,
                        color: CupertinoColors.destructiveRed,
                      )
                    ],
                  ],
                ),
              )
            ],
          ),
          tabBuilder: (context, index) {
            return tabs[index];
          },
        );
      },
    );
  }
}
