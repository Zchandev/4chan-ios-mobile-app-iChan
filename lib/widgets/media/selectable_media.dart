import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/models/media.dart';
import 'package:ichan/pages/gallery_item_page.dart';
import 'package:ichan/services/enums.dart';
import 'package:ichan/services/routz.dart';

import 'media_thumbnail.dart';

class SelectableGalleryMedia extends StatelessWidget {
  const SelectableGalleryMedia({
    Key key,
    @required this.selectable,
    @required this.media,
    @required this.mediaList,
  }) : super(key: key);

  final ValueNotifier<Media> selectable;
  final Media media;
  final List<Media> mediaList;

  void openMedia(BuildContext context) {
    Routz.of(context).fadeToPage(
      GalleryItemPage(
        mediaList: mediaList,
        media: media,
        origin: Origin.search,
      ),
      settings: RouteSettings(name: GalleryItemPage.routeName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (selectable.value == media) {
          openMedia(context);
        } else {
          selectable.value = media;
        }
      },
      onLongPress: () => openMedia(context),
      child: Stack(
        alignment: selectable == null ? Alignment.center : Alignment.topRight,
        children: [
          MediaThumbnail(heroTag: media.thumbnailUrl, media: media),
          if (selectable != null) ...[
            ValueListenableBuilder(
                valueListenable: selectable,
                builder: (context, _media, val) {
                  if (selectable.value == media) {
                    return Container(
                      margin: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue,
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.checkCircle,
                        color: CupertinoColors.white,
                      ),
                    );
                  } else {
                    return Container();
                  }
                })
          ],
        ],
      ),
    );
  }
}
