import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenscraper/screenscraper.dart' show RomScraper, MediaLink;
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

  Future<Game> scrape(Game rom) async {
    final game = await _scraper.scrapeRom(systemId: rom.system.screenScraperId, romPath: rom.absoluteRomPath);
    debugPrint("ScreenScraper ID is ${game.gameId}");
    final fileNameNoExt = rom.absoluteRomPath.substring(0, rom.absoluteRomPath.lastIndexOf("."));
    final romsPath = "${rom.volumePath}/${rom.systemFolder}";
    var imageUrl = rom.imageUrl;
    if (imageUrl == null && game.media.screenshot != null) {
      imageUrl = await _downloadMedia(game.media.screenshot!, fileNameNoExt, "$romsPath/media/images");
    }
    var videoUrl = rom.videoUrl;
    if (videoUrl == null && game.media.videoNormalized != null) {
      videoUrl = await _downloadMedia(game.media.videoNormalized!, fileNameNoExt, "$romsPath/media/videos");
    }
    var thumbnailUrl = rom.thumbnailUrl;
    if (thumbnailUrl == null && game.media.wheel != null) {
      thumbnailUrl = await _downloadMedia(game.media.wheel!, fileNameNoExt, "$romsPath/media/wheels");
    }
    return rom;
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

@riverpod
Future<Scraper> scraper(ScraperRef ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final scraper = Scraper(
    userName: settings.screenScraperUser ?? "",
    userPassword: settings.screenScraperPwd ?? "",
  );
  ref.onDispose(() => scraper.close());
  return scraper;
}
