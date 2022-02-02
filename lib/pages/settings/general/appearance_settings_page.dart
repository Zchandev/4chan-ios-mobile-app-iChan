import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/pages/settings/general_links_page.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;

class AppearanceSettingsPage extends StatelessWidget {
  static const header = 'Appearance';

  @override
  Widget build(BuildContext context) {
    return HeaderNavbar(
      backgroundColor: my.theme.secondaryBackgroundColor,
      previousPageTitle: GeneralSettingsPage.header,
      middleText: header,
      trailing: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Interactive(context).message(content: "Tap on text to get help");
        },
        child: Text(
          "Help",
          style: TextStyle(color: my.theme.primaryColor),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Consts.topPadding * 3),
        children: [
          MenuSwitch(
            label: "Favorites as blocks",
            field: "favorites_as_blocks",
            hint: "menus.hints.favorites_as_blocks".tr(),
            defaultValue: false,
            isFirst: true,
          ),
          MenuSwitch(
            label: 'Disable thread mode switcher',
            field: 'thread_mode_disabled',
            hint: "menus.hints.thread_mode_disabled".tr(),
            defaultValue: false,
          ),
          MenuSwitch(
            label: 'Disable activity',
            field: 'activity_disabled',
            hint: "menus.hints.activity_disabled".tr(),
            defaultValue: false,
          ),
          MenuSwitch(
            label: 'Disable history',
            field: 'history_disabled',
            hint: 'menus.hints.history_disabled'.tr(),
            defaultValue: false,
          ),
          menuDivider,
          MenuSwitch(
            label: "Replies on top",
            field: "replies_on_top",
            hint: "menus.hints.replies_on_top".tr(),
            defaultValue: false,
          ),
          MenuSwitch(
            label: "Disable autoturn in threads",
            field: "disable_autoturn",
            hint: "menus.hints.disable_autoturn".tr(),
            defaultValue: false,
          ),
          MenuSwitch(
            label: "Show absolute time",
            field: "absolute_time",
            hint: "menus.hints.absolute_time".tr(),
            defaultValue: false,
          ),
          MenuSwitch(
            label: "Show post's time after id",
            field: "time_at_right",
            hint: "menus.hints.time_at_right".tr(),
            defaultValue: false,
          ),
          MenuSwitch(
            label: "Show media extension",
            field: "show_extension",
            hint: 'menus.hints.show_extension'.tr(),
            defaultValue: false,
          ),
          MenuSwitch(
            label: "Do not mark my posts",
            field: "hide_my_posts",
            hint: "menus.hints.hide_my_posts".tr(),
            defaultValue: false,
          ),
          MenuSwitch(
            label: 'Do not fav on reply',
            field: 'fav_on_reply_disabled',
            hint: 'menus.hints.fav_on_reply_disabled'.tr(),
            defaultValue: false,
          ),
          MenuSwitch(
            label: 'Do not close replies on reply',
            field: 'back_to_thread_disabled',
            hint: 'menus.hints.back_to_thread_disabled'.tr(),
            defaultValue: false,
          ),
          if (Consts.isIpad) ...[
            MenuSwitch(
              label: "Menu on the right",
              field: "right_menu",
              hint: "menus.hints.right_menu".tr(),
              defaultValue: false,
            ),
            MenuSwitch(
              label: "Menu on the bottom",
              field: "bottom_menu",
              hint: "menus.hints.bottom_menu".tr(),
              defaultValue: false,
              isLast: true,
            )
          ],
        ],
      ),
    );
  }
}
