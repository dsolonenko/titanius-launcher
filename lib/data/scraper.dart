import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenscraper/screenscraper.dart'
    show
        DoNotRetryException,
        DoneForTheDayException,
        MediaLink,
        RomScraper,
        ScreenScraperException;
import 'package:titanius/data/env.dart';
import 'package:titanius/data/files.dart';
import 'package:titanius/data/gamelist_xml.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/widgets/scraper_progress.dart';
import 'package:retry/retry.dart';

const scraperRegionOptions = ["us", "eu", "jp", "wor"];
const scraperRegionLabels = ["US", "EU", "JP", "World"];

List<String> getScraperRegionPriority(String? regionId) {
  switch (regionId?.toLowerCase()) {
    case "eu":
      return ["eu", "wor", "us", "jp"];
    case "jp":
      return ["jp", "wor", "us", "eu"];
    case "wor":
      return ["wor", "us", "eu", "jp"];
    case "us":
    default:
      return ["us", "wor", "eu", "jp"];
  }
}

class Scraper {
  final RomScraper _scraper;
  final dio = Dio();

  Scraper({
    required String userName,
    required String userPassword,
    List<String>? regionPriority,
  }) : _scraper = RomScraper(
         devId: Env.devId,
         devPassword: Env.devPassword,
         softwareName: Env.appName,
         userName: userName,
         userPassword: userPassword,
         regionPriority: regionPriority,
         httpLogging: true,
       );

  Future<Game> scrape(
    Game rom,
    void Function(String msg) progress, {
    int? gameId,
  }) async {
    progress("Scraping...");
    const r = RetryOptions(maxAttempts: 5, delayFactor: Duration(seconds: 1));
    final game = await r.retry(
      () => gameId != null
          ? _scraper.scrapeGame(
              systemId: rom.system.screenScraperId,
              gameId: gameId,
            )
          : _scraper.scrapeRom(
              systemId: rom.system.screenScraperId,
              romPath: rom.absoluteRomPath,
            ),
      retryIf: (e) => _canRetryScraper(e),
    );
    debugPrint("ScreenScraper ID for ${rom.absoluteRomPath} is ${game.gameId}");
    final file = File(rom.absoluteRomPath);
    final fileName = file.uri.pathSegments.last;
    final fileNameNoExt = fileName.contains(".")
        ? fileName.substring(0, fileName.lastIndexOf("."))
        : fileName;
    final romsPath = "${rom.volumePath}/${rom.systemFolder}";
    var imageUrl = rom.imageUrl;
    if (game.media.screenshot != null) {
      progress("Downloading screenshot...");
      imageUrl = await r.retry(
        () => _downloadMedia(
          game.media.screenshot!,
          fileNameNoExt,
          "$romsPath/media/images",
        ),
        retryIf: (e) => _canRetryScraper(e),
      );
    }
    var videoUrl = rom.videoUrl;
    if (game.media.videoNormalized != null) {
      progress("Downloading video...");
      videoUrl = await r.retry(
        () => _downloadMedia(
          game.media.videoNormalized!,
          fileNameNoExt,
          "$romsPath/media/videos",
        ),
        retryIf: (e) => _canRetryScraper(e),
      );
    }
    var thumbnailUrl = rom.thumbnailUrl;
    if (game.media.wheel != null) {
      progress("Downloading wheel...");
      thumbnailUrl = await r.retry(
        () => _downloadMedia(
          game.media.wheel!,
          fileNameNoExt,
          "$romsPath/media/wheels",
        ),
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

  Future<String?> _downloadMedia(
    MediaLink mediaLink,
    String fileNameNoExt,
    String destinationFolder,
  ) async {
    final mediaName = "$fileNameNoExt.${mediaLink.format}";
    debugPrint("Downloading $destinationFolder/$mediaName");
    final newFilePath = "$destinationFolder/$mediaName";
    final newFile = File(newFilePath);
    newFile.parent.createSync(recursive: true);
    final response = await dio.download(
      mediaLink.url,
      "$destinationFolder/$mediaName",
    );
    debugPrint("Response: ${response.statusCode} ${response.statusMessage}");
    if (response.statusCode == 200) {
      return newFile.absolute.path;
    } else {
      throw ScreenScraperException.fromHttpResponse(
        response.statusCode ?? 401,
        response.data.toString(),
      );
    }
  }

  void close() {
    _scraper.close();
  }
}

bool _canRetryScraper(Exception e) {
  return !(e is DoNotRetryException || e is DoneForTheDayException);
}

final scraperProvider = FutureProvider<Scraper>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final scraper = Scraper(
    userName: settings.screenScraperUser ?? "",
    userPassword: settings.screenScraperPwd ?? "",
    regionPriority: getScraperRegionPriority(settings.scraperRegion),
  );
  return scraper;
});

abstract class ScraperService {
  Stream<ScraperProgress> get progressStream;
  Future<bool> isRunning();
  Future<void> startScrape({
    required String? username,
    required String? password,
    required String? region,
    required List<String> romFolders,
    required List<Game> roms,
    required List<System> systems,
    required String scrapeTheseGames,
  });
  Future<void> stopScrape();
}

class ForegroundScraperService implements ScraperService {
  final _progressController = StreamController<ScraperProgress>.broadcast();

  ForegroundScraperService() {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      _progressController.add(ScraperProgress.fromJson(map));
    }
  }

  @override
  Stream<ScraperProgress> get progressStream => _progressController.stream;

  @override
  Future<bool> isRunning() => FlutterForegroundTask.isRunningService;

  @override
  Future<void> startScrape({
    required String? username,
    required String? password,
    required String? region,
    required List<String> romFolders,
    required List<Game> roms,
    required List<System> systems,
    required String scrapeTheseGames,
  }) async {
    if (await isRunning()) {
      debugPrint("Scraper is already running");
      return;
    }

    await FlutterForegroundTask.requestNotificationPermission();

    final result = await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.dataSync],
      notificationTitle: 'Titanius Scraper',
      notificationText: 'Starting scraper...',
      notificationButtons: [const NotificationButton(id: 'stop', text: 'Stop')],
      callback: startScraperServiceCallback,
    );

    if (result is ServiceRequestFailure) {
      debugPrint("Failed to start scraper service: ${result.error}");
      return;
    }

    FlutterForegroundTask.sendDataToTask({
      'action': 'scrape',
      'username': username,
      'password': password,
      'region': region,
      'romFolders': romFolders,
      'roms': roms.map((e) => e.toJson()).toList(),
      'systems': systems.map((e) => e.toJson()).toList(),
      'scrapeTheseGames': scrapeTheseGames,
    });
  }

  @override
  Future<void> stopScrape() async {
    FlutterForegroundTask.sendDataToTask({'action': 'stop'});
  }
}

class DesktopScraperService implements ScraperService {
  final _progressController = StreamController<ScraperProgress>.broadcast();
  bool _running = false;
  CancellationToken? _cancellationToken;

  @override
  Stream<ScraperProgress> get progressStream => _progressController.stream;

  @override
  Future<bool> isRunning() async => _running;

  @override
  Future<void> startScrape({
    required String? username,
    required String? password,
    required String? region,
    required List<String> romFolders,
    required List<Game> roms,
    required List<System> systems,
    required String scrapeTheseGames,
  }) async {
    if (_running) return;
    _running = true;
    _cancellationToken = CancellationToken();

    unawaited(
      scrapeGames(
        username: username,
        password: password,
        region: region,
        romFolders: romFolders,
        roms: roms,
        systems: systems,
        scrapeTheseGames: scrapeTheseGames,
        cancellationToken: _cancellationToken,
        onProgress: (update) {
          final progress = ScraperProgress.fromJson(update);
          if (!progress.isRunning) {
            _running = false;
          }
          _progressController.add(progress);
        },
      ).whenComplete(() {
        _running = false;
      }),
    );
  }

  @override
  Future<void> stopScrape() async {
    _cancellationToken?.cancel();
    _running = false;
    _progressController.add(
      ScraperProgress(
        total: 0,
        pending: 0,
        success: 0,
        error: 0,
        system: "",
        rom: "",
        message: "Cancelled",
      ),
    );
  }
}

final scraperServiceProvider = Provider<ScraperService>((ref) {
  if (Platform.isAndroid) {
    return ForegroundScraperService();
  } else {
    return DesktopScraperService();
  }
});

@pragma('vm:entry-point')
void startScraperServiceCallback() {
  FlutterForegroundTask.setTaskHandler(ScraperTaskHandler());
}

class ScraperTaskHandler extends TaskHandler {
  CancellationToken? _cancellationToken;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final action = map['action'] as String?;

      if (action == 'scrape') {
        _cancellationToken?.cancel();
        final cancellationToken = CancellationToken();
        _cancellationToken = cancellationToken;

        final username = map['username'] as String?;
        final password = map['password'] as String?;
        final region = map['region'] as String?;
        final romFolders = (map['romFolders'] as List)
            .map((e) => e.toString())
            .toList();
        final roms = (map['roms'] as List)
            .map(
              (e) => e is Game
                  ? e
                  : Game.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        final systems = (map['systems'] as List)
            .map(
              (e) => e is System
                  ? e
                  : System.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        final scrapeTheseGames = map['scrapeTheseGames'] as String;

        scrapeGames(
          username: username,
          password: password,
          region: region,
          romFolders: romFolders,
          roms: roms,
          systems: systems,
          scrapeTheseGames: scrapeTheseGames,
          cancellationToken: cancellationToken,
          onProgress: (update) {
            FlutterForegroundTask.sendDataToMain(update);
            final msg = update['msg'] as String? ?? '';
            final system = update['system'] as String? ?? '';
            final rom = update['rom'] as String? ?? '';
            String notifText;
            if (system.isNotEmpty && rom.isNotEmpty) {
              notifText = "$system: $rom ($msg)";
            } else if (msg.isNotEmpty) {
              notifText = msg;
            } else {
              notifText = "Scraping...";
            }
            FlutterForegroundTask.updateService(
              notificationTitle: 'Titanius Scraper',
              notificationText: notifText,
            );
          },
        ).whenComplete(() {
          FlutterForegroundTask.stopService();
        });
      } else if (action == 'stop') {
        _cancellationToken?.cancel();
        FlutterForegroundTask.sendDataToMain({
          "total": 0,
          "success": 0,
          "error": 0,
          "pending": 0,
          "system": "",
          "rom": "",
          "msg": "Cancelled",
        });
        FlutterForegroundTask.stopService();
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      _cancellationToken?.cancel();
      FlutterForegroundTask.sendDataToMain({
        "total": 0,
        "success": 0,
        "error": 0,
        "pending": 0,
        "system": "",
        "rom": "",
        "msg": "Cancelled",
      });
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _cancellationToken?.cancel();
  }
}

Future<void> scrapeGames({
  required String? username,
  required String? password,
  required String? region,
  required List<String> romFolders,
  required List<Game> roms,
  required List<System> systems,
  required String scrapeTheseGames,
  required void Function(Map<String, dynamic> update) onProgress,
  CancellationToken? cancellationToken,
}) async {
  try {
    final romsMap = {for (var rom in roms) rom.absoluteRomPath: rom};
    debugPrint(
      "Scraping $scrapeTheseGames for ${systems.length} systems with ${roms.length} existing roms...",
    );
    onProgress({
      "total": 0,
      "success": 0,
      "error": 0,
      "pending": 0,
      "system": "",
      "rom": "",
      "msg": "Starting...",
    });

    final gamesToScrape = <Game>[];
    for (var system in systems) {
      if (cancellationToken?.isCancelled ?? false) break;
      for (var romsFolder in romFolders) {
        if (cancellationToken?.isCancelled ?? false) break;
        for (var folder in system.folders) {
          if (cancellationToken?.isCancelled ?? false) break;
          onProgress({
            "total": 0,
            "success": 0,
            "error": 0,
            "pending": gamesToScrape.length,
            "system": "",
            "rom": "",
            "msg": "Discovering...",
          });
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

    if (cancellationToken?.isCancelled ?? false) {
      debugPrint("Scraping cancelled during discovery");
      onProgress({
        "total": 0,
        "success": 0,
        "error": 0,
        "pending": 0,
        "system": "",
        "rom": "",
        "msg": "Cancelled",
      });
      return;
    }

    onProgress({
      "total": gamesToScrape.length,
      "success": 0,
      "error": 0,
      "pending": gamesToScrape.length,
      "system": "",
      "rom": "",
      "msg": "Scraping...",
    });

    var success = 0;
    var error = 0;
    var pending = gamesToScrape.length;
    final scraper = Scraper(
      userName: username ?? "",
      userPassword: password ?? "",
      regionPriority: getScraperRegionPriority(region),
    );
    for (var game in gamesToScrape) {
      if (cancellationToken?.isCancelled ?? false) {
        debugPrint("Scraping cancelled by user");
        break;
      }
      try {
        final scrapedGame = await scraper.scrape(game, (msg) {
          onProgress({
            "total": gamesToScrape.length,
            "success": success,
            "error": error,
            "pending": pending,
            "system": game.system.id,
            "rom": game.rom,
            "msg": msg,
          });
        });
        onProgress({
          "total": gamesToScrape.length,
          "success": success,
          "error": error,
          "pending": pending,
          "system": game.system.id,
          "rom": game.rom,
          "msg": "Writing gamelist.xml...",
        });
        await updateGameInGamelistXml(scrapedGame);
        success++;
      } on DoneForTheDayException {
        debugPrint("Error scraping ${game.rom}: Done for the day");
        error++;
        onProgress({
          "total": gamesToScrape.length,
          "success": success,
          "error": error,
          "pending": pending,
          "system": "",
          "rom": "",
          "msg": "Quota exceeded",
        });
        return;
      } catch (e, st) {
        debugPrint("Error scraping ${game.rom}: $e\n$st");
        error++;
        onProgress({
          "total": gamesToScrape.length,
          "success": success,
          "error": error,
          "pending": pending,
          "system": game.system.id,
          "rom": game.rom,
          "msg": "Error",
        });
      }
      pending--;
    }

    if (cancellationToken?.isCancelled ?? false) {
      onProgress({
        "total": gamesToScrape.length,
        "success": success,
        "error": error,
        "pending": 0,
        "system": "",
        "rom": "",
        "msg": "Cancelled",
      });
    } else {
      onProgress({
        "total": gamesToScrape.length,
        "success": success,
        "error": error,
        "pending": pending,
        "system": "",
        "rom": "",
        "msg": "Done",
      });
    }
  } catch (e, s) {
    debugPrint("Error scraping: $e, $s");
  }
}
