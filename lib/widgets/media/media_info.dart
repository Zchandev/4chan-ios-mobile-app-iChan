import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/models/media.dart';
import 'package:ichan/pages/thread/animated_opacity_item.dart';
import 'package:ichan/ui/haptic.dart';
import 'package:ichan/ui/interactive.dart';
import 'package:ichan/widgets/menu/menu_text_field.dart';
import 'package:ichan/services/exports.dart';

class MediaInfo extends StatefulWidget {
  const MediaInfo({
    Key key,
    this.media,
    this.future,
    this.onOverscroll,
  }) : super(key: key);

  final Media media;
  final Future future;
  final Function onOverscroll;

  @override
  _MediaInfoState createState() => _MediaInfoState();
}

class _MediaInfoState extends State<MediaInfo> {
  static const ignoredKeys = [
    'Image YResolution',
    'Image XResolution',
    'Image ExifOffset',
    'JPEGThumbnail',
  ];
  static const mainKeys = [
    'Image Make',
    'Image Model',
    'EXIF ExposureTime',
    'EXIF ISOSpeedRatings',
    'EXIF DateTime',
    'EXIF LensMake',
    'EXIF LensModel',
    'Image Software',
  ];

  ScrollController controller;
  bool showAll = false;

  @override
  void initState() {
    controller = ScrollController();

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String clean(String s) => s.toString().replaceFirst(RegExp(r'(Image|EXIF|MakerNote)\s'), '');

  List<Widget> _buildExifItems(Map exif) {
    final List<Widget> array = [];
    if (exif == null || exif.isEmpty) {
      array.add(const MenuTextField(
        label: 'EXIF',
        value: 'No data',
        isLast: true,
      ));
      return array;
    }

    final mainData = exif.filter((e) => mainKeys.contains(e.key)).toMap();
    mainData.forEach((key, value) {
      final cleanKey = clean(key);

      array.add(MenuTextField(
        label: cleanKey,
        value: value.toString(),
      ));
    });

    if (showAll) {
      exif.forEach((key, value) {
        final cleanKey = clean(key);
        final condition = !mainKeys.contains(key) &&
            !ignoredKeys.contains(key) &&
            !cleanKey.startsWith('Thumbnail') &&
            value.toString().trim().isNotEmpty;

        if (condition) {
          array.add(MenuTextField(
            label: isDebug ? key : cleanKey,
            value: value.toString(),
          ));
        }
      });
    }

    return array;
  }

  Widget buildList(ScrollController controller, BuildContext context) {
    final mediaSize = widget.media.sizeInMb >= 1
        ? "${widget.media.sizeInMb.toStringAsFixed(2)} MB"
        : "${widget.media.size} KB";

    return ListView(
      controller: controller,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () {
            const actions = [ActionSheet(text: "Copy URL", value: "copy")];
            Interactive(context).modal(actions).then((val) {
              if (val == "copy") {
                Haptic.lightImpact();
                return Clipboard.setData(ClipboardData(text: widget.media.url));
              }
            });
          },
          child: MenuTextField(
            label: "URL",
            value: widget.media.url,
            fontSize: 12,
          ),
        ),
        MenuTextField(
          label: "File name",
          value: widget.media.origName ?? widget.media.name,
        ),
        MenuTextField(
          label: "Resolution",
          value: "${widget.media.height} x ${widget.media.width}",
        ),
        MenuTextField(
          label: "Size",
          value: mediaSize,
        ),
        ..._buildExifItems(widget.media.exifData),
        if (!showAll && widget.media.exifData != null && widget.media.exifData.length > 1) ...[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              setState(() {
                showAll = true;
              });
            },
            child: Container(
                alignment: Alignment.center,
                child: const FaIcon(
                  FontAwesomeIcons.chevronDown,
                  color: Colors.white54,
                )),
          )
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // print('BUILD media.url IS  ${media.url}');

    if (widget.onOverscroll != null) {
      controller.addListener(() {
        if (controller.offset <= -60) {
          widget.onOverscroll();
        }
      });
    }

    if (widget.future != null) {
      return AnimatedOpacityItem(
        child: FutureBuilder<Object>(
          future: widget.future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return buildList(controller, context);
            }
            return AnimatedOpacityItem(
              delay: 0.5,
              child: Container(
                alignment: Alignment.center,
                height: 200,
                child: const CupertinoActivityIndicator(),
              ),
            );
          },
        ),
      );
    } else {
      return buildList(controller, context);
    }
  }
}
