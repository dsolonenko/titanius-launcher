import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:titanius/data/models.dart';
import 'package:titanius/data/storage.dart';

part 'repo.g.dart';

class Settings {
  final Map<String, Setting> settings;

  Settings(this.settings);

  bool get favouritesOnTop => _getBoolean('favouritesOnTop', false);
  bool get showHiddenGames => _getBoolean('showHiddenGames', false);
  bool get checkMissingGames => _getBoolean('checkMissingGames', false);
  bool get uniqueGamesInCollections => _getBoolean('uniqueGamesInCollections', false);
  bool get compactGameList => _getBoolean('compactGameList', false);
  bool get showGameVideos => _getBoolean('showGameVideos', false);
  bool get fadeToVideo => _getBoolean('fadeToVideo', false);
  bool get muteVideo => _getBoolean('muteVideo', true);
  String? get daijishoWallpaperPack => _getString('daijishoWallpaperPack');

  bool _getBoolean(String key, bool defaultValue) {
    return settings.containsKey(key) ? settings[key]!.value == "true" : defaultValue;
  }

  String? _getString(String key) {
    return settings.containsKey(key) ? settings[key]!.value : null;
  }
}

@collection
class AlternativeEmulator {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String system;
  String emulator;
  AlternativeEmulator({required this.system, this.emulator = ""});
}

@collection
class GameEmulator {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String romPath;
  String emulator;
  GameEmulator({required this.romPath, this.emulator = ""});
}

@collection
class Setting {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String key;
  String value;
  Setting({required this.key, this.value = ""});
}

@collection
class RecentGame {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String romPath;
  int timestamp;
  RecentGame({required this.romPath, this.timestamp = 0});
}

@collection
class AndroidApp {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String package;
  AndroidApp({required this.package});
}

class SettingsRepo {
  final Isar isar;

  SettingsRepo(this.isar);

  Future<Settings> _getSettings() async {
    final settings = await isar.settings.where().findAll();
    final settingsMap = {for (final s in settings) s.key: s};
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

  Future<void> _resetSetting(String key) async {
    await isar.writeTxn(() async {
      await isar.settings.deleteByKey(key);
    });
  }

  Future<void> _setSetting(String key, String value) async {
    await isar.writeTxn(() async {
      await isar.settings.put(Setting(key: key, value: value));
    });
  }

  Future<void> _setBoolean(String key, bool value) async {
    return _setSetting(key, value.toString());
  }
}

class RomFoldersRepo {
  final Isar isar;

  RomFoldersRepo(this.isar);

  Future<List<String>> _getRomFolders() async {
    final defaultRomFolders = await _getDefaultRomFolders();
    final settings = await isar.settings.where().keyEqualTo("romsFolders").findFirst();
    return settings != null ? settings.value.split(",") : defaultRomFolders;
  }

  Future<void> saveRomsFolders(List<String> romsFolders) async {
    debugPrint("Folders $romsFolders");
    await isar.writeTxn(() async {
      await isar.settings.put(Setting(key: 'romsFolders', value: romsFolders.join(","))).catchError((e) {
        debugPrint(e);
        return 0;
      });
    });
  }
}

class RecentGamesRepo {
  final Isar isar;

  RecentGamesRepo(this.isar);

  Future<List<RecentGame>> _getRecentGames() {
    return isar.recentGames.where().findAll();
  }

  Future<void> saveRecentGame(Game game) async {
    debugPrint("Recent ${game.romPath}");
    await isar.writeTxn(() async {
      await isar.recentGames
          .put(RecentGame(romPath: game.romPath, timestamp: DateTime.now().millisecondsSinceEpoch))
          .catchError((e) {
        debugPrint(e);
        return 0;
      });
    });
  }
}

class PerSystemConfigurationRepo {
  final Isar isar;

  PerSystemConfigurationRepo(this.isar);

  Future<List<AlternativeEmulator>> _getAlternativeEmulators() {
    return isar.alternativeEmulators.where().findAll();
  }

  Future<void> saveAlternativeEmulator(String system, String emulator) async {
    await isar.writeTxn(() async {
      await isar.alternativeEmulators.put(AlternativeEmulator(system: system, emulator: emulator));
    });
  }
}

class PerGameConfigurationRepo {
  final Isar isar;

  PerGameConfigurationRepo(this.isar);

  Future<List<GameEmulator>> _getGameEmulators() {
    return isar.gameEmulators.where().findAll();
  }

  Future<void> saveGameEmulator(Game game, String emulator) async {
    await isar.writeTxn(() async {
      await isar.gameEmulators.put(GameEmulator(romPath: game.romPath, emulator: emulator));
    });
  }

  Future<GameEmulator?> _getGameEmulator(Game game) {
    return isar.gameEmulators.where().romPathEqualTo(game.romPath).findFirst();
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
  final Isar isar;

  EnabledSystemsRepo(this.isar);

  Future<EnabledSystems> _getEnabledSystems() async {
    final settings = await isar.settings.where().findAll();
    final settingsMap = {for (final s in settings) s.key: s};
    return EnabledSystems(settingsMap);
  }

  Future<void> setShowSystem(String id, bool value) async {
    return _setBoolean('showSystem/$id', value);
  }

  Future<void> _setBoolean(String key, bool value) async {
    await isar.writeTxn(() async {
      await isar.settings.put(Setting(key: key, value: value.toString()));
    });
  }
}

class SelectedApps {
  final Set<String> apps;

  SelectedApps(this.apps);

  bool isSelected(String package) => apps.contains(package);
}

class AndroidAppsRepo {
  final Isar isar;

  AndroidAppsRepo(this.isar);

  Future<SelectedApps> _getSelectedApps() async {
    final settings = await isar.androidApps.where().findAll();
    final settingsSet = {for (final s in settings) s.package};
    return SelectedApps(settingsSet);
  }

  Future<void> selectApp(String package, bool selected) async {
    await isar.writeTxn(() async {
      if (selected) {
        await isar.androidApps.put(AndroidApp(package: package));
      } else {
        await isar.androidApps.deleteByPackage(package);
      }
    });
  }
}

@Riverpod(keepAlive: true)
Future<SettingsRepo> settingsRepo(SettingsRepoRef ref) async {
  final isar = await ref.watch(isarProvider.future);
  return SettingsRepo(isar);
}

@Riverpod(keepAlive: true)
Future<Settings> settings(SettingsRef ref) async {
  final repo = await ref.watch(settingsRepoProvider.future);
  return repo._getSettings();
}

@Riverpod(keepAlive: true)
Future<RecentGamesRepo> recentGamesRepo(RecentGamesRepoRef ref) async {
  final isar = await ref.watch(isarProvider.future);
  return RecentGamesRepo(isar);
}

@Riverpod(keepAlive: true)
Future<List<RecentGame>> recentGames(RecentGamesRef ref) async {
  final repo = await ref.watch(recentGamesRepoProvider.future);
  return repo._getRecentGames();
}

@Riverpod(keepAlive: true)
Future<RomFoldersRepo> romFoldersRepo(RomFoldersRepoRef ref) async {
  final isar = await ref.watch(isarProvider.future);
  return RomFoldersRepo(isar);
}

@Riverpod(keepAlive: true)
Future<List<String>> romFolders(RomFoldersRef ref) async {
  final repo = await ref.watch(romFoldersRepoProvider.future);
  return repo._getRomFolders();
}

@Riverpod(keepAlive: true)
Future<PerSystemConfigurationRepo> perSystemConfigurationRepo(PerSystemConfigurationRepoRef ref) async {
  final isar = await ref.watch(isarProvider.future);
  return PerSystemConfigurationRepo(isar);
}

@Riverpod(keepAlive: true)
Future<List<AlternativeEmulator>> perSystemConfigurations(PerSystemConfigurationsRef ref) async {
  final repo = await ref.watch(perSystemConfigurationRepoProvider.future);
  return repo._getAlternativeEmulators();
}

@Riverpod(keepAlive: true)
Future<PerGameConfigurationRepo> perGameConfigurationRepo(PerGameConfigurationRepoRef ref) async {
  final isar = await ref.watch(isarProvider.future);
  return PerGameConfigurationRepo(isar);
}

@Riverpod(keepAlive: true)
Future<List<GameEmulator>> perGameConfigurations(PerGameConfigurationsRef ref) async {
  final repo = await ref.watch(perGameConfigurationRepoProvider.future);
  return repo._getGameEmulators();
}

@riverpod
Future<GameEmulator?> perGameConfiguration(PerGameConfigurationRef ref, Game? game) async {
  if (game == null) {
    return null;
  }
  final repo = await ref.watch(perGameConfigurationRepoProvider.future);
  return repo._getGameEmulator(game);
}

@Riverpod(keepAlive: true)
Future<EnabledSystemsRepo> enabledSystemsRepo(EnabledSystemsRepoRef ref) async {
  final isar = await ref.watch(isarProvider.future);
  return EnabledSystemsRepo(isar);
}

@Riverpod(keepAlive: true)
Future<EnabledSystems> enabledSystems(EnabledSystemsRef ref) async {
  final repo = await ref.watch(enabledSystemsRepoProvider.future);
  return repo._getEnabledSystems();
}

@Riverpod(keepAlive: true)
Future<AndroidAppsRepo> androidAppsRepo(AndroidAppsRepoRef ref) async {
  final isar = await ref.watch(isarProvider.future);
  return AndroidAppsRepo(isar);
}

@Riverpod(keepAlive: true)
Future<SelectedApps> androidApps(AndroidAppsRef ref) async {
  final repo = await ref.watch(androidAppsRepoProvider.future);
  return repo._getSelectedApps();
}

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

@riverpod
Future<List<String>> externalRomsPaths(ExternalRomsPathsRef ref) async {
  if (Platform.isAndroid) {
    return _getExternalRomsPaths();
  }
  return _getDefaultRomFolders();
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
