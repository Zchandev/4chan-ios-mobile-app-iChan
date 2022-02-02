import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/media/gallery_media.dart';

class ThreadImage extends StatelessWidget {
  const ThreadImage({
    Key key,
    @required this.thread,
    this.width,
    this.height,
  }) : super(key: key);

  final Thread thread;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Container(
            width: width ?? height,
            height: height ?? width,
            child: GalleryMedia(
              origin: Origin.board,
              threadData: ThreadData(thread: thread),
              media: thread.mediaFiles[0],
            )),
        if (thread.mediaFiles.length >= 2) ...[
          Container(
              margin: const EdgeInsets.only(left: 5.0, bottom: 5.0),
              padding: const EdgeInsets.all(3.0),
              decoration:
                  BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(3.0)),
              child: Text(
                "x${thread.mediaFiles.length}",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ))
        ]
      ],
    );
  }
}
