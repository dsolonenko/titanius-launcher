import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:titanius/data/database.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/retroachievements_matcher.dart';
import 'package:titanius/data/storage.dart';

export 'package:drift/drift.dart' hide Column;
export 'package:titanius/data/database.dart';

class Settings {
  final Map<String, Setting> settings;

  Settings(this.settings);

  bool get favouritesOnTop => _getBoolean('favouritesOnTop', false);
  bool get showHiddenGames => _getBoolean('showHiddenGames', false);
  bool get showOnlyGamelistRoms => _getBoolean('showOnlyGamelistRoms', false);
  bool get uniqueGamesInCollections => _getBoolean('uniqueGamesInCollections', false);
  bool get compactGameList => _getBoolean('compactGameList', false);
  bool get showGameVideos => _getBoolean('showGameVideos', false);
  bool get fadeToVideo => _getBoolean('fadeToVideo', false);
  bool get muteVideo => _getBoolean('muteVideo', true);
  double get fontScale => _getDouble('fontScale', 1.0);
  ControllerLayout get controllerLayout => ControllerLayout.fromString(_getString('controllerLayout'));
  bool get swapConfirm => _getBoolean('swapConfirm', false);
  String? get daijishoWallpaperPack => _getString('daijishoWallpaperPack');
  String? get screenScraperUser => _getString('screenScraperUser');
  String? get screenScraperPwd => _getString('screenScraperPwd');
  String? get retroAchievementsUser => _getString('retroAchievementsUser');
  String? get retroAchievementsApiKey => _getString('retroAchievementsApiKey');
  bool get hasRetroAchievements =>
      retroAchievementsUser != null &&
      retroAchievementsUser!.trim().isNotEmpty &&
      retroAchievementsApiKey != null &&
      retroAchievementsApiKey!.trim().isNotEmpty;
  String? get scrapeTheseGames => _getString('scrapeTheseGames');
  List<String> get scrapeTheseSystems => _getStringList('scrapeTheseSystems');

  double _getDouble(String key, double defaultValue) {
    return settings.containsKey(key) ? double.tryParse(settings[key]!.value) ?? defaultValue : defaultValue;
  }

  bool _getBoolean(String key, bool defaultValue) {
    return settings.containsKey(key) ? settings[key]!.value == "true" : defaultValue;
  }

  String? _getString(String key) {
    return settings.containsKey(key) ? settings[key]!.value : null;
  }

  List<String> _getStringList(String key) {
    return settings.containsKey(key) ? settings[key]!.value.split(",") : [];
  }
}

class SettingsRepo {
  final AppDatabase db;

  SettingsRepo(this.db);

  Future<Settings> getSettings() async {
    final settingsList = await db.select(db.settingEntries).get();
    final settingsMap = {for (final s in settingsList) s.key: s};
    return Settings(settingsMap);
  }

  Future<void> setFavoutesOnTop(bool value) async {
    return _setBoolean('favouritesOnTop', value);
  }

  Future<void> setShowHiddenGames(bool value) async {
    return _setBoolean('showHiddenGames', value);
  }

  Future<void> setCheckMissingGames(bool value) async {
    return _setBoolean('checkMissingGames', value);
  }

  Future<void> setShowOnlyGamelistRoms(bool value) async {
    return _setBoolean('showOnlyGamelistRoms', value);
  }

  Future<void> setUniqueGamesInCollections(bool value) async {
    return _setBoolean('uniqueGamesInCollections', value);
  }

  Future<void> setCompactGameList(bool value) async {
    return _setBoolean('compactGameList', value);
  }

  Future<void> setShowGameVideos(bool value) async {
    return _setBoolean('showGameVideos', value);
  }

  Future<void> setFadeToVideo(bool value) async {
    return _setBoolean('fadeToVideo', value);
  }

  Future<void> setMuteVideo(bool value) async {
    return _setBoolean('muteVideo', value);
  }

  Future<void> setFontScale(double value) async {
    return _setSetting('fontScale', value.toStringAsFixed(1));
  }

  Future<void> setControllerLayout(ControllerLayout layout) async {
    return _setSetting('controllerLayout', layout.name);
  }

  Future<void> setSwapConfirm(bool value) async {
    return _setBoolean('swapConfirm', value);
  }

  Future<void> setDaijishoWallpaperPack(String value) async {
    return _setSetting('daijishoWallpaperPack', value);
  }

  Future<void> resetDaijishoWallpaperPack() async {
    return _resetSetting('daijishoWallpaperPack');
  }

  Future<void> setScreenScraperUser(String value) async {
    return _setSetting('screenScraperUser', value);
  }

  Future<void> setScreenScraperPwd(String value) async {
    return _setSetting('screenScraperPwd', value);
  }

  Future<void> setRetroAchievementsUser(String value) async {
    return _setSetting('retroAchievementsUser', value.trim());
  }

  Future<void> setRetroAchievementsApiKey(String value) async {
    return _setSetting('retroAchievementsApiKey', value.trim());
  }

  Future<void> clearRetroAchievements() async {
    await _resetSetting('retroAchievementsUser');
    await _resetSetting('retroAchievementsApiKey');
  }

  Future<void> setScrapeTheseGames(String value) async {
    return _setSetting('scrapeTheseGames', value);
  }

  Future<void> setScrapeTheseSystem(String id, bool scrape) async {
    final settings = await getSettings();
    final systems = settings.scrapeTheseSystems.toSet();
    if (scrape) {
      systems.add(id);
    } else {
      systems.remove(id);
    }
    return setScrapeTheseSystems(systems.toList());
  }

  Future<void> setScrapeTheseSystems(List<String> ids) async {
    if (ids.isEmpty) {
      return _resetSetting('scrapeTheseSystems');
    } else {
      return _setSetting('scrapeTheseSystems', ids.join(","));
    }
  }

  Future<void> _resetSetting(String key) async {
    await (db.delete(db.settingEntries)..where((t) => t.key.equals(key))).go();
  }

  Future<void> _setSetting(String key, String value) async {
    await db.into(db.settingEntries).insert(
          SettingEntriesCompanion.insert(key: key, value: value),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> _setBoolean(String key, bool value) async {
    return _setSetting(key, value.toString());
  }
}

class RomFoldersRepo {
  final AppDatabase db;

  RomFoldersRepo(this.db);

  Future<List<String>> getRomFolders() async {
    final defaultRomFolders = await _getDefaultRomFolders();
    final setting = await (db.select(db.settingEntries)..where((t) => t.key.equals("romsFolders"))).getSingleOrNull();
    return setting != null ? setting.value.split(",") : defaultRomFolders;
  }

  Future<void> saveRomsFolders(List<String> romsFolders) async {
    debugPrint("Folders $romsFolders");
    await db.into(db.settingEntries).insert(
          SettingEntriesCompanion.insert(key: 'romsFolders', value: romsFolders.join(",")),
          mode: InsertMode.insertOrReplace,
        );
  }
}

class RecentGamesRepo {
  final AppDatabase db;

  RecentGamesRepo(this.db);

  Future<List<RecentGame>> getRecentGames() {
    return db.select(db.recentGameEntries).get();
  }

  Future<void> saveRecentGame(Game game) async {
    debugPrint("Recent ${game.romPath}");
    await db.into(db.recentGameEntries).insert(
          RecentGameEntriesCompanion.insert(
            romPath: game.romPath,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}

class PerSystemConfigurationRepo {
  final AppDatabase db;

  PerSystemConfigurationRepo(this.db);

  Future<List<AlternativeEmulator>> getAlternativeEmulators() {
    return db.select(db.alternativeEmulatorEntries).get();
  }

  Future<void> saveAlternativeEmulator(String system, String emulator) async {
    await db.into(db.alternativeEmulatorEntries).insert(
          AlternativeEmulatorEntriesCompanion.insert(system: system, emulator: emulator),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> deleteAlternativeEmulator(String system) async {
    await (db.delete(db.alternativeEmulatorEntries)..where((t) => t.system.equals(system))).go();
  }
}

class CustomEmulatorsRepo {
  final AppDatabase db;
  CustomEmulatorsRepo(this.db);

  Future<List<CustomEmulator>> getCustomEmulators() {
    return db.select(db.customEmulatorEntries).get();
  }

  Future<void> saveCustomEmulator(CustomEmulator emulator) async {
    await db.into(db.customEmulatorEntries).insert(
          CustomEmulatorEntriesCompanion.insert(name: emulator.name, amStartCommand: emulator.amStartCommand),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> deleteCustomEmulator(String name) async {
    await (db.delete(db.customEmulatorEntries)..where((t) => t.name.equals(name))).go();
  }
}

class PerGameConfigurationRepo {
  final AppDatabase db;

  PerGameConfigurationRepo(this.db);

  Future<List<GameEmulator>> getGameEmulators() {
    return db.select(db.gameEmulatorEntries).get();
  }

  Future<void> saveGameEmulator(Game game, String emulator) async {
    await db.into(db.gameEmulatorEntries).insert(
          GameEmulatorEntriesCompanion.insert(romPath: game.romPath, emulator: emulator),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<GameEmulator?> getGameEmulator(Game game) {
    return (db.select(db.gameEmulatorEntries)..where((t) => t.romPath.equals(game.romPath))).getSingleOrNull();
  }
}

class EnabledSystems {
  final Map<String, Setting> settings;

  EnabledSystems(this.settings);

  bool get showSystemAndroid => showSystem('android');
  bool get showSystemFavourites => showSystem('favourites');
  bool get showSystemRetroAchievements => showSystem('retroachievements');
  bool showSystem(String id) =>
      _getBoolean('showSystem/$id', (id == 'no_metadata' || id == 'retroachievements') ? false : true);
  bool _getBoolean(String key, bool defaultValue) {
    return settings.containsKey(key) ? settings[key]!.value == "true" : defaultValue;
  }
}

class EnabledSystemsRepo {
  final AppDatabase db;

  EnabledSystemsRepo(this.db);

  Future<EnabledSystems> getEnabledSystems() async {
    final settingsList = await db.select(db.settingEntries).get();
    final settingsMap = {for (final s in settingsList) s.key: s};
    return EnabledSystems(settingsMap);
  }

  Future<void> setShowSystem(String id, bool value) async {
    return _setBoolean('showSystem/$id', value);
  }

  Future<void> _setBoolean(String key, bool value) async {
    await db.into(db.settingEntries).insert(
          SettingEntriesCompanion.insert(key: key, value: value.toString()),
          mode: InsertMode.insertOrReplace,
        );
  }
}

class SelectedApps {
  final Set<String> apps;

  SelectedApps(this.apps);

  bool isSelected(String package) => apps.contains(package);
}

class AndroidAppsRepo {
  final AppDatabase db;

  AndroidAppsRepo(this.db);

  Future<SelectedApps> getSelectedApps() async {
    final settingsList = await db.select(db.androidAppEntries).get();
    final settingsSet = {for (final s in settingsList) s.package};
    return SelectedApps(settingsSet);
  }

  Future<void> selectApp(String package, bool selected) async {
    if (selected) {
      await db.into(db.androidAppEntries).insert(
            AndroidAppEntriesCompanion.insert(package: package),
            mode: InsertMode.insertOrReplace,
          );
    } else {
      await (db.delete(db.androidAppEntries)..where((t) => t.package.equals(package))).go();
    }
  }
}

class GameRetroAchievementsRepo {
  final AppDatabase db;

  GameRetroAchievementsRepo(this.db);

  Future<GameRetroAchievements?> getEntry(String romPath) async {
    return (db.select(db.gameRetroAchievementsEntries)
          ..where((t) => t.romPath.equals(romPath)))
        .getSingleOrNull();
  }

  Future<Map<String, GameRetroAchievements>> getEntriesForSystem(
    System system,
    List<Game> games,
  ) async {
    if (games.isEmpty) return {};
    final romPaths = games.map((g) => g.romPath).toList();
    final list = await (db.select(db.gameRetroAchievementsEntries)
          ..where((t) => t.romPath.isIn(romPaths)))
        .get();
    return {for (final e in list) e.romPath: e};
  }

  Future<Map<String, GameRetroAchievements>> getAllEntries() async {
    final list = await db.select(db.gameRetroAchievementsEntries).get();
    return {for (final e in list) e.romPath: e};
  }

  Future<void> saveEntry({
    required String romPath,
    required String md5Hash,
    int? raGameId,
    int numAchievements = 0,
    int points = 0,
    String? raTitle,
    String? badgeUrl,
  }) async {
    await db.into(db.gameRetroAchievementsEntries).insert(
          GameRetroAchievementsEntriesCompanion.insert(
            romPath: romPath,
            md5Hash: md5Hash,
            raGameId: Value(raGameId),
            numAchievements: Value(numAchievements),
            points: Value(points),
            raTitle: Value(raTitle),
            badgeUrl: Value(badgeUrl),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}

class RetroAchievementsCacheRepo {
  final AppDatabase db;
  final Map<String, (String json, int timestamp)> _memoryCache = {};

  RetroAchievementsCacheRepo(this.db);

  String? getSyncCache(
    String key, {
    Duration maxAge = const Duration(hours: 24),
  }) {
    final entry = _memoryCache[key];
    if (entry == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - entry.$2;
    if (age < maxAge.inMilliseconds) {
      return entry.$1;
    }
    return null;
  }

  Future<String?> getValidCache(
    String key, {
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final syncHit = getSyncCache(key, maxAge: maxAge);
    if (syncHit != null) return syncHit;

    final entry = await (db.select(db.retroAchievementsApiCacheEntries)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    if (entry == null) return null;
    _memoryCache[key] = (entry.responseJson, entry.timestamp);
    final age = DateTime.now().millisecondsSinceEpoch - entry.timestamp;
    if (age < maxAge.inMilliseconds) {
      return entry.responseJson;
    }
    return null;
  }

  Future<String?> getAnyCache(String key) async {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!.$1;
    }
    final entry = await (db.select(db.retroAchievementsApiCacheEntries)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    if (entry != null) {
      _memoryCache[key] = (entry.responseJson, entry.timestamp);
    }
    return entry?.responseJson;
  }

  Future<void> putCache(String key, String responseJson) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _memoryCache[key] = (responseJson, now);
    await db.into(db.retroAchievementsApiCacheEntries).insert(
          RetroAchievementsApiCacheEntriesCompanion.insert(
            cacheKey: key,
            responseJson: responseJson,
            timestamp: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<(String key, String responseJson)>> getAllValidCacheEntries(
    String prefix, {
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final entries = await (db.select(db.retroAchievementsApiCacheEntries)
          ..where((t) => t.cacheKey.like('$prefix%')))
        .get();

    final result = <(String key, String responseJson)>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final entry in entries) {
      final age = now - entry.timestamp;
      if (age < maxAge.inMilliseconds) {
        _memoryCache[entry.cacheKey] = (entry.responseJson, entry.timestamp);
        result.add((entry.cacheKey, entry.responseJson));
      }
    }
    return result;
  }

  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    await (db.delete(db.retroAchievementsApiCacheEntries)
          ..where((t) => t.cacheKey.equals(key)))
        .go();
  }

  Future<void> clearAll() async {
    _memoryCache.clear();
    await db.delete(db.retroAchievementsApiCacheEntries).go();
  }
}

final retroAchievementsCacheRepoProvider =
    Provider<RetroAchievementsCacheRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return RetroAchievementsCacheRepo(db);
});

final settingsRepoProvider = Provider<SettingsRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepo(db);
});

final settingsProvider = FutureProvider<Settings>((ref) async {
  final repo = ref.watch(settingsRepoProvider);
  return repo.getSettings();
});

final recentGamesRepoProvider = Provider<RecentGamesRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return RecentGamesRepo(db);
});

final recentGamesProvider = FutureProvider<List<RecentGame>>((ref) async {
  final repo = ref.watch(recentGamesRepoProvider);
  return repo.getRecentGames();
});

final romFoldersRepoProvider = Provider<RomFoldersRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return RomFoldersRepo(db);
});

final romFoldersProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(romFoldersRepoProvider);
  return repo.getRomFolders();
});

final perSystemConfigurationRepoProvider = Provider<PerSystemConfigurationRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return PerSystemConfigurationRepo(db);
});

final perSystemConfigurationsProvider = FutureProvider<List<AlternativeEmulator>>((ref) async {
  final repo = ref.watch(perSystemConfigurationRepoProvider);
  return repo.getAlternativeEmulators();
});

final customEmulatorsRepoProvider = Provider<CustomEmulatorsRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomEmulatorsRepo(db);
});

final customEmulatorsProvider = FutureProvider<List<CustomEmulator>>((ref) async {
  final repo = ref.watch(customEmulatorsRepoProvider);
  return repo.getCustomEmulators();
});

final perGameConfigurationRepoProvider = Provider<PerGameConfigurationRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return PerGameConfigurationRepo(db);
});

final perGameConfigurationsProvider = FutureProvider<List<GameEmulator>>((ref) async {
  final repo = ref.watch(perGameConfigurationRepoProvider);
  return repo.getGameEmulators();
});

final perGameConfigurationProvider = FutureProvider.family<GameEmulator?, Game?>((ref, game) async {
  if (game == null) {
    return null;
  }
  final repo = ref.watch(perGameConfigurationRepoProvider);
  return repo.getGameEmulator(game);
});

final gameRetroAchievementsRepoProvider =
    Provider<GameRetroAchievementsRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return GameRetroAchievementsRepo(db);
});

final gameRetroAchievementsProvider =
    FutureProvider.family<GameRetroAchievements?, Game?>((ref, game) async {
  if (game == null) return null;
  final repo = ref.watch(gameRetroAchievementsRepoProvider);
  final entry = await repo.getEntry(game.romPath);
  if (entry != null) return entry;
  if (game.system.hasRetroAchievements) {
    return resolveGameRetroAchievements(game: game, repo: repo);
  }
  return null;
});

final systemRetroAchievementsProvider =
    FutureProvider.family<Map<String, GameRetroAchievements>, ({System system, List<Game> games})>(
        (ref, arg) async {
  final repo = ref.watch(gameRetroAchievementsRepoProvider);
  return repo.getEntriesForSystem(arg.system, arg.games);
});

final enabledSystemsRepoProvider = Provider<EnabledSystemsRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return EnabledSystemsRepo(db);
});

final enabledSystemsProvider = FutureProvider<EnabledSystems>((ref) async {
  final repo = ref.watch(enabledSystemsRepoProvider);
  return repo.getEnabledSystems();
});

final androidAppsRepoProvider = Provider<AndroidAppsRepo>((ref) {
  final db = ref.watch(databaseProvider);
  return AndroidAppsRepo(db);
});

final androidAppsProvider = FutureProvider<SelectedApps>((ref) async {
  final repo = ref.watch(androidAppsRepoProvider);
  return repo.getSelectedApps();
});

final externalRomsPathsProvider = FutureProvider<List<String>>((ref) async {
  if (Platform.isAndroid) {
    return _getExternalRomsPaths();
  }
  return _getDefaultRomFolders();
});

Future<List<String>> _getDefaultRomFolders() async {
  List<String> romsFolders = [];
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? '';
    romsFolders = ["$home/Roms"];
  }
  if (Platform.isWindows) {
    romsFolders = ["D:\\Roms"];
  }
  if (Platform.isAndroid) {
    final paths = await _getExternalRomsPaths();
    romsFolders = [paths[paths.length - 1]];
  }
  return romsFolders;
}

Future<List<String>> _getExternalRomsPaths() async {
  List<String> paths = ["/storage/emulated/0/Roms"];
  List<Directory?>? extDirectories = await getExternalStorageDirectories();

  if (extDirectories == null || extDirectories.isEmpty) {
    return paths;
  }

  if (extDirectories.length > 1) {
    for (int i = 1; i < extDirectories.length; i++) {
      List<String> dirs = extDirectories[i].toString().split('/');
      String rebuiltPath = '/${dirs[1]}/${dirs[2]}';
      paths.add(rebuiltPath);
      paths.add("$rebuiltPath/Roms");
    }
  }

  return paths;
}
