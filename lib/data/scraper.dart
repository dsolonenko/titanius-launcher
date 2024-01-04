import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenscraper/screenscraper.dart'
    show DoNotRetryException, DoneForTheDayException, MediaLink, RomScraper, ScreenScraperException;
import 'package:titanius/data/env.dart';
import 'package:titanius/data/files.dart';
import 'package:titanius/data/gamelist_xml.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:retry/retry.dart';

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
          httpLogging: true,
        );

  Future<Game> scrape(Game rom, void Function(String msg) progress, {int? gameId}) async {
    progress("Scraping...");
    const r = RetryOptions(maxAttempts: 5, delayFactor: Duration(seconds: 1));
    final game = await r.retry(
      () => gameId != null
          ? _scraper.scrapeGame(systemId: rom.system.screenScraperId, gameId: gameId)
          : _scraper.scrapeRom(systemId: rom.system.screenScraperId, romPath: rom.absoluteRomPath),
      retryIf: (e) => _canRetryScraper(e),
    );
    debugPrint("ScreenScraper ID for ${rom.absoluteRomPath} is ${game.gameId}");
    final file = File(rom.absoluteRomPath);
    final fileName = file.uri.pathSegments.last;
    final fileNameNoExt = fileName.contains(".") ? fileName.substring(0, fileName.lastIndexOf(".")) : fileName;
    final romsPath = "${rom.volumePath}/${rom.systemFolder}";
    var imageUrl = rom.imageUrl;
    if (game.media.screenshot != null) {
      progress("Downloading screenshot...");
      imageUrl = await r.retry(
        () => _downloadMedia(game.media.screenshot!, fileNameNoExt, "$romsPath/media/images"),
        retryIf: (e) => _canRetryScraper(e),
      );
    }
    var videoUrl = rom.videoUrl;
    if (game.media.videoNormalized != null) {
      progress("Downloading video...");
      videoUrl = await r.retry(
        () => _downloadMedia(game.media.videoNormalized!, fileNameNoExt, "$romsPath/media/videos"),
        retryIf: (e) => _canRetryScraper(e),
      );
    }
    var thumbnailUrl = rom.thumbnailUrl;
    if (game.media.wheel != null) {
      progress("Downloading wheel...");
      thumbnailUrl = await r.retry(
        () => _downloadMedia(game.media.wheel!, fileNameNoExt, "$romsPath/media/wheels"),
        retryIf: (e) => _canRetryScraper(e),
      );
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
      throw ScreenScraperException.fromHttpResponse(response.statusCode ?? 401, response.data.toString());
    }
  }

  close() {
    _scraper.close();
  }
}

bool _canRetryScraper(Exception e) {
  return !(e is DoNotRetryException || e is DoneForTheDayException);
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

scrapeGames(ServiceInstance service, Map<String, dynamic>? event) async {
  try {
    final username = event!["username"] as String?;
    final password = event["password"] as String?;
    final romFolders = (event["romFolders"] as List).map((e) => e.toString()).toList();
    final roms = (event["roms"] as List).map((e) => Game.fromJson(e)).toList();
    final romsMap = {for (var rom in roms) rom.absoluteRomPath: rom};
    final systems = (event["systems"] as List).map((e) => System.fromJson(e)).toList();
    final scrapeTheseGames = event["scrapeTheseGames"] as String;
    debugPrint("Scraping $scrapeTheseGames for ${systems.length} systems with ${roms.length} existing roms...");
    service.invoke(
      'update',
      {
        "total": 0,
        "success": 0,
        "error": 0,
        "pending": 0,
        "system": "",
        "rom": "",
        "msg": "Starting...",
      },
    );

    try {
      final gamesToScrape = <Game>[];
      for (var system in systems) {
        for (var romsFolder in romFolders) {
          for (var folder in system.folders) {
            service.invoke(
              'update',
              {
                "total": 0,
                "success": 0,
                "error": 0,
                "pending": gamesToScrape.length,
                "system": "",
                "rom": "",
                "msg": "Discovering...",
              },
            );
            final games = await listGamesFromFiles(
              romsFolder: romsFolder,
              folder: folder,
              system: system,
            );
            for (final g in games) {
              final game = romsMap[g.absoluteRomPath];
              if (game == null) {
                gamesToScrape.add(g);
              } else {
                switch (scrapeTheseGames) {
                  case "all_games":
                    gamesToScrape.add(game);
                    break;
                  case "favourites":
                    if (game.favorite) {
                      gamesToScrape.add(game);
                    }
                    break;
                  case "missing_details":
                    if (game.needsScraping) {
                      gamesToScrape.add(game);
                    }
                    break;
                }
              }
            }
          }
        }
      }
      service.invoke(
        'update',
        {
          "total": 0,
          "success": 0,
          "error": 0,
          "pending": gamesToScrape.length,
          "system": "",
          "rom": "",
          "msg": "Scraping...",
        },
      );

      var success = 0;
      var error = 0;
      var pending = gamesToScrape.length;
      final scraper = Scraper(userName: username ?? "", userPassword: password ?? "");
      for (var game in gamesToScrape) {
        try {
          final scrapedGame = await scraper.scrape(game, (msg) {
            service.invoke(
              'update',
              {
                "total": gamesToScrape.length,
                "success": success,
                "error": error,
                "pending": pending,
                "system": game.system.id,
                "rom": game.rom,
                "msg": msg,
              },
            );
          });
          service.invoke(
            'update',
            {
              "total": gamesToScrape.length,
              "success": success,
              "error": error,
              "pending": pending,
              "system": game.system.id,
              "rom": game.rom,
              "msg": "Writing gamelist.xml...",
            },
          );
          await updateGameInGamelistXml(scrapedGame);
          success++;
        } on DoneForTheDayException {
          debugPrint("Error scraping ${game.rom}: Done for the day");
          error++;
          service.invoke(
            'update',
            {
              "total": gamesToScrape.length,
              "success": success,
              "error": error,
              "pending": pending,
              "system": "",
              "rom": "",
              "msg": "Quota exceeded",
            },
          );
          return;
        } catch (e) {
          debugPrint("Error scraping ${game.rom}: $e");
          error++;
          service.invoke(
            'update',
            {
              "total": gamesToScrape.length,
              "success": success,
              "error": error,
              "pending": pending,
              "system": game.system.id,
              "rom": game.rom,
              "msg": "Error",
            },
          );
        }
        pending--;
      }
      service.invoke(
        'update',
        {
          "total": gamesToScrape.length,
          "success": success,
          "error": error,
          "pending": pending,
          "system": "",
          "rom": "",
          "msg": "Done",
        },
      );
    } finally {
      debugPrint("Stopping service...");
      service.stopSelf();
    }
  } catch (e, s) {
    debugPrint("Error scraping: $e, $s");
  }
}
