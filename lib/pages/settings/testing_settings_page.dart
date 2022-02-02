import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ichan/blocs/thread/event.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/menu/menu.dart';

class TestingSettingsPage extends StatefulWidget {
  static const header = 'Testing';

  @override
  _TestingSettingsPageState createState() => _TestingSettingsPageState();
}

class _TestingSettingsPageState extends State<TestingSettingsPage> {
  bool showLog = false;

  @override
  Widget build(BuildContext context) {
    final cleanButton = CupertinoButton(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 16.0, bottom: 16.0),
        color: my.theme.primaryColor,
        onPressed: () {
          setState(() {
            Log.clean();
          });
        },
        child: const Text("Clean"));

    final testButton = CupertinoButton(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 16.0, bottom: 16.0),
        color: my.theme.primaryColor,
        onPressed: () {
          setState(() {});
        },
        child: const Text("Test"));

    // final passcode = my.prefs.getString("passcode");

    return HeaderNavbar(
        backgroundColor: my.theme.secondaryBackgroundColor,
        middleText: TestingSettingsPage.header,
        previousPageTitle: "Settings",
        child: ListView(
          padding: const EdgeInsets.only(top: Consts.topPadding * 3),
          children: [
            menuDivider,
            const MenuSwitch(
              label: "Show profiler",
              field: "profiler",
              defaultValue: false,
            ),
            MenuSwitch(
              label: 'Disable thread cache',
              field: 'thread_cache_disabled',
              onChanged: (val) {
                my.threadBloc.add(const ThreadCacheDisabled());
                my.prefs.put("thread_cache_disabled", val);
              },
              defaultValue: false,
            ),
            const MenuSwitch(
              label: "Disable async loading",
              field: "async_disabled",
              defaultValue: false,
            ),
            MenuTextField(
              label: "Top menu margin",
              boxField: "menu_margin",
              onSubmitted: (val) {
                final parsed = double.tryParse(val) ?? my.prefs.get('menu_margin');
                my.prefs.put('menu_margin', parsed);
              },
            ),
            menuDivider,
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Consts.sidePadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isDebug) ...[
                    Expanded(child: testButton),
                    menuDivider,
                  ],
                  Expanded(child: cleanButton),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            if (showLog) ...[
              Container(
                height: 600,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: Consts.sidePadding),
                  reverse: true,
                  itemCount: Log.length,
                  itemBuilder: (context, index) {
                    return Text(Log.all[index]);
                  },
                ),
              ),
            ]
          ],
        ));
  }
}
