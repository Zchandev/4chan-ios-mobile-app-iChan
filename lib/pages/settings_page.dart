import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ichan/pages/settings/settings.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HeaderNavbar(
      backgroundColor: my.theme.secondaryBackgroundColor,
      backGesture: false,
      transparent: false,
      middleText: "Settings",
      child: ValueListenableBuilder(
        valueListenable: my.prefs.box.listenable(keys: ['tester']),
        builder: (BuildContext context, dynamic value, Widget child) {
          final menus = [
            MenuItem(name: "General", page: GeneralSettingsPage(), isFirst: true),
            MenuItem(name: "Platforms", page: PlatformsLinksPage()),
            MenuItem(name: "Uploads", page: UploadsSettingsPage()),
            MenuItem(name: "Media", page: MediaSettingsPage()),
            if (my.prefs.isTester) ...[MenuItem(name: "Testing", page: TestingSettingsPage())],
            MenuItem(name: "Stats", page: UserSettingsPage()),
            const MenuItem(name: "About", page: AboutSettingsPage(), isLast: true),
          ];

          return ListView.separated(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
            shrinkWrap: true,
            itemCount: menus.length,
            itemBuilder: (context, index) {
              return menus[index];
            },
            separatorBuilder: (context, index) {
              return Divider(
                color: my.theme.lightDividerColor,
                height: 1,
                thickness: 1,
              );
            },
          );
        },
      ),
    );
  }
}
