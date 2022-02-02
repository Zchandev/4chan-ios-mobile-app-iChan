import 'package:flutter/cupertino.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/pages/thread/thread.dart';

class MediaExtension extends StatelessWidget {
  const MediaExtension({Key key, @required this.media}) : super(key: key);

  final Media media;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 15,
      width: 35,
      decoration: BoxDecoration(
        color: CupertinoColors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5.0),
      ),
      alignment: Alignment.center,
      margin: const EdgeInsets.only(right: 5.0),
      child: Text(
        media.ext,
        style: const TextStyle(fontSize: 11, color: CupertinoColors.white),
      ),
    );
  }
}
