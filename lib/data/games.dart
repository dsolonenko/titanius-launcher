import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isolated_worker/isolated_worker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xml/xml_events.dart';
import 'package:collection/collection.dart';

import 'package:titanius/data/repo.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/data/files.dart';

part 'games.g.dart';

class GameList {
  final System system;
  final String currentFolder;
  final List<Game> games;
  final int Function(Game, Game)? compare;

  const GameList(this.system, this.currentFolder, this.games, this.compare);
}

@Riverpod(keepAlive: true)
Future<List<System>> loadedSystems(LoadedSystemsRef ref) async {
  final allSystems = await ref.watch(detectedSystemsProvider.future);
  final allGames = await ref.watch(allGamesProvider.future);
  final Set<String> systems = {};
  for (var game in allGames) {
    systems.add(game.system.id);
  }
  final loadedSystems = [
    for (final system in allSystems)
      if (system.id == "android" || system.isCollection || systems.contains(system.id)) system
  ];
  return loadedSystems;
}

@Riverpod(keepAlive: true)
Future<List<Game>> allGames(AllGamesRef ref) async {
  final detectedSystems = await ref.watch(detectedSystemsProvider.future);
  final romFolders = await ref.watch(romFoldersProvider.future);

  final settings = await ref.read(settingsProvider.future);
  final onlyGamelistRoms = settings.showOnlyGamelistRoms;

  final allGames = <Game>[];

  if (detectedSystems.isEmpty) {
    return [];
  }

  final stopwatch = Stopwatch()..start();

  try {
    List<Future<List<Game>>> tasks = [];
    for (var system in detectedSystems) {
      for (var romsFolder in romFolders) {
        for (var folder in system.folders) {
          final task =
              IsolatedWorker().run(_processFolder, GamelistTaskParams(romsFolder, folder, system, onlyGamelistRoms));
          tasks.add(task);
        }
      }
    }

    final results = await Future.wait(tasks);
    for (var r in results) {
      allGames.addAll(r);
    }
  } finally {
    stopwatch.stop();
    debugPrint("Games fetching took ${stopwatch.elapsedMilliseconds}ms. onlyGamelistRoms=$onlyGamelistRoms");
  }

  return allGames;
}

class GamelistTaskParams {
  final String romsFolder;
  final String folder;
  final System system;
  final bool onlyGamelistRoms;

  GamelistTaskParams(this.romsFolder, this.folder, this.system, this.onlyGamelistRoms);
}

Future<List<Game>> _processFolder(GamelistTaskParams params) async {
  try {
    final romsPath = "${params.romsFolder}/${params.folder}";
    final pathExists = await Directory(romsPath).exists();
    if (!pathExists) {
      return [];
    }
    final List<Game> gamesFromFiles = params.onlyGamelistRoms
        ? []
        : await listGamesFromFiles(
            romsFolder: params.romsFolder,
            folder: params.folder,
            system: params.system,
          );
    final file = File("$romsPath/gamelist.xml");
    final exists = await file.exists();
    if (exists) {
      final gamesFromGamelistXml = await file
          .openRead()
          .transform(utf8.decoder)
          .toXmlEvents()
          .normalizeEvents()
          .selectSubtreeEvents((event) => event.name == 'game' || event.name == 'folder')
          .toXmlNodes()
          .expand((nodes) => nodes)
          .map((node) => Game.fromXmlNode(node, params.system, params.romsFolder, params.folder))
          .toList();
      if (params.onlyGamelistRoms) {
        return gamesFromGamelistXml;
      }
      final romsMap = {for (var rom in gamesFromGamelistXml) rom.absoluteRomPath: rom};
      final List<Game> games = [];
      for (var g in gamesFromFiles) {
        final game = romsMap[g.absoluteRomPath];
        if (game != null) {
          games.add(game);
        } else {
          games.add(g);
        }
      }
      return games;
    } else {
      return gamesFromFiles;
    }
  } catch (e) {
    debugPrint("Error processing folder ${params.folder}: $e");
    return [];
  }
}

@Riverpod(keepAlive: true)
Future<GameList> games(GamesRef ref, String systemId) async {
  final allGamelistGames = await ref.watch(allGamesProvider.future);
  final systems = await ref.watch(allSupportedSystemsProvider.future);
  final settings = await ref.watch(settingsProvider.future);
  final recentGames = await ref.watch(recentGamesProvider.future);

  final system = systems.firstWhere((system) => system.id == systemId);

  final allGames = [...allGamelistGames];
  if (!settings.showHiddenGames) {
    allGames.removeWhere((game) => game.hidden);
  }

  switch (system.id) {
    case "favourites":
      compare(Game a, Game b) => a.name.compareTo(b.name);
      final games = allGames.where((game) => game.favorite).sorted(compare);
      final gamesInCollection = settings.uniqueGamesInCollections ? _uniqueGames(games) : games;
      return GameList(system, ".", gamesInCollection, (a, b) => a.name.compareTo(b.name));
    case "recent":
      Map<String, int> recentGamesMap = {
        for (var item in recentGames) item.romPath: item.timestamp,
      };
      compare(Game a, Game b) => recentGamesMap[b.romPath]!.compareTo(recentGamesMap[a.romPath]!);
      final games = allGames.where((game) => recentGamesMap.containsKey(game.romPath)).sorted(compare);
      final gamesInCollection = settings.uniqueGamesInCollections ? _uniqueGames(games) : games;
      return GameList(
        system,
        ".",
        gamesInCollection,
        compare,
      );
    case "all":
      final sorter = GameSorter(settings);
      final gamesButNotFolders = allGames.where((game) => !game.isFolder).toList();
      final games = settings.uniqueGamesInCollections ? _uniqueGames(gamesButNotFolders) : gamesButNotFolders;
      final gamesInCollection = _sortGames(settings, games);
      return GameList(system, ".", gamesInCollection, sorter.compare);
    default:
      final sorter = GameSorter(settings);
      final games = _sortGames(settings, allGames.where((game) => game.system.id == system.id).toList());
      return GameList(system, ".", games, sorter.compare);
  }
}

List<Game> _uniqueGames(List<Game> allGames) {
  final roms = <String>{};
  final uniqueGames = [...allGames];
  uniqueGames.retainWhere((game) => roms.add(game.uniqueKey));
  return uniqueGames;
}

List<Game> _sortGames(Settings settings, List<Game> allGames) {
  final sorter = GameSorter(settings);
  return allGames.sorted(sorter.compare);
}

class GameSorter {
  final Settings settings;

  GameSorter(this.settings);

  int compare(Game a, Game b) {
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
    if (settings.favouritesOnTop) {
      if (a.favorite && b.favorite) {
        final c = a.name.compareTo(b.name);
        if (c == 0) {
          return a.romPath.compareTo(b.romPath);
        } else {
          return c;
        }
      }
      if (a.favorite) {
        return -1;
      }
      if (b.favorite) {
        return 1;
      }
    }
    final c = a.name.compareTo(b.name);
    if (c == 0) {
      return a.romPath.compareTo(b.romPath);
    } else {
      return c;
    }
  }
}
