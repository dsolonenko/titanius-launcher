import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titanius/pages/games.dart';

import '../data/state.dart';
import '../data/systems.dart';
import '../gamepad.dart';
import 'android.dart';

class SystemProxy extends HookConsumerWidget {
  final String system;
  const SystemProxy({super.key, required this.system});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSystems = ref.watch(detectedSystemsProvider);

    useGamepad(ref, (location, key) {
      if (!location.startsWith("/games/$system")) return;
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
      if (key == GamepadButton.start) {
        GoRouter.of(context).push("/settings");
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
