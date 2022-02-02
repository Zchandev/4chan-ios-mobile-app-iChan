import 'package:exif/exif.dart';
import 'package:extended_image/extended_image.dart';
import 'package:hive/hive.dart';

part 'media.g.dart';

@HiveType(typeId: 4)
class Media extends HiveObject {
  Media({
    this.path,
    this.url,
    this.name,
    this.origName,
    this.thumbnail,
    this.thumbnailUrl,
    this.md5,
    this.nsfw,
    this.ext,
    this.postId,
    this.isVideo = false,
    this.isCached = false,
    this.size = 0,
    this.width = 0,
    this.height = 0,
  });

  factory Media.fromGoogleQuery(Map<String, dynamic> json) {
    final imageData = json['image'] as Map<String, dynamic>;

    return Media(
      path: json['link'] as String,
      url: json['link'] as String,
      thumbnail: imageData['thumbnailLink'] as String,
      thumbnailUrl: imageData['thumbnailLink'] as String,
      ext: (json['mime'] as String).split('/')[1].toLowerCase(),
    );
  }

  factory Media.fromUrl(String url) {
    final ext = url.split(".").last;

    return Media(
      path: url,
      url: url,
      thumbnail: url,
      thumbnailUrl: url,
      ext: ext,
    );
  }

  factory Media.fromMap(Map<String, dynamic> json, String domain) {
    assert(json['path'] != null);

    final _path = json['path'] as String;
    final _thumbnail = json['thumbnail'] as String;

    final ext = json['ext'] ?? (json['name'] as String).split(".")[1];
    final isVideo = ext == "mp4" || ext == "webm";

    assert(json['postId'] != null);

    return Media(
      path: _path,
      url: "$domain$_path",
      name: json['name'] as String,
      origName: json['fullname'] as String,
      thumbnail: _thumbnail,
      thumbnailUrl: "$domain$_thumbnail",
      md5: json['md5'] as String,
      nsfw: json['nsfw'] == 1,
      postId: json['postId'] as String,
      ext: ext,
      isVideo: isVideo,
      size: json['size'],
      width: json['width'],
      height: json['height'],
    );
  }
  @HiveField(0)
  final String postId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String origName;

  @HiveField(3)
  final String thumbnail;

  @HiveField(4)
  final String thumbnailUrl;

  @HiveField(5)
  final String md5;

  @HiveField(6)
  final String path;

  @HiveField(7)
  final String url;

  @HiveField(8)
  final String ext;

  @HiveField(9)
  final bool nsfw;

  @HiveField(10)
  final int size;

  @HiveField(11)
  final int width;

  @HiveField(12)
  final int height;

  @HiveField(13)
  final bool isVideo;

  bool isCached;
  Map<String, IfdTag> exifData;

  String toString() => name ?? url;

  String get sizeToHuman => sizeInMb > 0 ? sizeInMb.toString() : '';

  double get sizeInMb => size / 1024;
  double get ratio => width / height;

  bool get isImage => !isVideo;
  bool get isWide => ratio >= 1.5;

  bool get isSticker => path.startsWith('/stickers');

  Future<void> readExif() async {
    if (isVideo) {
      return Future.value();
    }

    if (exifData == null) {
      final bytes = await getNetworkImageData(url, useCache: true);
      exifData = await readExifFromBytes(bytes);
    }
    return Future.value();
  }
}
