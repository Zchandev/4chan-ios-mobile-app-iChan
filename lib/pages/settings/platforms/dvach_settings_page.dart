import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ichan/pages/settings/platforms_links_page.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;

class DvachSettingsPage extends StatelessWidget {
  final passcodeCtrl = TextEditingController();
  final domainCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  String setDomain(String domain) {
    final result = domain
        .replaceAll('www.', '')
        .replaceAll('http://', '')
        .replaceAll('https://', '')
        .replaceAll('/', '');

    return "https://$result";
  }

  @override
  Widget build(BuildContext context) {
    return HeaderNavbar(
      backgroundColor: my.theme.secondaryBackgroundColor,
      previousPageTitle: PlatformsLinksPage.header,
      middleText: '2ch',
      child: Container(
        height: context.screenHeight,
        child: ListView(
          children: [
            menuDivider,
            MenuSwitch(
              label: 'Enabled',
              field: 'dvach_enabled',
              defaultValue: false,
              onChanged: (val) {
                final List<Platform> platforms = my.prefs.platforms;

                if (val == true) {
                  const actions = [ActionSheet(text: "Use as default platform", value: "default")];
                  Interactive(context).modal(actions).then((val) {
                    if (val == 'default') {
                      platforms.insert(0, Platform.dvach);
                    } else {
                      platforms.add(Platform.dvach);
                    }
                    my.prefs.put('platforms', platforms.toSet().toList());
                    my.categoryBloc.setPlatform();
                  });
                } else {
                  platforms.remove(Platform.dvach);
                  my.prefs.put('platforms', platforms);
                }
                my.prefs.put("dvach_enabled", val);
                my.categoryBloc.setPlatform();
              },
            ),
            MenuTextField(
              label: 'Domain',
              boxField: 'domain',
              onSubmitted: (val) {
                if (val.isEmpty) {
                  my.prefs.put('domain', Consts.domain2ch);
                  my.makabaApi.domain = setDomain(Consts.domain2ch);
                } else {
                  my.prefs.put('domain', val);
                  my.makabaApi.domain = setDomain(val);
                  my.prefs.delete('json_cache');
                }
                my.categoryBloc.fetchBoards(Platform.dvach);
              },
            ),
            menuDivider,
            MenuSwitch(
              label: 'NSFW boards',
              field: 'dvach_nsfw',
              defaultValue: false,
              onChanged: (val) {
                _confirmAge(context, 'dvach_nsfw', val);
              },
            ),
            MenuSwitch(
              label: 'Users boards',
              field: 'dvach_userboards',
              defaultValue: false,
              onChanged: (val) {
                _confirmAge(context, 'dvach_userboards', val);
              },
            ),
            MenuSwitch(
              label: 'Passcode',
              field: 'passcode_enabled',
              defaultValue: false,
              onChanged: (v) {
                if (v == true) {
                  my.prefs.put('bypass_captcha', false);
                }
                my.prefs.put('passcode_enabled', v);
                my.contextTools.init(context);
              },
            ),
            ValueListenableBuilder(
              valueListenable: my.prefs.box.listenable(keys: ['passcode_enabled', 'passcode']),
              builder: (BuildContext context, dynamic value, Widget child) {
                if (my.prefs.getBool('passcode_enabled')) {
                  return const MenuTextField(
                    label: 'Code',
                    boxField: 'passcode',
                  );
                }
                return Container();
              },
            ),
            menuDivider,
            const MenuSwitch(
              label: 'Proxy enabled',
              field: 'dvach_proxy_enabled',
              defaultValue: false,
            ),
            ValueListenableBuilder(
              valueListenable: my.prefs.box.listenable(keys: ['dvach_proxy_enabled']),
              builder: (BuildContext context, dynamic value, Widget child) {
                if (my.prefs.getBool('dvach_proxy_enabled')) {
                  return Column(
                    children: const [
                      MenuTextField(
                        label: 'Address:port',
                        boxField: 'dvach_proxy',
                      ),
                      MenuTextField(
                        label: 'Boards',
                        boxField: 'dvach_proxy_boards',
                      ),
                    ],
                  );
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future _confirmAge(BuildContext context, String field, bool val) async {
    if (val == true) {
      final actions = [
        ActionSheet(text: "yes".tr(), value: "yes"),
        ActionSheet(text: "no".tr(), value: "no")
      ];

      final result = await Interactive(context).alert(actions, content: "modals.age_confirm".tr());
      if (result == "yes") {
        my.prefs.put(field, true);
      }
    } else {
      my.prefs.put(field, false);
    }

    if (my.categoryBloc.selectedPlatform == Platform.dvach) {
      my.categoryBloc.fetchBoards(Platform.dvach);
    }
  }
}
