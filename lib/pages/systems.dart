import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';

import '../data/games.dart';
import '../data/models.dart';
import '../data/state.dart';
import '../data/systems.dart';
import '../gamepad.dart';
import '../widgets/appbar.dart';
import '../widgets/prompt_bar.dart';

class SystemsPage extends HookConsumerWidget {
  const SystemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSystems = ref.watch(detectedSystemsProvider);
    final selectedSystem = ref.watch(selectedSystemProvider);
    final pageController = PageController(initialPage: selectedSystem);

    final games = ref.watch(gamesForCurrentSystemProvider);

    // Forces games loading in background
    games.whenData((games) {
      debugPrint("Games: ${games.games.length}");
    });

    useGamepad(ref, (location, key) {
      if (location != "/") return;
      if (allSystems.value == null || allSystems.value!.isEmpty) return;
      if (key == GamepadButton.r1 || key == GamepadButton.r2 || key == GamepadButton.right) {
        final currentSystem = ref.read(selectedSystemProvider);
        final next = (currentSystem + 1) % allSystems.value!.length;
        pageController.animateToPage(next, duration: const Duration(milliseconds: 200), curve: Curves.ease);
      }
      if (key == GamepadButton.l1 || key == GamepadButton.l2 || key == GamepadButton.left) {
        final currentSystem = ref.read(selectedSystemProvider);
        final prev = currentSystem - 1 < 0 ? allSystems.value!.length - 1 : currentSystem - 1;
        pageController.animateToPage(prev, duration: const Duration(milliseconds: 200), curve: Curves.ease);
      }
      if (key == GamepadButton.a) {
        final currentSystemIndex = ref.read(selectedSystemProvider);
        final system = allSystems.value![currentSystemIndex];
        GoRouter.of(context).go("/games/${system.id}");
      }
      if (key == GamepadButton.start) {
        GoRouter.of(context).go("/settings?source=root");
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.leftRight], "Choose"),
          GamepadPrompt([GamepadButton.start], "Menu"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.a], "Select"),
        ],
      ),
      body: allSystems.when(
        data: (systems) {
          return Stack(
            children: [
              PageView.builder(
                onPageChanged: (value) {
                  ref.read(selectedSystemProvider.notifier).set(value);
                },
                controller: pageController,
                itemCount: systems.length,
                itemBuilder: (context, index) {
                  if (index >= systems.length) return Container();
                  final system = systems[index];
                  return Row(children: [
                    const Spacer(flex: 1),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => GoRouter.of(context).go("/games/${system.id}"),
                        child: _systemLogo(system),
                      ),
                    ),
                    const Spacer(flex: 1),
                  ]);
                },
              ),
              systems.isNotEmpty
                  ? Container(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          games.when(
                              data: (games) => _gamesStats(games),
                              error: (error, stackTrace) => const Text("Error loading games"),
                              loading: () => Container()),
                          const SizedBox(height: 8),
                          PageViewDotIndicator(
                            currentItem: selectedSystem < systems.length ? selectedSystem : 0,
                            count: systems.length,
                            unselectedColor: Theme.of(context).colorScheme.background.lighten(10),
                            selectedColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    )
                  : Container(),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }

  Widget _systemLogo(System system) {
    switch (system.id) {
      case "favourites":
        return _collectionLogo(Icons.star_rounded, Colors.orangeAccent, "Favourites");
      case "recent":
        return _collectionLogo(Icons.history_rounded, Colors.redAccent, "Recent");
      case "all":
        return _collectionLogo(Icons.apps_rounded, Colors.indigoAccent, "All Games");
      default:
        return Image.asset(
          "assets/images/color/${system.logo}",
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          errorBuilder: (context, url, error) => const Icon(Icons.error),
        );
    }
  }

  Widget _collectionLogo(IconData icon, Color iconColor, String text) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 80,
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 80)),
        ],
      ),
    );
  }

  Widget _gamesStats(GameList games) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("${games.games.length}", style: const TextStyle(color: Colors.white, fontSize: 20)),
        const Text(
          " games",
          style: TextStyle(color: Colors.grey, fontSize: 20),
        ),
      ],
    );
  }
}
