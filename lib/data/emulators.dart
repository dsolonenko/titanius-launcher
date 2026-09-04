import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanius/data/daijisho_platforms.dart';
import 'package:titanius/data/games.dart';

import 'package:titanius/data/repo.dart';
import 'package:titanius/data/models.dart';

class EmulatorList {
  final System system;
  final List<Emulator> emulators;
  final Emulator? defaultEmulator;

  EmulatorList(this.system, this.emulators, this.defaultEmulator);
}

final alternativeEmulatorsProvider = FutureProvider<List<EmulatorList>>((
  ref,
) async {
  final perSystemConfigurations = await ref.watch(
    perSystemConfigurationsProvider.future,
  );
  final systems = await ref.watch(loadedSystemsProvider.future);
  final customEmulators = await ref.watch(customEmulatorsProvider.future);
  final emulators = customEmulators.map((e) => e.toEmulator()).toList();
  final daijishoService = ref.watch(daijishoPlatformsServiceProvider);

  final systemsToLoad = systems
      .whereNot((element) => element.isCollection)
      .whereNot((element) => element.id == "android")
      .toList();

  return await Future.wait(
    systemsToLoad.map((v) async {
      List<Emulator> daijishoEmus = [];
      try {
        daijishoEmus = await daijishoService.getCachedEmulatorsForSystem(v.id);
      } catch (_) {}
      final allEmus = [...v.builtInEmulators, ...emulators, ...daijishoEmus];
      return EmulatorList(
        v,
        allEmus,
        defaultEmulator(
          allEmus,
          perSystemConfigurations.firstWhereOrNull((e) => e.system == v.id),
        ),
      );
    }),
  );
});

Emulator? defaultEmulator(
  List<Emulator> emulators,
  AlternativeEmulator? alternativeEmulator,
) {
  if (alternativeEmulator != null) {
    final alternative = emulators.firstWhereOrNull(
      (e) => e.id == alternativeEmulator.emulator,
    );
    if (alternative != null) {
      return alternative;
    }
  }
  return emulators.isEmpty ? null : emulators.first;
}
