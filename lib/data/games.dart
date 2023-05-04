import 'dart:convert';
import 'dart:io';

import 'package:async_task/async_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xml/xml_events.dart';
import 'package:collection/collection.dart';

import 'repo.dart';
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
  final romFolders = await ref.watch(romFoldersProvider.future);

  final allGames = <Game>[];

  if (detectedSystems.isEmpty) {
    return [];
  }

  var asyncExecutor = AsyncExecutor(
    sequential: false,
    parallelism: Platform.numberOfProcessors - 1,
    taskTypeRegister: _taskTypeRegister,
  );
  asyncExecutor.logger.enabled = true;
  try {
    List<GamelistParser> tasks = [];
    for (var system in detectedSystems) {
      for (var romsFolder in romFolders) {
        for (var folder in system.folders) {
          tasks.add(GamelistParser(GamelistTaskParams(romsFolder, folder, system)));
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

  return allGames;
}

List<AsyncTask> _taskTypeRegister() => [GamelistParser(GamelistTaskParams("", "", systemAllGames))];

class GamelistTaskParams {
  final String romsFolder;
  final String folder;
  final System system;

  GamelistTaskParams(this.romsFolder, this.folder, this.system);
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
    return _processFolder(params.romsFolder, params.folder, params.system);
  }
}

Future<List<Game>> _processFolder(String romsFolder, String folder, System system) async {
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
        .map((node) => Game.fromXmlNode(node, system, romsPath))
        .toList();
    return games;
  }
  return [];
}

@Riverpod(keepAlive: true)
Future<GameList> games(GamesRef ref, String systemId) async {
  final allGames = await ref.watch(allGamesProvider.future);
  final systems = await ref.watch(allSupportedSystemsProvider.future);
  final settings = await ref.watch(settingsProvider.future);
  final recentGames = await ref.watch(recentGamesProvider.future);

  final system = systems.firstWhere((system) => system.id == systemId);
  final favouritesMap = {for (var favourite in settings.favourites) favourite.romPath: favourite.favourite};

  for (var game in allGames) {
    game.favorite = favouritesMap[game.romPath] ?? game.favorite;
  }

  switch (system.id) {
    case "favourites":
      final games = allGames.where((game) => game.favorite).sortedBy((game) => game.name);
      final gamesInCollection = settings.uniqueGamesInCollections ? _uniqueGames(games) : games;
      return GameList(system, ".", gamesInCollection);
    case "recent":
      Map<String, int> recentGamesMap = {
        for (var item in recentGames) item.romPath: item.timestamp,
      };
      final games = allGames.where((game) => recentGamesMap.containsKey(game.romPath)).toList();
      games.sort((a, b) => recentGamesMap[b.romPath]!.compareTo(recentGamesMap[a.romPath]!));
      final gamesInCollection = settings.uniqueGamesInCollections ? _uniqueGames(games) : games;
      return GameList(system, ".", gamesInCollection);
    case "all":
      final gamesButNotFolders = allGames.where((game) => !game.isFolder).toList();
      final games = settings.uniqueGamesInCollections ? _uniqueGames(gamesButNotFolders) : gamesButNotFolders;
      final gamesInCollection = _sortGames(settings, games);
      return GameList(system, ".", gamesInCollection);
    default:
      final games = _sortGames(settings, allGames.where((game) => game.system.id == system.id).toList());
      return GameList(system, ".", games);
  }
}

List<Game> _uniqueGames(List<Game> allGames) {
  final roms = <String>{};
  final uniqueGames = [...allGames];
  uniqueGames.retainWhere((game) => roms.add(game.uniqueKey));
  return uniqueGames;
}

List<Game> _sortGames(Settings settings, List<Game> allGames) {
  bool favouriteOnTop = settings.favouritesOnTop;
  final games = allGames.sorted((a, b) {
    // folders on top
    if (a.isFolder && b.isFolder) {
      return a.name.compareTo(b.name);
    }
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
