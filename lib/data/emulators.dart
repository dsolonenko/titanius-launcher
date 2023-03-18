import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/settings.dart';
import 'models.dart';
import 'systems.dart';

part 'emulators.g.dart';

class EmulatorList {
  final System system;
  final Emulator defaultEmulator;

  EmulatorList(this.system, this.defaultEmulator);
}

@Riverpod(keepAlive: true)
Future<List<EmulatorList>> alternativeEmulators(
    AlternativeEmulatorsRef ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final systems = await ref.watch(detectedSystemsProvider.future);
  return systems
      .map((v) => EmulatorList(
          v,
          defaultEmulator(
              v.emulators,
              settings.perSystemConfigurations
                  .firstWhereOrNull((e) => e.system == v.id))))
      .toList();
}

Emulator defaultEmulator(
    List<Emulator> emulators, AlternativeEmulator? alternativeEmulator) {
  if (alternativeEmulator != null) {
    final alternative =
        emulators.firstWhereOrNull((e) => e.id == alternativeEmulator.emulator);
    if (alternative != null) {
      return alternative;
    }
  }
  return emulators.first;
}
