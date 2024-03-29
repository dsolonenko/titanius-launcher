import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';
import 'package:preload_page_view/preload_page_view.dart';

import 'package:titanius/data/daijisho.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/appbar.dart';
import 'package:titanius/widgets/prompt_bar.dart';

class SystemsPage extends HookConsumerWidget {
  const SystemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSystems = ref.watch(loadedSystemsProvider);
    final selectedSystem = ref.watch(selectedSystemProvider);
    final wallpaperPack = ref.watch(daijishoCurrentThemeDataProvider);
    final games = ref.watch(gamesForCurrentSystemProvider);

    final pageController = PreloadPageController(initialPage: selectedSystem);

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
        pageController.jumpToPage(next);
      }
      if (key == GamepadButton.l1 || key == GamepadButton.l2 || key == GamepadButton.left) {
        final currentSystem = ref.read(selectedSystemProvider);
        final prev = currentSystem - 1 < 0 ? allSystems.value!.length - 1 : currentSystem - 1;
        pageController.jumpToPage(prev);
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
      extendBody: true,
      extendBodyBehindAppBar: true,
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
        data: (systems) => wallpaperPack.when(
          data: (wallpaperPack) {
            return Stack(
              children: [
                PreloadPageView.builder(
                  onPageChanged: (value) {
                    ref.read(selectedSystemProvider.notifier).set(value);
                  },
                  preloadPagesCount: systems.length,
                  controller: pageController,
                  itemCount: systems.length,
                  itemBuilder: (context, index) {
                    if (index >= systems.length) return Container();
                    final system = systems[index];
                    return GestureDetector(
                      onTap: () => GoRouter.of(context).go("/games/${system.id}"),
                      child: _systemLogo(ref, context, system, wallpaperPack),
                    );
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
                                data: (games) => _gamesStats(context, games),
                                error: (error, stackTrace) => const Text("Error loading games"),
                                loading: () => Container()),
                            const SizedBox(height: 8),
                            PageViewDotIndicator(
                              size: const Size(8, 8),
                              unselectedSize: const Size(8, 8),
                              currentItem: selectedSystem < systems.length ? selectedSystem : 0,
                              count: systems.length,
                              unselectedColor: Theme.of(context).colorScheme.background.lighten(10),
                              selectedColor: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      )
                    : Container(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text(error.toString()),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }

  Widget _systemLogo(WidgetRef ref, BuildContext context, System system, WallpaperPack? wallpaperPack) {
    switch (system.id) {
      case "favourites":
        return _textLogo(context, Icons.star_rounded, Colors.orangeAccent, "Favourites");
      case "recent":
        return _textLogo(context, Icons.history_rounded, Colors.redAccent, "Recent");
      case "all":
        return _textLogo(context, Icons.apps_rounded, Colors.indigoAccent, "All Games");
      default:
        if (wallpaperPack != null) {
          final wallpaper =
              wallpaperPack.wallpaperList.firstWhereOrNull((element) => element.matchPlatformShortname == system.id);
          if (wallpaper != null) {
            final imageUrl = wallpaper.imageUrl(wallpaperPack.rootPath);
            return _cachedImage(imageUrl);
          } else {
            if (wallpaperPack.hasDefaultWallpaper) {
              final imageUrl = wallpaperPack.defaultWallpaperUrl(wallpaperPack.rootPath);
              return _cachedImage(imageUrl);
            } else {
              return _textLogo(context, Icons.gamepad_rounded, Theme.of(context).primaryColor, system.name);
            }
          }
        } else {
          return Row(
            children: [
              const Expanded(flex: 1, child: SizedBox()),
              Expanded(
                flex: 4,
                child: Image.asset(
                  "assets/images/color/${system.logo}",
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  isAntiAlias: true,
                  errorBuilder: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              const Expanded(flex: 1, child: SizedBox()),
            ],
          );
        }
    }
  }

  CachedNetworkImage _cachedImage(String imageUrl) {
    return CachedNetworkImage(
      key: ValueKey(imageUrl),
      imageUrl: imageUrl,
      filterQuality: FilterQuality.medium,
      fit: BoxFit.fill,
    );
  }

  Widget _textLogo(BuildContext context, IconData icon, Color iconColor, String text) {
    return Row(
      children: [
        const Expanded(flex: 1, child: SizedBox()),
        Expanded(
          flex: 4,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor),
                Text(text, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        const Expanded(flex: 1, child: SizedBox()),
      ],
    );
  }

  Widget _gamesStats(BuildContext context, GameList games) {
    if (games.games.isEmpty) return Container();
    return Text(
      "${games.games.length} games",
      style: const TextStyle(color: Colors.white, fontSize: 20),
    );
  }
}
