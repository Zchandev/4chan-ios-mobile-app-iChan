import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ichan/services/my.dart' as my;

import 'package:http_parser/http_parser.dart';

import 'file_tools.dart';

class ImageProcess {
  static Future<List<MultipartFile>> filesToUpload(List<File> files) async {
    final future = files.map<Future<MultipartFile>>((file) async {
      return await fileToUpload(file);
    });

    return await Future.wait<MultipartFile>(future);
  }

  static Future<MultipartFile> fileToUpload(File file) async {
    final tools = FileTools(path: file.path);
    String filename = tools.filename;

    Uint8List bytes = file.readAsBytesSync();

    if (tools.isImage && tools.ext != 'gif') {
      if (my.prefs.getBool('compress_images')) {
        if (tools.ext != 'png' || my.prefs.getBool('convert_png_to_jpg')) {
          bytes = await _compressImage(bytes);
          filename = filename
              .replaceFirst('.png', '.jpg')
              .replaceFirst('.PNG', '.JPG')
              .replaceFirst('.HEIC', '.JPG');
        }
      } else if (my.prefs.getBool('clean_exif') && tools.ext != 'png') {
        bytes = await _cleanExif(bytes);
      }
    }

    return MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: MediaType(tools.mimee, tools.type),
    );
  }

  static Future<Uint8List> _compressImage(Uint8List bytes) async {
    final qualityMap = {
      "very_high": 85,
      "high": 80,
      "medium": 70,
    };

    final quality = qualityMap[my.prefs.getString("compress_quality")];
    final resolution = my.prefs.getInt('compress_image_resolution');
    final keepExif = !my.prefs.getBool('clean_exif');

    return await FlutterImageCompress.compressWithList(
      bytes,
      minHeight: resolution,
      minWidth: resolution,
      quality: quality,
      keepExif: keepExif,
    );
  }

  static Future<Uint8List> _cleanExif(Uint8List bytes) async {
    return await FlutterImageCompress.compressWithList(
      bytes,
      minHeight: 10000,
      minWidth: 10000,
      quality: 90,
      keepExif: false,
    );
  }
}
