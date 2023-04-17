import 'dart:convert';
import 'dart:io';

import 'package:async_task/async_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';
import 'package:collection/collection.dart';

import 'repo.dart';
import 'emulators.dart';
import 'models.dart';
import 'systems.dart';

part 'games.g.dart';

class GameList {
  final System system;
  final String currentFolder;
  final List<Game> games;

  const GameList(this.system, this.currentFolder, this.games);
}

@Riverpod(keepAlive: true)
Future<List<Game>> allGames(AllGamesRef ref) async {
  final detectedSystems = await ref.watch(detectedSystemsProvider.future);
  final settings = await ref.watch(settingsProvider.future);

  final allGames = <Game>[];

  if (detectedSystems.isEmpty) {
    return [];
  }

  final favouritesMap = {for (var favourite in settings.favourites) favourite.romPath: favourite.favourite};

  var asyncExecutor = AsyncExecutor(
    sequential: false,
    parallelism: Platform.numberOfProcessors - 1,
    taskTypeRegister: _taskTypeRegister,
  );
  asyncExecutor.logger.enabled = true;
  try {
    List<GamelistParser> tasks = [];
    for (var system in detectedSystems) {
      final emulator = defaultEmulator(
          system.emulators, settings.perSystemConfigurations.firstWhereOrNull((e) => e.system == system.id));
      for (var romsFolder in settings.romsFolders) {
        for (var folder in system.folders) {
          tasks.add(GamelistParser(GamelistTaskParams(romsFolder, folder, system, emulator, favouritesMap)));
        }
      }
    }

    final futures = asyncExecutor.executeAll(tasks);
    final results = await Future.wait(futures);
    for (var r in results) {
      allGames.addAll(r);
    }
  } finally {
    asyncExecutor.close();
  }

  bool favouriteOnTop = settings.favouritesOnTop;
  final games = allGames.sorted((a, b) {
    // folders on top
    if (a.isFolder) {
      return -1;
    }
    if (b.isFolder) {
      return 1;
    }
    if (favouriteOnTop) {
      if (a.favorite && b.favorite) {
        return a.name.compareTo(b.name);
      }
      if (a.favorite) {
        return -1;
      }
      if (b.favorite) {
        return 1;
      }
    }
    return a.name.compareTo(b.name);
  });
  return games;
}

List<AsyncTask> _taskTypeRegister() => [GamelistParser(GamelistTaskParams("", "", systemAllGames, null, {}))];

class GamelistTaskParams {
  final String romsFolder;
  final String folder;
  final System system;
  final Emulator? emulator;
  final Map<String, bool> favouritesMap;

  GamelistTaskParams(this.romsFolder, this.folder, this.system, this.emulator, this.favouritesMap);
}

class GamelistParser extends AsyncTask<GamelistTaskParams, List<Game>> {
  final GamelistTaskParams params;

  GamelistParser(this.params);

  @override
  AsyncTask<GamelistTaskParams, List<Game>> instantiate(GamelistTaskParams parameters,
      [Map<String, SharedData>? sharedData]) {
    return GamelistParser(parameters);
  }

  @override
  GamelistTaskParams parameters() {
    return params;
  }

  @override
  FutureOr<List<Game>> run() async {
    return _processFolder(params.romsFolder, params.folder, params.system, params.emulator, params.favouritesMap);
  }
}

Future<List<Game>> _processFolder(
    String romsFolder, String folder, System system, Emulator? emulator, Map<String, bool> favouritesMap) async {
  final romsPath = "$romsFolder/$folder";
  final gamelistPath = "$romsPath/gamelist.xml";

  final file = File(gamelistPath);
  final exists = await file.exists();
  if (exists) {
    final games = await file
        .openRead()
        .transform(utf8.decoder)
        .toXmlEvents()
        .normalizeEvents()
        .selectSubtreeEvents((event) => event.name == 'game' || event.name == 'folder')
        .toXmlNodes()
        .expand((nodes) => nodes)
        .map((node) => _fromNode(node, system, emulator, romsPath))
        .toList();
    for (var game in games) {
      if (favouritesMap.containsKey(game.romPath)) {
        game.favorite = favouritesMap[game.romPath]!;
      }
    }
    return games;
  }
  return [];
}

@Riverpod(keepAlive: true)
Future<GameList> games(GamesRef ref, String systemId) async {
  final allGames = await ref.watch(allGamesProvider.future);
  final detectedSystems = await ref.watch(detectedSystemsProvider.future);
  final system = detectedSystems.firstWhere((element) => element.id == systemId);

  switch (systemId) {
    case "favourites":
      return GameList(system, ".", allGames.where((element) => element.favorite).toList());
    case "recent":
      final recentGames = await ref.watch(recentGamesProvider.future);
      Map<String, int> recentGamesMap = {
        for (var item in recentGames) item.romPath: item.timestamp,
      };
      final games = allGames.where((element) => recentGamesMap.containsKey(element.romPath)).toList();
      games.sort((a, b) => recentGamesMap[b.romPath]!.compareTo(recentGamesMap[a.romPath]!));
      return GameList(system, ".", games);
    case "all":
      return GameList(system, ".", allGames);
    default:
      return GameList(system, ".", allGames.where((element) => element.system.id == systemId).toList());
  }
}

Game _fromNode(XmlNode node, System system, Emulator? emulator, String romsPath) {
  final name = node.findElements("name").first.text;
  final path = node.findElements("path").first.text;
  final description = node.findElements("desc").firstOrNull?.text;
  final genre = node.findElements("genre").firstOrNull?.text;
  final developer = node.findElements("developer").firstOrNull?.text;
  final publisher = node.findElements("publisher").firstOrNull?.text;
  final players = node.findElements("players").firstOrNull?.text;
  final ratingString = node.findElements("rating").firstOrNull?.text;
  final rating = ratingString != null ? double.tryParse(ratingString) : null;
  final yearString = node.findElements("releasedate").firstOrNull?.text;
  final year = yearString != null && yearString.length > 4 ? int.parse(yearString.substring(0, 4)) : null;
  final image = node.findElements("image").firstOrNull?.text;
  final video = node.findElements("video").firstOrNull?.text;
  final thumbnail = node.findElements("thumbnail").firstOrNull?.text;
  final favorite = node.findElements("favorite").firstOrNull?.text == "true";
  return Game(system, emulator, name, romsPath, path.substring(0, path.lastIndexOf("/")), path,
      description: description,
      genre: genre,
      rating: rating != null ? 10 * rating : null,
      imageUrl: image != null ? "$romsPath/$image" : null,
      videoUrl: video != null ? "$romsPath/$video" : null,
      thumbnailUrl: thumbnail != null ? "$romsPath/$thumbnail" : null,
      developer: developer,
      publisher: publisher,
      players: players,
      year: year,
      favorite: favorite,
      isFolder: node is XmlElement && node.name.local == "folder");
}
