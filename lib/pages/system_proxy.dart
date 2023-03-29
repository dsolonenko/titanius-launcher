import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titanius/pages/games.dart';

import '../data/games.dart';
import '../data/settings.dart';
import '../data/state.dart';
import '../data/systems.dart';
import '../gamepad.dart';
import 'android.dart';

class SystemProxy extends HookConsumerWidget {
  final String system;
  const SystemProxy(this.system, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSystems = ref.watch(detectedSystemsProvider);

    useGamepad(ref, (location, key) {
      if (location != "/games/$system") return;
      if (allSystems.value == null || allSystems.value!.isEmpty) return;
      if (key == GamepadButton.r2 || key == GamepadButton.r1) {
        final currentSystem = ref.read(selectedSystemProvider);
        final next = (currentSystem + 1) % allSystems.value!.length;
        ref.read(selectedSystemProvider.notifier).set(next);
        GoRouter.of(context).go("/games/${allSystems.value![next].id}");
      }
      if (key == GamepadButton.l2 || key == GamepadButton.l1) {
        final currentSystem = ref.read(selectedSystemProvider);
        final prev = currentSystem - 1 < 0
            ? allSystems.value!.length - 1
            : currentSystem - 1;
        ref.read(selectedSystemProvider.notifier).set(prev);
        GoRouter.of(context).go("/games/${allSystems.value![prev].id}");
      }
      if (key == GamepadButton.y) {
        if (system == "android") {
        } else {
          _favouriteCurrentGame(ref);
        }
      }
      if (key == GamepadButton.start) {
        GoRouter.of(context).push("/settings");
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/");
      }
    });

    if (system == "android") {
      return const AndroidPage();
    } else {
      return GamesPage(system);
    }
  }

  void _favouriteCurrentGame(WidgetRef ref) {
    final games = ref.read(gamesProvider(system)).value!;
    final selectedGameIndex = ref.read(selectedGameProvider(system));
    final game = games.games[selectedGameIndex];
    ref
        .read(settingsRepoProvider)
        .value!
        .saveFavourite(game.romPath, !game.favorite)
        .then((value) => ref.refresh(settingsProvider));
  }
}
