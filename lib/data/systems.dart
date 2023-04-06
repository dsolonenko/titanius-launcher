import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:titanius/data/settings.dart';

import 'models.dart';

part 'systems.g.dart';

@Riverpod(keepAlive: true)
Future<List<System>> allSupportedSystems(AllSupportedSystemsRef ref) async {
  final content = json.decode(
    await rootBundle.loadString('assets/metadata.json'),
  );
  final List<System> systems =
      content['systems'].map<System>((e) => System.fromJson(e)).toList();
  if (!Platform.isAndroid) {
    systems.removeWhere((system) => system.id == 'android');
  }
  systems.sort((a, b) => a.name.compareTo(b.name));
  return systems;
}

@Riverpod(keepAlive: true)
Future<List<System>> detectedSystems(DetectedSystemsRef ref) async {
  final allSystems = await ref.watch(allSupportedSystemsProvider.future);
  final settings = await ref.watch(settingsProvider.future);
  return allSystems
      .where((system) =>
          settings.showSystem(system.id) && _hasGamelist(system, settings))
      .toList();
}

bool _hasGamelist(System system, Settings settings) {
  if (system.folders.isEmpty) {
    return true;
  }
  return system.folders.any((folder) => settings.romsFolders.any(
      (romsFolder) => File("$romsFolder/$folder/gamelist.xml").existsSync()));
}
