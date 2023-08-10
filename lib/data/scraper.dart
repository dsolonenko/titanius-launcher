import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenscraper/screenscraper.dart' show MediaLink, RomScraper;
import 'package:titanius/data/env.dart';
import 'package:titanius/data/files.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';

part 'scraper.g.dart';

class Scraper {
  final RomScraper _scraper;

  Scraper({required String userName, required String userPassword})
      : _scraper = RomScraper(
          devId: Env.devId,
          devPassword: Env.devPassword,
          softwareName: Env.appName,
          userName: userName,
          userPassword: userPassword,
        );

  Future<Game> scrape(RomToScrape rom, void Function(String msg) progress) async {
    progress("Scraping ${rom.rom}...");
    final game = await _scraper.scrapeRom(systemId: rom.systemScreenScraperId, romPath: rom.absoluteRomPath);
    progress("ScreenScraper ID is ${game.gameId}");
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
    final task = DownloadTask(
      url: mediaLink.url,
      filename: mediaName,
      baseDirectory: BaseDirectory.temporary,
    );
    final result = await FileDownloader().download(task);
    if (result.status == TaskStatus.complete) {
      final filePath = await task.filePath();
      debugPrint("Downloaded to $filePath");
      final newFilePath = "$destinationFolder/$mediaName";
      File(newFilePath).parent.createSync(recursive: true);
      final newFile = await moveFile(File(filePath), newFilePath);
      return newFile.absolute.path;
    } else {
      debugPrint("Error downloading $mediaName: ${result.exception.toString()}");
    }
    return null;
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
