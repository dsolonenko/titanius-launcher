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
      if (enabledSystems.showSystem(system.id) && await _hasGames(system, romFolders)) system
  ];
  return detectedSystems;
}

Future<bool> _hasGames(System system, List<String> romFolders) async {
  for (final folder in system.folders) {
    for (final romFolder in romFolders) {
      final path = Directory('$romFolder/$folder');
      final hasFiles = path.existsSync() && !await path.list().isEmpty;
      if (hasFiles) {
        return true;
      }
    }
  }
  return false;
}
