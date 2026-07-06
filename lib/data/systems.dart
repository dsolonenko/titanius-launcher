import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:titanius/data/repo.dart';
import 'package:titanius/data/models.dart';

final allSupportedSystemsProvider = FutureProvider<List<System>>((ref) async {
  final content = json.decode(
    await rootBundle.loadString('assets/metadata.json'),
  );
  final List<System> systems = content['systems'].map<System>((e) => System.fromJson(e)).toList();
  if (!Platform.isAndroid) {
    systems.removeWhere((system) => system.id == 'android');
  }
  systems.sort((a, b) => a.name.compareTo(b.name));
  return [...collections, ...systems];
});

final detectedSystemsProvider = FutureProvider<List<System>>((ref) async {
  final allSystems = await ref.watch(allSupportedSystemsProvider.future);
  final enabledSystems = await ref.watch(enabledSystemsProvider.future);
  final detectedSystems = [
    for (final system in allSystems)
      if (enabledSystems.showSystem(system.id)) system
  ];
  return detectedSystems;
});
