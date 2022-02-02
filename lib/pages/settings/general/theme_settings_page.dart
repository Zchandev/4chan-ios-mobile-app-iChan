import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/pages/settings/general_links_page.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;

class ThemeSettingsPage extends StatelessWidget {
  static const header = 'Theme';

  @override
  Widget build(BuildContext context) {
    return HeaderNavbar(
        backgroundColor: my.theme.secondaryBackgroundColor,
        middleText: header,
        previousPageTitle: GeneralSettingsPage.header,
        child: ListView(
          padding: const EdgeInsets.only(top: Consts.topPadding * 3),
          children: [
            MenuSwitch(
              label: "Sync with system",
              field: 'sync_theme',
              defaultValue: false,
              onChanged: (val) {
                my.prefs.put('sync_theme', val);
                if (val == true) {
                  my.themeManager.syncTheme();
                }
                return false;
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, bottom: 5.0),
              child: Text("Theme", style: TextStyle(color: my.theme.inactiveColor)),
            ),
            Container(
              height: 45.0 * 5,
              child: MenuSelect(
                labels: const [
                  "Dark Orange",
                  "Dark Green",
                  "Dark Blue",
                  "Light Orange",
                  "Light Black",
                ],
                values: const [
                  "dark",
                  "dark_green",
                  "dark_blue",
                  "orange_white",
                  "black_white",
                ],
                field: "theme",
                defaultValue: "dark",
                onChanged: (val) {
                  my.prefs.put('theme', val);
                  my.themeManager.updateTheme();
                  return false;
                },
              ),
            ),
          ],
        ));
  }
}
