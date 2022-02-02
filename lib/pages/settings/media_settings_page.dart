import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/menu/menu.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:directory_picker/directory_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaSettingsPage extends StatefulWidget {
  static const header = 'Media';

  @override
  _MediaSettingsPageState createState() => _MediaSettingsPageState();
}

class _MediaSettingsPageState extends State<MediaSettingsPage> {
  final TextEditingController albumController = TextEditingController();

  void fieldChanged(String field, String val) {
    double parsedVal;
    try {
      final _val = val.replaceAll(',', '.');
      parsedVal = double.parse(_val);
      if (parsedVal <= 0.0) {
        parsedVal = 0.0;
      } else if (parsedVal >= 1000) {
        parsedVal = 1000.0;
      }
    } catch (e) {
      parsedVal = 1.0;
    }

    my.prefs.put(field, parsedVal);
  }

  Widget build(BuildContext context) {
    return HeaderNavbar(
      backgroundColor: my.theme.secondaryBackgroundColor,
      middleText: MediaSettingsPage.header,
      previousPageTitle: "Settings",
      child: ListView(
        padding: const EdgeInsets.only(top: Consts.topPadding * 3),
        children: [
          MenuSwitch(
            label: 'Disable media',
            field: 'disable_media',
            defaultValue: false,
            onChanged: (val) {
              // todo: remove this hack
              my.prefs.put('enable_media', !val);
            },
          ),
          const MenuSwitch(
            label: "Disable image preloading",
            field: "image_preload_disabled",
            defaultValue: false,
          ),
          const MenuSwitch(
            label: "Show media extension",
            field: "show_extension",
            defaultValue: false,
          ),
          menuDivider,
          MenuSwitch(
            label: "Border color based on size",
            field: "media_color_enabled",
            defaultValue: false,
            onChanged: (_) {
              setState(() {});
            },
          ),
          MenuTextField(
            label: "Medium image size (mb)",
            boxField: "medium_image_size",
            enabled: my.prefs.getBool('media_color_enabled'),
            onSubmitted: (String val) {
              fieldChanged("medium_image_size", val);
              return false;
            },
          ),
          MenuTextField(
            label: "Big image size (mb)",
            boxField: "big_image_size",
            enabled: my.prefs.getBool('media_color_enabled'),
            onSubmitted: (String val) {
              fieldChanged("big_image_size", val);
              return false;
            },
          ),
          MenuTextField(
            label: "Medium video size (mb)",
            boxField: "medium_video_size",
            enabled: my.prefs.getBool('media_color_enabled'),
            onSubmitted: (String val) {
              fieldChanged("medium_video_size", val);
              return false;
            },
          ),
          MenuTextField(
            label: "Big video size (mb)",
            boxField: "big_video_size",
            enabled: my.prefs.getBool('media_color_enabled'),
            onSubmitted: (String val) {
              fieldChanged("big_video_size", val);
              return false;
            },
          ),
          menuDivider,
          MenuTextField(
            label: "Album for media",
            boxField: "media_album",
            onTap: () async {
              if (isIos) {
                if (await Permission.photos.request().isGranted == false) {
                  Interactive(context).message(content: "Please allow access to photos");
                  return false;
                }
              } else {
                if (await Permission.storage.request().isGranted == false) {
                  Interactive(context).message(content: "Please allow access to directories");
                  return false;
                }

                final rootDirectory = await getExternalStorageDirectory();
                final newDirectory = await DirectoryPicker.pick(
                  context: context,
                  rootDirectory: rootDirectory,
                );

                if (newDirectory != null) {
                  setState(() {
                    my.prefs.put('media_album', newDirectory.path);
                  });
                }
                return false;
              }
            },
          ),
        ],
      ),
    );
  }
}
