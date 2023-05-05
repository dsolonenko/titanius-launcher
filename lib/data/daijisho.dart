import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:titanius/data/repo.dart';

part 'daijisho.g.dart';

class PlatformWallpapersPack {
  List<String> authors;
  String description;
  bool isNSFW;
  String name;
  String previewThumbnailPath;
  String rootPath;

  PlatformWallpapersPack({
    required this.authors,
    required this.description,
    required this.isNSFW,
    required this.name,
    required this.previewThumbnailPath,
    required this.rootPath,
  });

  factory PlatformWallpapersPack.fromJson(Map<String, dynamic> json) {
    return PlatformWallpapersPack(
      authors: List<String>.from(json['platformWallpapersPackAuthors']),
      description: json['platformWallpapersPackDescription'],
      isNSFW: json['platformWallpapersPackIsNSFW'],
      name: json['platformWallpapersPackName'],
      previewThumbnailPath: json['platformWallpapersPackPreviewThumbnailPath'],
      rootPath: json['platformWallpapersPackRootPath'],
    );
  }

  get thumbnailUrl =>
      "https://raw.githubusercontent.com/TapiocaFox/Daijishou/main/themes/platform_wallpapers_packs/$previewThumbnailPath";
}

@riverpod
Future<List<PlatformWallpapersPack>> daijishoPlatformWallpapersPacks(DaijishoPlatformWallpapersPacksRef ref) async {
  final response = await http.get(Uri.parse(
      'https://raw.githubusercontent.com/TapiocaFox/Daijishou/main/themes/platform_wallpapers_packs/index.json'));

  if (response.statusCode == 200) {
    Map<String, dynamic> json = jsonDecode(response.body);
    List<dynamic> platformWallpapersPackListJson = json['platformWallpapersPackList'];
    List<PlatformWallpapersPack> platformWallpapersPackList =
        platformWallpapersPackListJson.map((dynamic item) => PlatformWallpapersPack.fromJson(item)).toList();
    return platformWallpapersPackList;
  } else {
    throw Exception('Failed to load platform wallpapers packs');
  }
}

class WallpaperPack {
  final String rootPath;
  final String name;
  final String description;
  final List<String> authors;
  final List<String> sources;
  final String previewThumbnailFilename;
  final bool hasDefaultWallpaper;
  final String defaultWallpaperFilename;
  final List<Wallpaper> wallpaperList;

  WallpaperPack({
    required this.rootPath,
    required this.name,
    required this.description,
    required this.authors,
    required this.sources,
    required this.previewThumbnailFilename,
    required this.hasDefaultWallpaper,
    required this.defaultWallpaperFilename,
    required this.wallpaperList,
  });

  factory WallpaperPack.fromJson(String rootPath, Map<String, dynamic> json) {
    return WallpaperPack(
      rootPath: rootPath,
      name: json['name'],
      description: json['description'],
      authors: List<String>.from(json['authors']),
      sources: List<String>.from(json['sources']),
      previewThumbnailFilename: json['previewThumbnailFilename'],
      hasDefaultWallpaper: json['hasDefaultWallpaper'],
      defaultWallpaperFilename: json['defaultWallpaperFilename'],
      wallpaperList: (json['wallpaperList'] as List).map((item) => Wallpaper.fromJson(item)).toList(),
    );
  }

  String defaultWallpaperUrl(String rootPath) {
    return "https://raw.githubusercontent.com/TapiocaFox/Daijishou/main/themes/platform_wallpapers_packs/$rootPath/$defaultWallpaperFilename";
  }
}

class Wallpaper {
  final String matchPlatformShortname;
  final String filename;

  Wallpaper({required this.matchPlatformShortname, required this.filename});

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      matchPlatformShortname: json['matchPlatformShortname'],
      filename: json['filename'],
    );
  }

  String imageUrl(String rootPath) {
    return "https://raw.githubusercontent.com/TapiocaFox/Daijishou/main/themes/platform_wallpapers_packs/$rootPath/$filename";
  }
}

Future<WallpaperPack?> daijishoWallpaperPack(String rootPath) async {
  final response = await http.get(Uri.parse(
      "https://raw.githubusercontent.com/TapiocaFox/Daijishou/main/themes/platform_wallpapers_packs/$rootPath/index.json"));

  if (response.statusCode == 200) {
    return WallpaperPack.fromJson(rootPath, json.decode(response.body));
  } else {
    debugPrint('Failed to load wallpaper pack $rootPath');
    return null;
  }
}

@Riverpod(keepAlive: true)
Future<WallpaperPack?> daijishoCurrentThemeData(DaijishoCurrentThemeDataRef ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final wallpaperPack = settings.daijishoWallpaperPack;
  if (wallpaperPack == null) {
    return null;
  }
  return daijishoWallpaperPack(wallpaperPack);
}
