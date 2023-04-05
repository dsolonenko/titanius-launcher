import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'storage.dart';

part 'settings.g.dart';

class Settings {
  final Map<String, Setting> settings;
  final List<AlternativeEmulator> perSystemConfigurations;
  final List<Favourite> favourites;

  Settings(this.settings, this.perSystemConfigurations, this.favourites);

  List<String> get romsFolders => settings['romsFolders']!.value.split(",");
  bool get showSystemAndroid => showSystem('android');
  bool get favouritesOnTop => _getBoolean('favouritesOnTop', true);
  bool get showGameVideos => _getBoolean('showGameVideos', false);

  bool showSystem(String id) => _getBoolean('showSystem/$id', true);
  bool _getBoolean(String key, bool defaultValue) {
    return settings.containsKey(key)
        ? settings[key]!.value == "true"
        : defaultValue;
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

class SettingsRepo {
  final Isar isar;

  SettingsRepo(this.isar);

  Future<Settings> _getSettings() async {
    final defaultSettings = await _getDefaultSettings();
    final settingsMap = {
      for (final setting in defaultSettings) setting.key: setting
    };
    final settings = await isar.settings.where().findAll();
    settingsMap.addAll({for (final setting in settings) setting.key: setting});
    final perSystemConfigurations =
        await isar.alternativeEmulators.where().findAll();
    final favourites = await isar.favourites.where().findAll();
    return Settings(settingsMap, perSystemConfigurations, favourites);
  }

  Future<void> saveAlternativeEmulator(AlternativeEmulator config) async {
    await isar.writeTxn(() async {
      await isar.alternativeEmulators.put(config);
    });
  }

  Future<void> setShowSystem(String id, bool value) async {
    return _setBoolean('showSystem/$id', value);
  }

  Future<void> saveFavourite(String path, bool isFavourite) async {
    debugPrint("Favourite $path $isFavourite");
    await isar.writeTxn(() async {
      await isar.favourites
          .put(Favourite(romPath: path, favourite: isFavourite))
          .catchError((e) {
        debugPrint(e);
        return 0;
      });
    });
  }

  Future<void> setFavoutesOnTop(bool value) async {
    return _setBoolean('favouritesOnTop', value);
  }

  Future<void> setShowGameVideos(bool value) async {
    return _setBoolean('showGameVideos', value);
  }

  Future<void> _setBoolean(String key, bool value) async {
    await isar.writeTxn(() async {
      await isar.settings.put(Setting(key: key, value: value.toString()));
    });
  }

  Future<void> saveRomsFolders(List<String> romsFolders) async {
    debugPrint("Folders $romsFolders");
    await isar.writeTxn(() async {
      await isar.settings
          .put(Setting(key: 'romsFolders', value: romsFolders.join(",")))
          .catchError((e) {
        debugPrint(e);
        return 0;
      });
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

Future<List<Setting>> _getDefaultSettings() async {
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

  return [
    Setting(key: 'romsFolders', value: romsFolders.join(",")),
  ];
}

@riverpod
Future<List<String>> externalRomsPaths(ExternalRomsPathsRef ref) async {
  return _getExternalRomsPaths();
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
