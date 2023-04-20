import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'models.dart';
import 'storage.dart';

part 'repo.g.dart';

class Settings {
  final Map<String, Setting> settings;
  final List<Favourite> favourites;

  Settings(this.settings, this.favourites);

  bool get favouritesOnTop => _getBoolean('favouritesOnTop', false);
  bool get compactGameList => _getBoolean('compactGameList', false);
  bool get showGameVideos => _getBoolean('showGameVideos', false);
  bool get fadeToVideo => _getBoolean('fadeToVideo', false);
  bool get muteVideo => _getBoolean('muteVideo', true);

  bool _getBoolean(String key, bool defaultValue) {
    return settings.containsKey(key) ? settings[key]!.value == "true" : defaultValue;
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
class Favourite {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String romPath;
  bool favourite;
  Favourite({required this.romPath, this.favourite = false});
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

class SettingsRepo {
  final Isar isar;

  SettingsRepo(this.isar);

  Future<Settings> _getSettings() async {
    final settings = await isar.settings.where().findAll();
    final settingsMap = {for (final s in settings) s.key: s};
    final favourites = await isar.favourites.where().findAll();
    return Settings(settingsMap, favourites);
  }

  Future<void> saveFavourite(String path, bool isFavourite) async {
    debugPrint("Favourite $path $isFavourite");
    await isar.writeTxn(() async {
      await isar.favourites.put(Favourite(romPath: path, favourite: isFavourite)).catchError((e) {
        debugPrint(e);
        return 0;
      });
    });
  }

  Future<void> setFavoutesOnTop(bool value) async {
    return _setBoolean('favouritesOnTop', value);
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

  Future<void> _setBoolean(String key, bool value) async {
    await isar.writeTxn(() async {
      await isar.settings.put(Setting(key: key, value: value.toString()));
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

  Future<void> saveAlternativeEmulator(AlternativeEmulator config) async {
    await isar.writeTxn(() async {
      await isar.alternativeEmulators.put(config);
    });
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
Future<EnabledSystemsRepo> enabledSystemsRepo(EnabledSystemsRepoRef ref) async {
  final isar = await ref.watch(isarProvider.future);
  return EnabledSystemsRepo(isar);
}

@Riverpod(keepAlive: true)
Future<EnabledSystems> enabledSystems(EnabledSystemsRef ref) async {
  final repo = await ref.watch(enabledSystemsRepoProvider.future);
  return repo._getEnabledSystems();
}
