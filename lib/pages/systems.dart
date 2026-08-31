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
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/appbar.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/retroachievements_card.dart';

class SystemsPage extends HookConsumerWidget {
  const SystemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSystems = ref.watch(loadedSystemsProvider);
    final selectedSystem = ref.watch(selectedSystemProvider);
    final systemStatsEnabled = ref.watch(systemStatsEnabledProvider);
    final wallpaperPack = ref.watch(daijishoCurrentThemeDataProvider);

    final pageController = PreloadPageController(initialPage: selectedSystem);

    useGamepad(ref, (location, key) {
      if (location != "/") return;
      if (allSystems.value == null || allSystems.value!.isEmpty) return;
      if (key == GamepadButton.r1 ||
          key == GamepadButton.r2 ||
          key == GamepadButton.right) {
        ref.read(systemStatsEnabledProvider.notifier).enable();
        final currentSystem = ref.read(selectedSystemProvider);
        final next = (currentSystem + 1) % allSystems.value!.length;
        pageController.jumpToPage(next);
      }
      if (key == GamepadButton.l1 ||
          key == GamepadButton.l2 ||
          key == GamepadButton.left) {
        ref.read(systemStatsEnabledProvider.notifier).enable();
        final currentSystem = ref.read(selectedSystemProvider);
        final prev = currentSystem - 1 < 0
            ? allSystems.value!.length - 1
            : currentSystem - 1;
        pageController.jumpToPage(prev);
      }
      if (key == GamepadButton.confirm) {
        ref.read(systemStatsEnabledProvider.notifier).enable();
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          allSystems.when(
            data: (systems) {
              if (systems.isEmpty) return const SizedBox.shrink();
              final system =
                  systems[selectedSystem.clamp(0, systems.length - 1)];
              return !systemStatsEnabled ||
                      (system.isCollection && !system.isRetroAchievements) ||
                      system.isAndroid
                  ? const SizedBox.shrink()
                  : _SystemStats(system: system);
            },
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
          allSystems.when(
            data: (systems) => systems.isNotEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      PageViewDotIndicator(
                        size: const Size(8, 8),
                        unselectedSize: const Size(8, 8),
                        currentItem: selectedSystem < systems.length
                            ? selectedSystem
                            : 0,
                        count: systems.length,
                        unselectedColor: Theme.of(
                          context,
                        ).colorScheme.surface.lighten(10),
                        selectedColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          const PromptBar(
            navigations: [
              GamepadPrompt([GamepadButton.leftRight], "Choose"),
              GamepadPrompt([GamepadButton.start], "Menu"),
            ],
            actions: [
              GamepadPrompt([GamepadButton.confirm], "Select"),
            ],
          ),
        ],
      ),
      body: allSystems.when(
        data: (systems) => wallpaperPack.when(
          data: (wallpaperPack) {
            return Listener(
              onPointerDown: (_) =>
                  ref.read(systemStatsEnabledProvider.notifier).enable(),
              child: PreloadPageView.builder(
                onPageChanged: (value) {
                  ref.read(selectedSystemProvider.notifier).state = value;
                },
                preloadPagesCount: 1,
                controller: pageController,
                itemCount: systems.length,
                itemBuilder: (context, index) {
                  if (index >= systems.length) return Container();
                  final system = systems[index];
                  return GestureDetector(
                    onTap: () {
                      ref.read(systemStatsEnabledProvider.notifier).enable();
                      GoRouter.of(context).go("/games/${system.id}");
                    },
                    child: _systemLogo(ref, context, system, wallpaperPack),
                  );
                },
              ),
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

  Widget _systemLogo(
    WidgetRef ref,
    BuildContext context,
    System system,
    WallpaperPack? wallpaperPack,
  ) {
    switch (system.id) {
      case "favourites":
        return _textLogo(
          context,
          "\u{2605}",
          Colors.orangeAccent,
          "Favourites",
          glyphYOffset: -10.0,
        );
      case "recent":
        return _textLogo(
          context,
          "\u{23F2}",
          Colors.redAccent,
          "Recent",
        );
      case "all":
        return _textLogo(
          context,
          "\u{1F579}",
          Colors.indigoAccent,
          "All Games",
        );
      case "no_metadata":
        return _textLogo(
          context,
          "\u{2753}",
          Colors.amberAccent,
          "No Metadata",
        );
      case "retroachievements":
        final settings = ref.watch(settingsProvider).value;
        if (settings?.hasRetroAchievements ?? false) {
          return Align(
            alignment: const Alignment(0, -0.28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "\u{1F3C6}",
                        style: TextStyle(
                          fontFamily: "Prompt",
                          fontSize: 32,
                          color: Colors.amberAccent,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "RetroAchievements",
                        style: TextStyle(
                          fontFamily: "KarenFat",
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black),
                            Shadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black87),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  RetroAchievementsPlayerHeaderCard(
                    margin: EdgeInsets.zero,
                  ),
                  SizedBox(height: 6),
                  RetroAchievementsGamesOverviewBar(
                    margin: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          );
        }
        return _textLogo(
          context,
          "\u{1F3C6}",
          Colors.amberAccent,
          "RetroAchievements",
        );
      default:
        if (wallpaperPack != null) {
          final wallpaper = wallpaperPack.wallpaperList.firstWhereOrNull(
            (element) => element.matchPlatformShortname == system.id,
          );
          if (wallpaper != null) {
            final imageUrl = wallpaper.imageUrl(wallpaperPack.rootPath);
            return _cachedImage(imageUrl);
          } else {
            if (wallpaperPack.hasDefaultWallpaper) {
              final imageUrl = wallpaperPack.defaultWallpaperUrl(
                wallpaperPack.rootPath,
              );
              return _cachedImage(imageUrl);
            } else {
              return _textLogo(
                context,
                "\u{243C}",
                Theme.of(context).primaryColor,
                system.name,
              );
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
                  errorBuilder: (context, url, error) =>
                      const Icon(Icons.error),
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
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image_rounded, size: 48),
    );
  }

  Widget _textLogo(
    BuildContext context,
    String glyph,
    Color glyphColor,
    String text, {
    double glyphYOffset = -3.0,
  }) {
    return Row(
      children: [
        const Expanded(flex: 1, child: SizedBox()),
        Expanded(
          flex: 4,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, glyphYOffset),
                    child: Text(
                      glyph,
                      style: TextStyle(
                        fontFamily: "Prompt",
                        fontSize: 36,
                        color: glyphColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: "KarenFat",
                      color: Colors.white,
                      fontSize: 36,
                      shadows: [
                        Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black),
                        Shadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black87),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Expanded(flex: 1, child: SizedBox()),
      ],
    );
  }
}

class _SystemStats extends ConsumerWidget {
  final System system;

  const _SystemStats({required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (system.isRetroAchievements) {
      return const SizedBox.shrink();
    }
    final games = ref.watch(gamesProvider(system.id));
    return games.when(
      data: (value) => value.games.isEmpty
          ? const SizedBox.shrink()
          : Text(
              "${value.games.length} games",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black),
                  Shadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black87),
                  Shadow(offset: Offset(0, 0), blurRadius: 10, color: Colors.black),
                ],
              ),
            ),
      error: (_, _) => const Text("Error loading games"),
      loading: () => const SizedBox.shrink(),
    );
  }
}
