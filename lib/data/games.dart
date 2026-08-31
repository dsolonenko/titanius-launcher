import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xml/xml_events.dart';
import 'package:collection/collection.dart';

import 'package:titanius/data/repo.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/data/files.dart';

class GameList {
  final System system;
  final String currentFolder;
  final List<Game> games;
  final int Function(Game, Game)? compare;
  final Map<int, int> _indexByHash;

  GameList(this.system, this.currentFolder, this.games, this.compare) : _indexByHash = _buildIndex(games);

  static Map<int, int> _buildIndex(List<Game> games) {
    final result = <int, int>{};
    for (var index = 0; index < games.length; index++) {
      result.putIfAbsent(games[index].hash, () => index);
    }
    return result;
  }

  int indexOf(Game game) => _indexByHash[game.hash] ?? -1;
}

final loadedSystemsProvider = FutureProvider<List<System>>((ref) async {
  final allSystemsFuture = ref.watch(detectedSystemsProvider.future);
  final romFoldersFuture = ref.watch(romFoldersProvider.future);
  final allSystems = await allSystemsFuture;
  final romFolders = await romFoldersFuture;
  final availability = await Future.wait(
      allSystems.map((system) async => MapEntry(system, await hasSystemFolder(system, romFolders))));
  return [for (final entry in availability) if (entry.value) entry.key];
});

Future<bool> hasSystemFolder(System system, List<String> romFolders) async {
  if (system.isAndroid || system.isCollection) return true;
  for (final romsFolder in romFolders) {
    for (final folder in system.folders) {
      if (await Directory('$romsFolder/$folder').exists()) return true;
    }
  }
  return false;
}

class _GameLoadCoordinator {
  _GameLoadCoordinator(this.maxConcurrent);

  final int maxConcurrent;
  final List<Completer<void>> _waiters = [];
  int _active = 0;

  Future<T> run<T>(Future<T> Function() operation) async {
    if (_active >= maxConcurrent) {
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
    _active++;
    try {
      return await operation();
    } finally {
      _active--;
      if (_waiters.isNotEmpty) _waiters.removeAt(0).complete();
    }
  }
}

typedef SystemGamesLoader = Future<List<Game>> Function(SystemGamesTaskParams params);

class GameLibrary {
  GameLibrary({int maxConcurrent = 2, SystemGamesLoader? loader})
      : _coordinator = _GameLoadCoordinator(maxConcurrent),
        _loader = loader ?? _loadSystemInIsolate;

  final _GameLoadCoordinator _coordinator;
  final SystemGamesLoader _loader;
  final Map<String, ({Object token, Future<List<Game>> future})> _cache = {};

  Future<List<Game>> load(SystemGamesTaskParams params) {
    final key = _key(params);
    final cached = _cache[key];
    if (cached != null) return cached.future;
    // A system should retain only the active roots/settings variant.
    invalidateSystem(params.system.id);
    final token = Object();
    final future = _load(key, token, params);
    _cache[key] = (token: token, future: future);
    return future;
  }

  Future<List<Game>> _load(String key, Object token, SystemGamesTaskParams params) async {
    try {
      return await _coordinator.run(() => _loader(params));
    } catch (_) {
      if (identical(_cache[key]?.token, token)) _cache.remove(key);
      rethrow;
    }
  }

  void invalidateSystem(String systemId) {
    _cache.removeWhere((key, _) => key.startsWith('$systemId\u0001'));
  }

  void clear() => _cache.clear();

  String _key(SystemGamesTaskParams params) =>
      '${params.system.id}\u0001${params.onlyGamelistRoms}\u0001${params.romFolders.join('\u0000')}';
}

Future<List<Game>> _loadSystemInIsolate(SystemGamesTaskParams params) =>
    Isolate.run(() => _processSystem(params));

final gameLibraryProvider = Provider((ref) => GameLibrary());

final systemGamesProvider = FutureProvider.family<List<Game>, String>((ref, systemId) async {
  final systemsFuture = ref.watch(detectedSystemsProvider.future);
  final romFoldersFuture = ref.watch(romFoldersProvider.future);
  final onlyGamelistRomsFuture =
      ref.watch(settingsProvider.selectAsync((settings) => settings.showOnlyGamelistRoms));
  final library = ref.watch(gameLibraryProvider);
  final systems = await systemsFuture;
  final romFolders = await romFoldersFuture;
  final onlyGamelistRoms = await onlyGamelistRomsFuture;
  final system = systems.firstWhereOrNull((system) => system.id == systemId);
  if (system == null || system.isCollection || system.isAndroid) return [];
  final params = SystemGamesTaskParams(romFolders, system, onlyGamelistRoms);
  return library.load(params);
});

final allGamesProvider = FutureProvider<List<Game>>((ref) async {
  final detectedSystemsFuture = ref.watch(detectedSystemsProvider.future);
  final romFoldersFuture = ref.watch(romFoldersProvider.future);
  final onlyGamelistRomsFuture =
      ref.watch(settingsProvider.selectAsync((settings) => settings.showOnlyGamelistRoms));
  final library = ref.watch(gameLibraryProvider);
  final detectedSystems = await detectedSystemsFuture;
  final romFolders = await romFoldersFuture;
  final onlyGamelistRoms = await onlyGamelistRomsFuture;
  final systems = detectedSystems.where((system) => !system.isCollection && !system.isAndroid);
  final results = await Future.wait([
    for (final system in systems)
      library.load(SystemGamesTaskParams(romFolders, system, onlyGamelistRoms))
  ]);
  return [for (final games in results) ...games];
});

class SystemGamesTaskParams {
  final List<String> romFolders;
  final System system;
  final bool onlyGamelistRoms;
  SystemGamesTaskParams(this.romFolders, this.system, this.onlyGamelistRoms);
}

Future<List<Game>> _processSystem(SystemGamesTaskParams params) async {
  final games = <Game>[];
  final stopwatch = Stopwatch()..start();
  try {
    for (final root in params.romFolders) {
      for (final folder in params.system.folders) {
        games.addAll(await _processFolder(GamelistTaskParams(root, folder, params.system, params.onlyGamelistRoms)));
      }
    }
  } finally {
    stopwatch.stop();
    debugPrint('${params.system.id}: loaded ${games.length} games in ${stopwatch.elapsedMilliseconds}ms');
  }
  return games;
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
    final file = File("$romsPath/gamelist.xml");
    final exists = await file.exists();
    final gamesFromGamelistXml = exists
        ? await file
          .openRead()
          .transform(utf8.decoder)
          .toXmlEvents()
          .normalizeEvents()
          .selectSubtreeEvents((event) => event.name == 'game' || event.name == 'folder')
          .toXmlNodes()
          .expand((nodes) => nodes)
          .map((node) => Game.fromXmlNode(node, params.system, params.romsFolder, params.folder))
          .toList()
        : <Game>[];
    if (params.onlyGamelistRoms) return gamesFromGamelistXml;
    final romsMap = {for (final rom in gamesFromGamelistXml) rom.absoluteRomPath: rom};
    final games = <Game>[];
    await for (final game in streamGamesFromFiles(
        romsFolder: params.romsFolder,
        folder: params.folder,
        system: params.system)) {
      games.add(romsMap[game.absoluteRomPath] ?? game);
    }
    return games;
  } catch (e) {
    debugPrint("Error processing folder ${params.folder}: $e");
    return [];
  }
}

final gamesProvider = FutureProvider.family<GameList, String>((ref, systemId) async {
  final isCollection = collections.any((c) => c.id == systemId);
  final sourceProvider = isCollection ? allGamesProvider : systemGamesProvider(systemId);
  final systemsFuture = ref.watch(allSupportedSystemsProvider.future);
  final settingsFuture = ref.watch(settingsProvider.future);
  final recentGamesFuture = ref.watch(recentGamesProvider.future);
  final sourceGamesFuture = ref.watch(sourceProvider.future);
  final systems = await systemsFuture;
  final settings = await settingsFuture;
  final recentGames = await recentGamesFuture;
  final sourceGames = await sourceGamesFuture;

  final system = systems.firstWhere((system) => system.id == systemId);

  final allGames = [...sourceGames];
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
    case "no_metadata":
      final sorter = GameSorter(settings);
      final gamesWithoutMetadata = allGames.where((game) => !game.isFolder && !game.hasMetadata).toList();
      final games = settings.uniqueGamesInCollections ? _uniqueGames(gamesWithoutMetadata) : gamesWithoutMetadata;
      final gamesInCollection = _sortGames(settings, games);
      return GameList(system, ".", gamesInCollection, sorter.compare);
    case "retroachievements":
      return GameList(system, ".", [], (a, b) => 0);
    default:
      final sorter = GameSorter(settings);
      final games = _sortGames(settings, allGames.where((game) => game.system.id == system.id).toList());
      return GameList(system, ".", games, sorter.compare);
  }
});

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
