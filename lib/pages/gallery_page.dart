import 'package:flutter/material.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/services/exports.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/widgets/media/media_actions.dart';
import 'package:ichan/widgets/media/media_grid_view.dart';

class GalleryPage extends StatelessWidget with MediaActions {
  const GalleryPage({
    Key key,
    this.scrollIndex,
    @required this.threadData,
  }) : super(key: key);

  static const routeName = '/gallery';

  final int scrollIndex;
  final ThreadData threadData;

  @override
  Widget build(BuildContext context) {
    if (my.prefs.getBool('disable_autoturn')) {
      System.setAutoturn('auto');
    }

    if (!my.prefs.getBool('enable_media')) {
      return HeaderNavbar(
        middleText: "Gallery",
        child: Container(),
      );
    }

    return HeaderNavbar(
      transparent: true,
      child: MediaGridView(
        threadData: threadData,
        origin: Origin.gallery,
        scrollIndex: scrollIndex,
      ),
      middleText: "Gallery",
      trailing: GestureDetector(
        onTap: () => showMenu(context),
        child: const Padding(
          padding: EdgeInsets.only(left: 15.0),
          child: Icon(CupertinoIcons.share, size: 30),
        ),
      ),
    );
  }

  Future<void> showMenu(BuildContext context) async {
    final sheets = [
      const ActionSheet(text: 'Save all images', value: 'save_images'),
    ];

    final result = await Interactive(context).modal(sheets);

    if (result == 'save_images') {
      Haptic.mediumImpact();
      final mediaList = my.threadBloc.getThreadData(threadData.thread.toKey).mediaList;

      for (final media in mediaList) {
        if (media.isImage) {
          // print('Downloading media...');
          await saveMedia(media);
          // await Future.delayed(0.1.seconds);
        }

        // await my.mediaCache.getSingleFile(media.url);
        // await my.mediaCache.getSingleFile(media.thumbnailUrl);
      }
      Interactive(context).message(content: "Saved");
      // print('Download finished');
    } else if (result == 'save') {}
  }
}
