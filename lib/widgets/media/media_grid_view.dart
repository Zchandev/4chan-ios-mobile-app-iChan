import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/models/media.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/media/selectable_media.dart';
import 'package:ichan/widgets/media/gallery_media.dart';

import 'media_extension.dart';

class MediaGridView extends HookWidget {
  const MediaGridView({
    Key key,
    this.mediaList,
    this.threadData,
    this.origin,
    this.selectable,
    this.scrollIndex = -1,
  }) : super(key: key);

  final ThreadData threadData;
  final List<Media> mediaList;
  final Origin origin;
  final ValueNotifier<Media> selectable;
  final int scrollIndex;

  static const regularPadding = EdgeInsets.only(top: Consts.topNavbarHeight - 25);
  static const notchPadding = EdgeInsets.only(top: Consts.topNavbarHeight);

  List<Media> get _mediaList => mediaList ?? threadData?.mediaList ?? [];

  int calcItemsCount(Orientation orientation) {
    if (orientation == Orientation.landscape) {
      return my.contextTools.isPhone ? 4 : 8;
    } else {
      return my.contextTools.isPhone ? 3 : 6;
    }
  }

  double calcScrollOffset(BuildContext context) {
    final rowItemsCount = calcItemsCount(MediaQuery.of(context).orientation);
    final height = context.screenWidth / rowItemsCount;
    final columnItemsCount = (context.screenHeight - Consts.topNavbarHeight) ~/ height;
    // print("columnItemsCount = ${columnItemsCount}");

    final maxIndex = (threadData.mediaList.length - 1) - columnItemsCount * rowItemsCount;
    // print("maxIndex = ${maxIndex}, scrollIndex = $scrollIndex");

    final needRow =
        maxIndex > scrollIndex ? scrollIndex ~/ rowItemsCount : maxIndex ~/ rowItemsCount;
    // print("needRow = ${needRow}");
    final needHeight = height * needRow;
    // print("needHeight = ${needHeight}");
    return needHeight;
  }

  @override
  Widget build(BuildContext context) {
    final scrollOffset = scrollIndex <= 0 ? 0.0 : calcScrollOffset(context);
    final controller = useScrollController(initialScrollOffset: scrollOffset);

    final padding = selectable == null
        ? (my.contextTools.hasHomeButton ? regularPadding : notchPadding)
        : const EdgeInsets.only(top: Consts.topPadding / 4);

    return OrientationBuilder(
      builder: (context, orientation) {
        return CupertinoScrollbar(
          child: GridView.builder(
            controller: controller,
            padding: padding,
            itemCount: selectable != null && _mediaList.length == 10 ? 9 : _mediaList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: calcItemsCount(orientation), childAspectRatio: 1 / 1),
            itemBuilder: (_, index) {
              final media = _mediaList[index];

              final mediaWidget = selectable != null
                  ? SelectableGalleryMedia(
                      selectable: selectable, media: media, mediaList: mediaList)
                  : GalleryMedia(
                      threadData: threadData,
                      media: media,
                      origin: Origin.gallery,
                    );

              return Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    margin: const EdgeInsets.all(1),
                    child: mediaWidget,
                  ),
                  if (my.prefs.getBool('show_extension')) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: MediaExtension(media: media),
                    )
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
