import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:titanius/data/android_saf.dart';
import 'package:titanius/data/repo.dart';

import 'models.dart';

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
  return systems;
}

@Riverpod(keepAlive: true)
Future<List<System>> detectedSystems(DetectedSystemsRef ref) async {
  final allSystems = await ref.watch(allSupportedSystemsProvider.future);
  final enabledSystems = await ref.watch(enabledSystemsProvider.future);
  final grantedUris = await ref.watch(grantedUrisProvider.future);
  final detectedSystems =
      allSystems.where((system) => enabledSystems.showSystem(system.id) && _hasGamelist(system, grantedUris)).toList();
  final enabledCollections = [];
  for (var collection in collections) {
    if (enabledSystems.showSystem(collection.id)) {
      enabledCollections.add(collection);
    }
  }
  debugPrint("enabledCollections: ${enabledCollections.map((e) => e.name).join(", ")}");
  debugPrint("detectedSystems: ${detectedSystems.map((e) => e.name).join(", ")}");
  return [...enabledCollections, ...detectedSystems];
}

bool _hasGamelist(System system, List<GrantedUri> grantedUris) {
  if (system.folders.isEmpty) {
    return true;
  }
  return system.folders.any((folder) =>
      grantedUris.any((romsFolder) => File("${romsFolder.grantedFullPath}/$folder/gamelist.xml").existsSync()));
}
