import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/pages/settings/general_links_page.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;

class GesturesSettingsPage extends StatelessWidget {
  static const header = 'Gestures';

  @override
  Widget build(BuildContext context) {
    return HeaderNavbar(
      backgroundColor: my.theme.secondaryBackgroundColor,
      previousPageTitle: GeneralSettingsPage.header,
      middleText: header,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0, bottom: 5.0, top: 20.0),
            child: Text("Media gestures", style: TextStyle(color: my.theme.inactiveColor)),
          ),
          MenuSwitch(
            label: "Disable media swipe up/down",
            field: "disable_media_swipe",
            defaultValue: false,
            onChanged: (val) {
              if (val == true) {
                my.prefs.put('swipe_down_skips_gallery', false);
              }
              my.prefs.put('disable_media_swipe', val);
            },
          ),
          // const MenuSwitch(
          //   label: 'Swipe down skips gallery',
          //   field: 'swipe_down_skips_gallery',
          //   defaultValue: false,
          // ),
          const MenuSwitch(
            label: 'Swipe up opens gallery',
            field: 'swipe_up_opens_gallery',
            defaultValue: false,
          ),
          const MenuSwitch(
            label: 'Swipe from bottom for info',
            field: 'swipe_bottom_for_info',
            defaultValue: false,
            isLast: true,
          ),
          const MenuSwitch(
            label: 'Scroll to post after close',
            field: 'scroll_to_post',
            defaultValue: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}
