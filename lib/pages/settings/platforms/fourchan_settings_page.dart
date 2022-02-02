import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:ichan/pages/settings/platforms_links_page.dart';
import 'package:ichan/repositories/4chan/fourchan_api.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;

class FourchanSettingsPage extends HookWidget {
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
      middleText: '4chan',
      child: Container(
        height: context.screenHeight,
        child: ListView(
          children: [
            menuDivider,
            MenuSwitch(
              label: 'Enabled',
              field: 'fourchan_enabled',
              defaultValue: false,
              onChanged: (val) {
                final List<Platform> platforms = my.prefs.platforms;

                if (val == true) {
                  const actions = [ActionSheet(text: "Use as default platform", value: "default")];
                  Interactive(context).modal(actions).then((val) {
                    if (val == 'default') {
                      platforms.insert(0, Platform.fourchan);
                    } else {
                      platforms.add(Platform.fourchan);
                    }
                    my.prefs.put('platforms', platforms.toSet().toList());
                    my.categoryBloc.setPlatform();
                  });
                } else {
                  platforms.remove(Platform.fourchan);
                  my.prefs.put('platforms', platforms.toList());
                }
                my.categoryBloc.setPlatform();
                my.prefs.put("fourchan_enabled", val);
              },
            ),
            MenuTextField(
              label: 'Domain',
              boxField: 'fourchan_domain',
              onSubmitted: (val) {
                if (val.isEmpty) {
                  my.prefs.put('fourchan_domain', FourchanApi.defaultDomain);
                  my.fourchanApi.domain = setDomain(FourchanApi.defaultDomain);
                } else {
                  my.prefs.put('fourchan_domain', val);
                  my.fourchanApi.domain = setDomain(val);
                  my.prefs.delete('json_cache');
                }
                my.categoryBloc.fetchBoards(Platform.fourchan);
              },
            ),
            menuDivider,
            if (!my.prefs.isSafe) ...[
              MenuSwitch(
                label: 'NSFW boards',
                field: 'fourchan_nsfw',
                defaultValue: false,
                onChanged: (val) async {
                  if (val == true) {
                    final actions = [
                      ActionSheet(text: "yes".tr(), value: "yes"),
                      ActionSheet(text: "no".tr(), value: "no")
                    ];

                    final result = await Interactive(context)
                        .alert(actions, content: "modals.age_confirm".tr());

                    if (result == "yes") {
                      my.prefs.put('fourchan_nsfw', true);
                    }
                  } else {
                    my.prefs.put('fourchan_nsfw', false);
                  }

                  if (my.categoryBloc.selectedPlatform == Platform.fourchan) {
                    my.categoryBloc.fetchBoards(Platform.fourchan);
                  }

                  return false;
                },
              ),
            ],
            const MenuSwitch(
              label: 'Proxy enabled',
              field: 'fourchan_proxy_enabled',
              defaultValue: false,
            ),
            ValueListenableBuilder(
              valueListenable: my.prefs.box.listenable(keys: ['fourchan_proxy_enabled']),
              builder: (BuildContext context, dynamic value, Widget child) {
                if (my.prefs.getBool('fourchan_proxy_enabled')) {
                  return Column(
                    children: const [
                      MenuTextField(
                        label: 'Address:port',
                        boxField: 'fourchan_proxy',
                      ),
                      MenuTextField(
                        label: 'Boards',
                        boxField: 'fourchan_proxy_boards',
                      ),
                    ],
                  );
                }
                return Container();
              },
            ),
            // MenuSwitch(
            //   label: 'Passcode enabled',
            //   field: 'fourchan_passcode_enabled',
            //   defaultValue: false,
            //   onChanged: (v) {
            //     my.prefs.put('fourchan_passcode_enabled', v);
            //     my.contextTools.init(context);
            //     return false;
            //   },
            // ),
            // ValueListenableBuilder(
            //   valueListenable: my.prefs.box.listenable(keys: ['fourchan_passcode_enabled']),
            //   builder: (BuildContext context, dynamic value, Widget child) {
            //     if (my.prefs.getBool('fourchan_passcode_enabled')) {
            //       return MenuTextField(
            //         label: 'Code',
            //         boxField: 'fourchan_passcode',
            //         enabled: my.prefs.getBool('fourchan_passcode_enabled'),
            //       );
            //     } else {
            //       return Container();
            //     }
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
