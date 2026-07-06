import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:titanius/data/database.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/storage.dart';

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
  String? get daijishoWallpaperPack => _getString('daijishoWallpaperPack');
  String? get screenScraperUser => _getString('screenScraperUser');
  String? get screenScraperPwd => _getString('screenScraperPwd');
  String? get scrapeTheseGames => _getString('scrapeTheseGames');
  List<String> get scrapeTheseSystems => _getStringList('scrapeTheseSystems');

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
    await db.into(db.settingEntries).insertOnConflictUpdate(
          SettingEntriesCompanion.insert(key: key, value: value),
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
    await db.into(db.settingEntries).insertOnConflictUpdate(
          SettingEntriesCompanion.insert(key: 'romsFolders', value: romsFolders.join(",")),
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
    await db.into(db.recentGameEntries).insertOnConflictUpdate(
          RecentGameEntriesCompanion.insert(
            romPath: game.romPath,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
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
    await db.into(db.alternativeEmulatorEntries).insertOnConflictUpdate(
          AlternativeEmulatorEntriesCompanion.insert(system: system, emulator: emulator),
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
    await db.into(db.customEmulatorEntries).insertOnConflictUpdate(
          CustomEmulatorEntriesCompanion.insert(name: emulator.name, amStartCommand: emulator.amStartCommand),
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
    await db.into(db.gameEmulatorEntries).insertOnConflictUpdate(
          GameEmulatorEntriesCompanion.insert(romPath: game.romPath, emulator: emulator),
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
  bool showSystem(String id) => _getBoolean('showSystem/$id', true);
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
    await db.into(db.settingEntries).insertOnConflictUpdate(
          SettingEntriesCompanion.insert(key: key, value: value.toString()),
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
      await db.into(db.androidAppEntries).insertOnConflictUpdate(
            AndroidAppEntriesCompanion.insert(package: package),
          );
    } else {
      await (db.delete(db.androidAppEntries)..where((t) => t.package.equals(package))).go();
    }
  }
}

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
    romsFolders = ["/Users/ds/Roms"];
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
