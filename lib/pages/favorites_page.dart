import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ichan/blocs/blocs.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/pages/thread/thread.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

import 'favorites/favorites.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key key}) : super(key: key);

  @override
  FavoritesPageState createState() => FavoritesPageState();
}

class FavoritesPageState extends State<FavoritesPage> with WidgetsBindingObserver {
  static final listenable = my.prefs.box.listenable(keys: ['favorites_as_blocks']);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    listenable.addListener(() {
      setState(() {});
    });
    my.favoriteBloc.reloadFavorites();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      my.favoriteBloc.refresh(auto: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    my.analytics.setCurrentScreen(screenName: 'favorites');

    final Widget refreshButton =
        BlocBuilder<FavoriteBloc, FavoriteState>(builder: (context, state) {
      final bool isRefreshing = state is FavoriteRefreshInProgress || state is FavoriteRefreshing;

      // print("state = ${state}");

      if (isRefreshing) {
        return LoopAnimation<double>(
            tween: 0.0.tweenTo(math.pi * 12),
            duration: 10.seconds,
            curve: Curves.linear,
            builder: (context, child, value) {
              return Transform.rotate(
                angle: value,
                child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: FaIcon(FlutterIcons.md_refresh_ion,
                        size: 24, color: my.theme.inactiveColor)),
              );
            });
      } else {
        return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () async {
              final actions = [
                const ActionSheet(
                  text: 'Clear deleted',
                  value: 'clear_deleted',
                ),
                ActionSheet(
                  text: 'Clear all',
                  value: 'clear_all',
                  color: my.theme.alertColor,
                )
              ];

              final result = await Interactive(context).modal(actions);
              if (result == "clear_deleted") {
                my.favoriteBloc.clearDeleted();
              } else if (result == "clear_all") {
                Interactive(context).modalDelete(text: 'Seriously?').then((confirmed) {
                  if (confirmed) {
                    my.favs.box.clear();
                    my.favoriteBloc.favoriteUpdated();
                  }
                });
              }
            },
            onTap: () {
              my.favoriteBloc.refresh();
            },
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: FaIcon(FlutterIcons.md_refresh_ion, size: 24, color: my.theme.navbarFontColor),
            ));
      }
    });

    return HeaderNavbar(
      backGesture: false,
      child: SafeArea(
        child: CupertinoScrollbar(
          child: my.prefs.getBool('favorites_as_blocks')
              ? const FavoritesGrid()
              : const FavoritesList(),
        ),
      ),
      middleText: "Favorites",
      trailing: refreshButton,
    );
  }

  Future<void> showMenu(BuildContext context, ThreadStorage fav) async {
    final sheet = [
      ActionSheet(
          text: "Delete",
          color: my.theme.alertColor,
          onPressed: () {
            my.favoriteBloc.favoriteDeleted(fav);
          }),
      ActionSheet(
          text: fav.refresh == false ? 'Turn on refresh' : 'Turn off refresh',
          onPressed: () {
            fav.refresh = !fav.refresh;
            fav.save();
            my.favoriteBloc.favoriteUpdated();
          }),
    ];

    return await Interactive(context).modal(sheet);
  }
}
