import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:mime_type/mime_type.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailResult {
  const ThumbnailResult({this.image, this.dataSize, this.height, this.width});

  final Image image;
  final int dataSize;
  final int height;
  final int width;
}

class FileTools {
  FileTools({this.path, this.file}) {
    if (file != null) {
      path = file.path;
    }
  }

  String path;
  File file;
  Uint8List bytes;
  final Completer<ThumbnailResult> completer = Completer();

  String get filename => basename(path);
  String get mimeType => mime(filename);
  String get mimee => mimeType.split('/')[0];
  String get type => mimeType.split('/')[1];
  String get ext => filename.split(".")[1].toLowerCase();
  bool get isImage => mimee == "image";
  bool get isVideo => mimee == "video";

  Future<ThumbnailResult> videoThumbnail({int maxWidth = 100, int quality = 25}) async {
    final bytes = await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: maxWidth,
      quality: quality,
    );

    final _image = Image.memory(bytes);
    final int _imageDataSize = bytes.length;

    _image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(ThumbnailResult(
        image: _image,
        dataSize: _imageDataSize,
        height: info.image.height,
        width: info.image.width,
      ));
    }));

    return completer.future;
  }

  Future<ThumbnailResult> thumbnail() async {
    if (isImage) {
      return Future.value(ThumbnailResult(image: Image.file(file)));
    }

    return videoThumbnail();
  }
}
