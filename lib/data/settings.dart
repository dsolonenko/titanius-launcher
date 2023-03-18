import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'storage.dart';

part 'settings.g.dart';

class Settings {
  final Map<String, Setting> settings;
  final List<AlternativeEmulator> perSystemConfigurations;

  Settings(this.settings, this.perSystemConfigurations);

  get romsFolder => settings['romsFolder']!.value;
  get showSystemAndroid => showSystem('android');
  get favouritesOnTop => _getBoolean('favouritesOnTop', true);

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
    return Settings(settingsMap, perSystemConfigurations);
  }

  Future<void> saveAlternativeEmulator(AlternativeEmulator config) async {
    await isar.writeTxn(() async {
      await isar.alternativeEmulators.put(config);
    });
  }

  Future<void> setShowSystem(String id, bool value) async {
    return _setBoolean('showSystem/$id', value);
  }

  Future<void> setFavoutesOnTop(bool value) async {
    return _setBoolean('favouritesOnTop', value);
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

Future<List<Setting>> _getDefaultSettings() async {
  String romsFolder = "";
  if (Platform.isMacOS) {
    romsFolder = "/Users/ds/Roms";
  }
  if (Platform.isWindows) {
    romsFolder = "C:\\Users\\denis\\Roms";
  }
  if (Platform.isAndroid) {
    final directory = await _getExternalSdCardPath();
    romsFolder = "${directory.path}/Roms";
    print(romsFolder);
  }

  return [
    Setting(key: 'romsFolder', value: romsFolder),
  ];
}

Future<Directory> _getExternalSdCardPath() async {
  List<Directory?>? extDirectories = await getExternalStorageDirectories();

  List<String> dirs = extDirectories![1].toString().split('/');
  String rebuiltPath = '/${dirs[1]}/${dirs[2]}';

  print("SD Card path: " + rebuiltPath);
  return Directory(rebuiltPath);
}
