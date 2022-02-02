import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;

class UserSettingsPage extends StatelessWidget {
  final TextEditingController albumController = TextEditingController();

  static const header = 'Stats';

  Widget build(BuildContext context) {
    return HeaderNavbar(
      backgroundColor: my.theme.secondaryBackgroundColor,
      middleText: header,
      previousPageTitle: "Settings",
      child: ValueListenableBuilder(
          valueListenable: my.prefs.box.listenable(keys: ['stats']),
          builder: (context, val, widget) {
            final boxField = my.favs.values.isEmpty ? '' : null;

            return ListView(
              padding: const EdgeInsets.only(top: Consts.topPadding * 3),
              children: [
                MenuTextField(
                  label: "Threads visited",
                  boxField: boxField,
                  value: my.prefs.stats['threads_visited'].toString(),
                  keyboardType: TextInputType.number,
                  onSubmitted: (val) => _setValue('threads_visited', val),
                ),
                MenuTextField(
                  label: "Total threads clicked",
                  boxField: boxField,
                  value: my.prefs.stats['threads_clicked'].toString(),
                  keyboardType: TextInputType.number,
                  onSubmitted: (val) => _setValue('threads_clicked', val),
                ),
                MenuTextField(
                  label: "Threads created",
                  boxField: boxField,
                  value: my.prefs.stats['threads_created'].toString(),
                  keyboardType: TextInputType.number,
                  onSubmitted: (val) => _setValue('threads_created', val),
                ),
                MenuTextField(
                  label: "Posts created",
                  boxField: boxField,
                  value: my.prefs.stats['posts_created'].toString(),
                  keyboardType: TextInputType.number,
                  onSubmitted: (val) => _setValue('posts_created', val),
                ),
                MenuTextField(
                  label: "Replies received",
                  value: my.prefs.stats['replies_received'].toString(),
                ),
                MenuTextField(
                  label: "Media views",
                  value: my.prefs.stats['media_views'].toString(),
                ),
                MenuTextField(
                  label: "Favorites refreshed",
                  value: my.prefs.stats['favs_refreshed'].toString(),
                ),
                MenuTextField(
                  label: "Total hours",
                  value: (my.prefs.stats['visits'] * 3 ~/ 60).toString(),
                ),
              ],
            );
          }),
    );
  }

  void _setValue(String field, String val) {
    try {
      final intVal = int.parse(val);
      my.prefs.setStats(field, intVal);
    } catch (e) {
      my.prefs.setStats(field, my.prefs.stats[field]);
    }
  }
}
