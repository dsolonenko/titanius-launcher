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
  final detectedSystems =
      allSystems.where((system) => enabledSystems.showSystem(system.id) && _hasGamelist(system, romFolders)).toList();
  return detectedSystems;
}

bool _hasGamelist(System system, List<String> romFolders) {
  if (system.folders.isEmpty) {
    return true;
  }
  return system.folders
      .any((folder) => romFolders.any((romsFolder) => File("$romsFolder/$folder/gamelist.xml").existsSync()));
}
