import 'dart:convert';
import 'dart:io';

import 'package:async_task/async_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xml/xml.dart';
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
        .map((node) => _fromNode(node, system, romsPath))
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

  final system = systems.firstWhere((element) => element.id == systemId);
  final favouritesMap = {for (var favourite in settings.favourites) favourite.romPath: favourite.favourite};

  for (var element in allGames) {
    element.favorite = favouritesMap[element.romPath] ?? element.favorite;
  }

  switch (system.id) {
    case "favourites":
      final games = allGames.where((element) => element.favorite).sortedBy((element) => element.name);
      final gamesInCollection = settings.uniqueGamesInCollections ? _uniqueGames(games) : games;
      return GameList(system, ".", gamesInCollection);
    case "recent":
      Map<String, int> recentGamesMap = {
        for (var item in recentGames) item.romPath: item.timestamp,
      };
      final games = allGames.where((element) => recentGamesMap.containsKey(element.romPath)).toList();
      games.sort((a, b) => recentGamesMap[b.romPath]!.compareTo(recentGamesMap[a.romPath]!));
      final gamesInCollection = settings.uniqueGamesInCollections ? _uniqueGames(games) : games;
      return GameList(system, ".", gamesInCollection);
    case "all":
      final games = _sortGames(settings, allGames);
      final gamesInCollection = settings.uniqueGamesInCollections ? _uniqueGames(games) : games;
      return GameList(system, ".", gamesInCollection);
    default:
      final games = _sortGames(settings, allGames.where((element) => element.system.id == system.id).toList());
      return GameList(system, ".", games);
  }
}

List<Game> _uniqueGames(List<Game> allGames) {
  final roms = <String>{};
  final uniqueGames = allGames.where((element) => !element.isFolder).toList();
  uniqueGames.retainWhere((game) => roms.add(game.uniqueKey));
  return uniqueGames;
}

List<Game> _sortGames(Settings settings, List<Game> allGames) {
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

Game _fromNode(XmlNode node, System system, String romsPath) {
  final id = node.attributes.firstWhereOrNull((element) => element.name.local == "id")?.value;
  final name = node.findElements("name").first.text;
  final path = node.findElements("path").first.text;
  final description = node.findElements("desc").firstOrNull?.text;
  final genre = node.findElements("genre").firstOrNull?.text;
  final genreid = node.findElements("genreid").firstOrNull?.text;
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
  return Game(system, name, romsPath, path.substring(0, path.lastIndexOf("/")), path,
      id: id,
      description: description,
      genre: genre,
      genreid: genreid,
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
