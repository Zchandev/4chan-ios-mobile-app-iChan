import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ichan/services/my.dart' as my;

class AboutSettingsPage extends StatefulWidget {
  const AboutSettingsPage({Key key}) : super(key: key);

  @override
  _AboutSettingsPageState createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends State<AboutSettingsPage> {
  final licenceController = TextEditingController();

  @override
  void dispose() {
    licenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const header = 'About iChan';

    final supportButton = CupertinoButton(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 16.0, bottom: 16.0),
      onPressed: () async {
        if (await canLaunch(Consts.patreonUrl)) {
          return await launch(Consts.patreonUrl, forceSafariVC: false);
        }
        return Future.value();
      },
      color: my.theme.primaryColor,
      child: const Text(
        'Support project',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    final data = ListView(
      padding: const EdgeInsets.only(top: Consts.topPadding * 3),
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () {
            Haptic.heavyImpact();
            setState(() {
              my.prefs.put('tester', !my.prefs.isTester);
            });
          },
          child: MenuTextField(
            label: "Version",
            value: Consts.version.toString(),
            isFirst: true,
          ),
        ),
        MenuTextField(
          label: "Build",
          value: Consts.build.toString(),
        ),
        if (my.prefs.isTester) ...[
          MenuTextField(
            label: "Testing",
            value: my.prefs.isTester ? 'on' : 'off',
          )
        ],
        MenuTextField(
          label: 'Telegram group',
          value: my.prefs.platforms[0] == Platform.dvach ? Consts.telegramRu : Consts.telegramEn,
          onTap: () async {
            final url = my.prefs.platforms[0] == Platform.dvach
                ? Consts.telegramRuUrl
                : Consts.telegramEnUrl;
            if (await canLaunch(url)) {
              await launch(url);
            }
          },
          isLast: true,
        ),
        if (my.prefs.platforms[0] != Platform.dvach) ...[
          MenuTextField(
            label: 'Discord server',
            value: Consts.discordUrl.replaceAll('https://', ''),
            onTap: () async {
              if (await canLaunch(Consts.discordUrl)) {
                await launch(Consts.discordUrl);
              }
            },
            isLast: true,
          ),
        ],
        menuDivider,
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Consts.sidePadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: supportButton),
              menuDivider,
            ],
          ),
        )
      ],
    );

    return HeaderNavbar(
      backgroundColor: my.theme.secondaryBackgroundColor,
      middle: Text(header, style: TextStyle(color: my.theme.navbarFontColor)),
      child: data,
      previousPageTitle: "Settings",
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> showMessage(BuildContext context, {String header, String message}) {
    return showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(header),
            content: Text(message),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    Haptic.lightImpact();
                    Clipboard.setData(ClipboardData(text: message));
                    Navigator.pop(context);
                  },
                  child: Text('Copy', style: TextStyle(color: my.theme.primaryColor))),
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Close', style: TextStyle(color: my.theme.alertColor))),
            ],
          );
        });
  }
}
