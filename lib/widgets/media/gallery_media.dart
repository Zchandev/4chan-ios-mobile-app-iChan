import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/blocs/thread/event.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/pages/gallery_item_page.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

import 'media_actions.dart';
import 'media_thumbnail.dart';

class GalleryMedia extends StatefulWidget {
  const GalleryMedia({
    Key key,
    @required this.media,
    @required this.threadData,
    this.post,
    this.origin = Origin.thread,
  }) : super(key: key);

  final Media media;
  final ThreadData threadData;
  final Post post;
  final Origin origin;

  @override
  _GalleryMediaState createState() => _GalleryMediaState();
}

class _GalleryMediaState extends State<GalleryMedia> with MediaActions {
  bool justSaved = false;

  Future<void> showVideoPopup(BuildContext context, Media media) async {
    final actionSheets = [
      if (!isIos || media.ext != 'webm') ...[
        const ActionSheet(text: "Save"),
      ],
      const ActionSheet(text: "Share"),
      const ActionSheet(text: "Go to post"),
    ];

    final result = await Interactive(context).modal(actionSheets);
    if (result == "save") {
      try {
        final result = await saveMedia(media);
        showSaveResult(result);
      } catch (e) {
        Interactive(context).message(title: "Error", content: e.toString());
      }
    } else if (result == "go to post") {
      Haptic.mediumImpact();
      Routz.of(context).backToThread();
      my.threadBloc
          .add(ThreadScrollStarted(postId: media.postId, thread: widget.threadData.thread));
    } else if (result == "share") {
      try {
        return await shareMedia(media);
      } catch (e) {
        Interactive(context).message(title: "Error", content: e.toString());
      }
    }
  }

  Future<void> showImagePopup(BuildContext context, Media media) async {
    final sheet = [
      const ActionSheet(text: "Save"),
      const ActionSheet(text: "Share"),
      const ActionSheet(text: "Go to post"),
    ];

    final result = await Interactive(context).modal(sheet);

    if (result == "share") {
      try {
        await shareMedia(media);
      } catch (e) {
        Interactive(context).message(title: "Error", content: e.toString());
      }
    } else if (result == "go to post") {
      Haptic.mediumImpact();
      Routz.of(context).backToThread();
      my.threadBloc
          .add(ThreadScrollStarted(postId: media.postId, thread: widget.threadData.thread));
    } else if (result == "save") {
      final result = await saveMedia(media);
      showSaveResult(result);
    }

    return;
  }

  @override
  Widget build(BuildContext context) {
    final heroTag =
        [Origin.board, Origin.activity].contains(widget.origin) || widget.media.isSticker
            ? UniqueKey().toString()
            : widget.media.thumbnailUrl;

    return GestureDetector(
      onLongPress: () {
        if (widget.media.isImage) {
          showImagePopup(context, widget.media);
        } else {
          showVideoPopup(context, widget.media);
        }
      },
      onTap: () async {
        if (widget.threadData.mediaList.isEmpty) {
          return;
        }

        // final result = await Routz.of(context).fadeToPage(
        Routz.of(context).fadeToPage(
          GalleryItemPage(
            media: widget.media,
            origin: widget.origin,
            thread: widget.threadData.thread,
            mediaList: widget.threadData.mediaList,
          ),
          replace: widget.origin == Origin.gallery,
          settings: RouteSettings(name: GalleryItemPage.routeName),
        );

        // if (result == true) {
        //   return Navigator.pop(context);
        // }
      },
      child: Stack(
        children: [
          MediaThumbnail(
            heroTag: heroTag,
            media: widget.media,
            origin: widget.origin,
          ),
          AnimatedOpacity(
            opacity: justSaved ? 1.0 : 0.0,
            duration: 0.3.seconds,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: my.theme.backgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.fileDownload,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showSaveResult(bool result) {
    if (result == true) {
      setState(() {
        justSaved = true;
        Future.delayed(1.0.seconds).then((value) {
          setState(() {
            justSaved = false;
          });
        });
      });
    }
  }
}
