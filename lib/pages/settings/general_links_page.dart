import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/pages/settings/general/gestures_settings_page.dart';
import 'package:ichan/pages/settings/general/system_settings_page.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;

import 'general/appearance_settings_page.dart';
import 'general/font_settings_page.dart';
import 'general/theme_settings_page.dart';

class GeneralSettingsPage extends StatelessWidget {
  static const header = 'General';

  @override
  Widget build(BuildContext context) {
    final menus = [
      MenuItem(name: "Appearance", page: AppearanceSettingsPage(), isFirst: true),
      MenuItem(name: "Gestures", page: GesturesSettingsPage()),
      MenuItem(name: "System", page: SystemSettingsPage()),
      MenuItem(name: "Theme", page: ThemeSettingsPage()),
      MenuItem(name: "Font", page: FontSettingsPage(), isLast: true),
    ];

    return HeaderNavbar(
      backgroundColor: my.theme.secondaryBackgroundColor,
      middle: Text(header, style: TextStyle(color: my.theme.navbarFontColor)),
      previousPageTitle: "Settings",
      child: Container(
        margin: const EdgeInsets.only(top: Consts.topPadding),
        child: ListView.separated(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
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
        ),
      ),
    );
  }
}
