import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ichan/models/media.dart';
import 'package:ichan/services/exceptions.dart';
import 'package:ichan/services/file_tools.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/services/exports.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wc_flutter_share/wc_flutter_share.dart';

mixin MediaActions {
  Future<void> shareMedia(Media media) async {
    if (await Permission.photos.request().isGranted == false) {
      throw MyException("Please allow access to photos");
    }

    Uint8List bytes;
    FileTools fileTools;
    if (media.isImage) {
      bytes = await getNetworkImageData(media.url, useCache: true);
      fileTools = FileTools(path: media.url);
    } else {
      final file = await my.cacheManager.getSingleFile(media.url);
      fileTools = FileTools(file: file);
      bytes = file.readAsBytesSync();
    }

    await WcFlutterShare.share(
      sharePopupTitle: 'Share',
      fileName: media.name,
      mimeType: fileTools.mimeType,
      bytesOfFile: bytes.buffer.asUint8List(),
    );
  }

  Future<bool> saveMedia(Media media) async {
    if (await Permission.photos.request().isGranted == false) {
      throw MyException("Please allow access to photos");
    }

    if (await Permission.storage.request().isGranted == false) {
      throw MyException("Please allow access to photos");
    }

    final album = my.prefs.getString('media_album').presence;

    if (media.isVideo) {
      final file = await my.cacheManager.getSingleFile(media.url);

      if (!isIos && media.ext == 'webm') {
        await ImageGallerySaver.saveFile(file.path);
      } else {
        await GallerySaver.saveVideo(file.path, albumName: album);
      }
      return Future.value(true);
    } else {
      final file = await my.cacheManager.getSingleFile(media.url);
      print('media.ext = ${media.ext}');
      // final file = await my.cacheManager.putFile(media.url, bytes, fileExtension: media.ext);

      if (album != null || isIos) {
        print('file.path = ${file.path}');
        return await GallerySaver.saveImage(file.path, albumName: album);
      } else {
        await ImageGallerySaver.saveFile(file.path);
      }
      return Future.value(true);
    }
  }
}
