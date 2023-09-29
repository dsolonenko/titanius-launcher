import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:titanius/data/repo.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/systems.dart';

part 'emulators.g.dart';

class EmulatorList {
  final System system;
  final List<Emulator> emulators;
  final Emulator? defaultEmulator;

  EmulatorList(this.system, this.emulators, this.defaultEmulator);
}

@Riverpod(keepAlive: true)
Future<List<EmulatorList>> alternativeEmulators(AlternativeEmulatorsRef ref) async {
  final perSystemConfigurations = await ref.watch(perSystemConfigurationsProvider.future);
  final systems = await ref.watch(detectedSystemsProvider.future);
  final customEmulators = await ref.watch(customEmulatorsProvider.future);
  final emulators = customEmulators.map((e) => e.toEmulator()).toList();
  return systems
      .whereNot((element) => element.isCollection)
      .map((v) => EmulatorList(
            v,
            [...v.builtInEmulators, ...emulators],
            defaultEmulator([...v.builtInEmulators, ...emulators],
                perSystemConfigurations.firstWhereOrNull((e) => e.system == v.id)),
          ))
      .toList();
}

Emulator? defaultEmulator(List<Emulator> emulators, AlternativeEmulator? alternativeEmulator) {
  if (alternativeEmulator != null) {
    final alternative = emulators.firstWhereOrNull((e) => e.id == alternativeEmulator.emulator);
    if (alternative != null) {
      return alternative;
    }
  }
  return emulators.isEmpty ? null : emulators.first;
}
