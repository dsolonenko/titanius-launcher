import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenscraper/screenscraper.dart' show MediaLink, RomScraper;
import 'package:titanius/data/env.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';

part 'scraper.g.dart';

class Scraper {
  final RomScraper _scraper;
  final dio = Dio();

  Scraper({required String userName, required String userPassword})
      : _scraper = RomScraper(
          devId: Env.devId,
          devPassword: Env.devPassword,
          softwareName: Env.appName,
          userName: userName,
          userPassword: userPassword,
        );

  Future<Game> scrape(RomToScrape rom, void Function(String msg) progress) async {
    progress("Scraping...");
    final game = await _scraper.scrapeRom(systemId: rom.systemScreenScraperId, romPath: rom.absoluteRomPath);
    debugPrint("ScreenScraper ID for ${rom.absoluteRomPath} is ${game.gameId}");
    final file = File(rom.absoluteRomPath);
    final fileName = file.uri.pathSegments.last;
    final fileNameNoExt = fileName.contains(".") ? fileName.substring(0, fileName.lastIndexOf(".")) : fileName;
    final romsPath = "${rom.volumePath}/${rom.systemFolder}";
    var imageUrl = rom.imageUrl;
    if (game.media.screenshot != null) {
      progress("Downloading screenshot...");
      imageUrl = await _downloadMedia(game.media.screenshot!, fileNameNoExt, "$romsPath/media/images");
    }
    var videoUrl = rom.videoUrl;
    if (game.media.videoNormalized != null) {
      progress("Downloading video...");
      videoUrl = await _downloadMedia(game.media.videoNormalized!, fileNameNoExt, "$romsPath/media/videos");
    }
    var thumbnailUrl = rom.thumbnailUrl;
    if (game.media.wheel != null) {
      progress("Downloading wheel...");
      thumbnailUrl = await _downloadMedia(game.media.wheel!, fileNameNoExt, "$romsPath/media/wheels");
    }
    return Game(
      systemAllGames, //dummy
      game.name,
      rom.volumePath,
      rom.systemFolder,
      rom.folder,
      rom.rom,
      id: game.gameId.toString(),
      description: game.description,
      genre: game.genres?.map((e) => e.name).join("/"),
      genreId: game.normalizedGenre,
      rating: 10 * game.rating,
      imageUrl: imageUrl?.replaceFirst(romsPath, "."),
      videoUrl: videoUrl?.replaceFirst(romsPath, "."),
      thumbnailUrl: thumbnailUrl?.replaceFirst(romsPath, "."),
      developer: game.developer,
      publisher: game.publisher,
      players: game.players,
      year: int.tryParse(game.releaseYear),
      favorite: rom.favorite,
      isFolder: false,
      hidden: rom.hidden,
      fromGamelistXml: true,
    );
  }

  Future<String?> _downloadMedia(MediaLink mediaLink, String fileNameNoExt, String destinationFolder) async {
    final mediaName = "$fileNameNoExt.${mediaLink.format}";
    debugPrint("Downloading $destinationFolder/$mediaName");
    final newFilePath = "$destinationFolder/$mediaName";
    final newFile = File(newFilePath);
    newFile.parent.createSync(recursive: true);
    final response = await dio.download(mediaLink.url, "$destinationFolder/$mediaName");
    debugPrint("Response: ${response.statusCode} ${response.statusMessage}");
    if (response.statusCode == 200) {
      return newFile.absolute.path;
    } else {
      return null;
    }
  }

  close() {
    _scraper.close();
  }
}

@Riverpod(keepAlive: true)
Future<Scraper> scraper(ScraperRef ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final scraper = Scraper(
    userName: settings.screenScraperUser ?? "",
    userPassword: settings.screenScraperPwd ?? "",
  );
  return scraper;
}
