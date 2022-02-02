import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/models/media.dart';
import 'package:ichan/services/enums.dart';
import 'package:ichan/services/system.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/media/rounded_image.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    Key key,
    this.media,
    this.heroTag,
    this.origin,
  }) : super(key: key);

  final Media media;
  final String heroTag;
  final Origin origin;

  Border getBorder() {
    if (!my.prefs.getBool("media_color_enabled")) {
      return null;
    }
    final str = media.isImage ? 'image' : 'video';
    final mediumSize = my.prefs.getDouble("medium_${str}_size");
    final bigSize = my.prefs.getDouble("big_${str}_size");

    if (media.sizeInMb >= bigSize) {
      return Border.all(width: 2, color: CupertinoColors.systemRed.withOpacity(0.4));
    } else if (media.sizeInMb >= mediumSize) {
      return Border.all(width: 2, color: CupertinoColors.systemYellow.withOpacity(0.4));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = ExtendedNetworkImageProvider(
      media.thumbnailUrl,
      cache: true,
      headers: System.headersForPath(media.path),
    );

    final webmBorder = Border.all(
      color: CupertinoColors.destructiveRed.withOpacity(0.5),
      width: 2,
    );

    final nonRoundedImage = Container(
      decoration: BoxDecoration(
        border: getBorder(),
        image: DecorationImage(
          image: image,
          fit: BoxFit.cover,
        ),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Hero(
          tag: heroTag,
          child: origin == Origin.gallery
              ? nonRoundedImage
              : RoundedImage(image: image, border: getBorder()),
        ),
        if (media.isVideo) ...[
          Container(
            decoration: BoxDecoration(
              color: my.theme.backgroundColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(15.0),
              border: media.ext == 'webm' ? webmBorder : null,
            ),
            child: FaIcon(
              FontAwesomeIcons.solidPlayCircle,
              color: CupertinoColors.white.withOpacity(0.6),
              size: 22,
            ),
          )
        ],
      ],
    );
  }
}
