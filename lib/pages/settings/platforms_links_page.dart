import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/pages/settings/platforms/platforms.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;

class PlatformsLinksPage extends StatelessWidget {
  static const header = 'Platforms';

  @override
  Widget build(BuildContext context) {
    final menus = [
      MenuItem(name: "Zchan", page: ZchanSettingsPage(), isFirst: true),
      MenuItem(name: "4chan", page: FourchanSettingsPage()),
      MenuItem(name: "2ch", page: DvachSettingsPage(), isLast: true),
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
