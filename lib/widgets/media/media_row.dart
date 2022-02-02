import 'package:flutter/cupertino.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/pages/thread/thread.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/media/gallery_media.dart';

import 'media_extension.dart';

class MediaRow extends StatelessWidget {
  const MediaRow({
    @required this.items,
    @required this.threadData,
    @required this.origin,
    this.highlightMedia,
  });

  final List<Media> items;
  final ThreadData threadData;
  final Origin origin;
  final Media highlightMedia;

  double getWidth(BuildContext context) {
    final imageWidth = origin == Origin.board ? Consts.threadImageWidth : Consts.postImageWidth;

    final n = origin == Origin.board ? 7 : 5.5;

    if (!Consts.isIpad && items.length == 4) {
      final width = context.screenWidth;
      final imagesWidth = 4 * imageWidth + Consts.sidePadding * n;
      if (width < imagesWidth) {
        return (width - Consts.sidePadding * n) / 4;
      }
    }

    return imageWidth;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(height: 0, width: 0);
    }

    final width = getWidth(context);

    return Container(
      height: width,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final media = items[index];
          return Stack(
            children: [
              Container(
                width: width,
                height: width,
                margin: const EdgeInsets.only(right: 10.0),
                decoration: boxDecoration(media),
                child: GalleryMedia(
                  origin: origin,
                  media: media,
                  threadData: threadData,
                ),
              ),
              if (my.prefs.getBool('show_extension')) ...[
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: MediaExtension(media: media),
                  ),
                )
              ],
            ],
          );
        },
      ),
    );
  }

  BoxDecoration boxDecoration(Media media) {
    if (highlightMedia == null || highlightMedia.md5 != media.md5) {
      return null;
    }
    if (items.length == 1) {
      return null;
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(15.0),
      border: Border.all(
        color: CupertinoColors.activeGreen.withOpacity(0.7),
        width: 2,
      ),
    );
  }
}
