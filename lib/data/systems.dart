import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:titanius/data/repo.dart';
import 'package:titanius/data/models.dart';

part 'systems.g.dart';

@Riverpod(keepAlive: true)
Future<List<System>> allSupportedSystems(AllSupportedSystemsRef ref) async {
  final content = json.decode(
    await rootBundle.loadString('assets/metadata.json'),
  );
  final List<System> systems = content['systems'].map<System>((e) => System.fromJson(e)).toList();
  if (!Platform.isAndroid) {
    systems.removeWhere((system) => system.id == 'android');
  }
  systems.sort((a, b) => a.name.compareTo(b.name));
  return [...collections, ...systems];
}

@Riverpod(keepAlive: true)
Future<List<System>> detectedSystems(DetectedSystemsRef ref) async {
  final allSystems = await ref.watch(allSupportedSystemsProvider.future);
  final enabledSystems = await ref.watch(enabledSystemsProvider.future);
  final romFolders = await ref.watch(romFoldersProvider.future);
  final detectedSystems = [
    for (final system in allSystems)
      if (enabledSystems.showSystem(system.id) && _hasGames(system, romFolders)) system
  ];
  return detectedSystems;
}

bool _hasGames(System system, List<String> romFolders) {
  if (system.id == 'android') {
    return true;
  }
  if (system.isCollection) {
    return true;
  }
  for (final folder in system.folders) {
    for (final romFolder in romFolders) {
      final gamelist = File('$romFolder/$folder/gamelist.xml');
      if (gamelist.existsSync()) {
        return true;
      }
    }
  }
  return false;
}
