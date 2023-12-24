import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titanius/data/games.dart';

import 'package:titanius/pages/android.dart';
import 'package:titanius/pages/games.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/gamepad.dart';

class SystemProxy extends HookConsumerWidget {
  final String system;
  const SystemProxy({super.key, required this.system});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSystems = ref.watch(loadedSystemsProvider);

    useGamepad(ref, (location, key) {
      if (location != "/games/$system") return;
      if (allSystems.value == null || allSystems.value!.isEmpty) return;
      if (key == GamepadButton.r2 || (system != "android" && key == GamepadButton.right)) {
        final currentSystem = ref.read(selectedSystemProvider);
        final next = (currentSystem + 1) % allSystems.value!.length;
        ref.read(selectedSystemProvider.notifier).set(next);
        GoRouter.of(context).go("/games/${allSystems.value![next].id}");
      }
      if (key == GamepadButton.l2 || (system != "android" && key == GamepadButton.left)) {
        final currentSystem = ref.read(selectedSystemProvider);
        final prev = currentSystem - 1 < 0 ? allSystems.value!.length - 1 : currentSystem - 1;
        ref.read(selectedSystemProvider.notifier).set(prev);
        GoRouter.of(context).go("/games/${allSystems.value![prev].id}");
      }
      if (key == GamepadButton.start) {
        GoRouter.of(context).go("/settings?source=$system");
      }
    });

    if (system == "android") {
      return const AndroidPage();
    } else {
      return GamesPage(
        system: system,
      );
    }
  }
}
