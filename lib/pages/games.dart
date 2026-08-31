import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:android_intent_plus/android_intent.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:titanius/data/emulators.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/widgets/fade_image_to_video.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/retroachievements_matcher.dart';
import 'package:titanius/data/retroachievements.dart';
import 'package:titanius/widgets/appbar.dart';
import 'package:titanius/widgets/info_tile.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/selected_scroll_tile.dart';

const double verticalSpacing = 4;

class GamesPage extends HookConsumerWidget {
  final String system;
  const GamesPage({super.key, required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(filteredGamesInFolderProvider(system));
    final selectedGame = ref.watch(selectedGameProvider(system));
    final settings = ref.watch(settingsProvider);

    final showDetails = useState(false);
    final detailsScrollController = useScrollController();

    final currentGamelist = games.value;
    final currentSelectedIndex = (currentGamelist != null && currentGamelist.games.isNotEmpty)
        ? findGame(currentGamelist, selectedGame)
        : -1;
    final currentGameToShow =
        (currentGamelist != null && currentSelectedIndex >= 0 && currentSelectedIndex < currentGamelist.games.length)
        ? currentGamelist.games[currentSelectedIndex]
        : null;

    useEffect(() {
      final auth = ref.read(retroAchievementsAuthProvider);
      if (currentGameToShow == null || !currentGameToShow.system.hasRetroAchievements || auth == null) {
        return null;
      }
      final repo = ref.read(gameRetroAchievementsRepoProvider);
      final cacheRepo = ref.read(retroAchievementsCacheRepoProvider);
      final progressNotifier = ref.read(retroAchievementsProgressMapProvider.notifier);

      final timer = Timer(const Duration(milliseconds: 500), () async {
        if (!context.mounted) return;
        final entry = await repo.getEntry(currentGameToShow.romPath);
        if (!context.mounted) return;
        if (entry != null && entry.raGameId != null && entry.numAchievements > 0) {
          final raGameId = entry.raGameId!;
          if (progressNotifier.has(raGameId)) return;

          final res = await fetchGameInfoAndUserProgressWithCache(
            auth: auth,
            gameId: raGameId,
            cacheRepo: cacheRepo,
            allowNetwork: true,
          );
          if (!context.mounted) return;
          if (res != null) {
            progressNotifier.set(raGameId, res);
            ref.invalidate(gameRetroAchievementsDetailsProvider(raGameId));
          }
        }
      });
      return () => timer.cancel();
    }, [currentGameToShow?.romPath]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (detailsScrollController.hasClients) {
          detailsScrollController.jumpTo(0);
        }
      });
      return null;
    }, [selectedGame?.hash, showDetails.value]);

    useEffect(() {
      if (system == "recent") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          // ignore: unused_result
          ref.refresh(recentGamesProvider);
          ref.read(selectedGameProvider(system).notifier).state = null;
        });
      }
      return null;
    }, const []);

    useEffect(() {
      final gamelist = games.value;
      if (gamelist != null && gamelist.system.hasRetroAchievements) {
        final repo = ref.read(gameRetroAchievementsRepoProvider);
        scanSystemRetroAchievements(
          system: gamelist.system,
          games: gamelist.games,
          repo: repo,
          onUpdated: () {
            if (!context.mounted) return;
            ref.invalidate(systemRetroAchievementsProvider((system: gamelist.system, games: gamelist.games)));
          },
        );
      }
      return null;
    }, [games.value?.system.id, games.value?.currentFolder, games.value?.games.length]);

    useGamepadChord(ref, (location, key, pressed) {
      if (location != "/games/$system") return;
      if (key == GamepadButton.up) {
        final gamelist = games.value;
        if (gamelist != null && gamelist.games.isNotEmpty) {
          final selectedIndex = findGame(gamelist, ref.read(selectedGameProvider(system)));
          if (selectedIndex > 0) {
            final newIndex = selectedIndex - 1;
            ref.read(selectedGameProvider(system).notifier).state = gamelist.games[newIndex];
          }
        }
      }
      if (key == GamepadButton.down) {
        final gamelist = games.value;
        if (gamelist != null && gamelist.games.isNotEmpty) {
          final selectedIndex = findGame(gamelist, ref.read(selectedGameProvider(system)));
          if (selectedIndex < gamelist.games.length - 1) {
            final newIndex = selectedIndex + 1;
            ref.read(selectedGameProvider(system).notifier).state = gamelist.games[newIndex];
          }
        }
      }
      if (key == GamepadButton.confirm) {
        final gamelist = games.value;
        if (gamelist != null && gamelist.games.isNotEmpty) {
          final selectedIndex = findGame(gamelist, ref.read(selectedGameProvider(system)));
          final game = gamelist.games[selectedIndex];
          if (game.isFolder) {
            ref.read(currentGameNavigationProvider(system).notifier).moveIntoFolder(game);
            ref.read(selectedGameProvider(system).notifier).state = null;
          } else {
            _launchGame(ref, game);
          }
        }
      }
      if (key == GamepadButton.l1 || key == GamepadButton.r1) {
        final gamelist = games.value;
        if (gamelist == null || gamelist.games.isEmpty) return;
        const pageSize = 10;
        final current = findGame(gamelist, ref.read(selectedGameProvider(system)));
        final index = key == GamepadButton.l1
            ? max(current - pageSize, 0)
            : min(gamelist.games.length - 1, current + pageSize);
        debugPrint("Go to index=$index page=$pageSize");
        ref.read(selectedGameProvider(system).notifier).state = gamelist.games[index];
      }
      if (key == GamepadButton.l2 || key == GamepadButton.r2) {
        final allSystems = ref.read(loadedSystemsProvider).value ?? [];
        if (allSystems.isNotEmpty) {
          final currentIdx = allSystems.indexWhere((s) => s.id == system);
          if (currentIdx != -1) {
            final nextIdx = key == GamepadButton.r2
                ? (currentIdx + 1) % allSystems.length
                : (currentIdx - 1 + allSystems.length) % allSystems.length;
            ref.read(selectedSystemProvider.notifier).state = nextIdx;
            GoRouter.of(context).go("/games/${allSystems[nextIdx].id}");
          }
        }
      }
      if (key == GamepadButton.back) {
        final navigation = ref.read(currentGameNavigationProvider(system));
        debugPrint("Back: $navigation");
        if (navigation.isAtRoot) {
          GoRouter.of(context).go("/");
        } else {
          Game game = ref.read(currentGameNavigationProvider(system).notifier).goBack();
          ref.read(selectedGameProvider(system).notifier).state = game;
        }
      }
      if (key == GamepadButton.l3 || key == GamepadButton.r3) {
        final gamelist = games.value;
        if (gamelist != null && gamelist.games.isNotEmpty) {
          final selectedIndex = findGame(gamelist, ref.read(selectedGameProvider(system)));
          final selectedGame = gamelist.games[selectedIndex];
          if (!selectedGame.isFolder && selectedGame.system.hasRetroAchievements) {
            ref.read(selectedGameProvider(system).notifier).state = selectedGame;
            GoRouter.of(context).push("/games/$system/game/${selectedGame.hash}/achievements");
            return;
          }
        }
      }
      if (key == GamepadButton.x) {
        showDetails.value = !showDetails.value;
      }
      if (key == GamepadButton.rightStickUp || key == GamepadButton.rightStickDown) {
        if (!showDetails.value || !detailsScrollController.hasClients) return;
        const scrollStep = 56.0;
        final delta = key == GamepadButton.rightStickUp ? -scrollStep : scrollStep;
        final position = detailsScrollController.position;
        final target = (detailsScrollController.offset + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        detailsScrollController.jumpTo(target);
      }
      if (key == GamepadButton.select) {
        final currentFilter = ref.read(currentGameFilterProvider(system));
        ref.read(temporaryGameFilterProvider(system).notifier).set(currentFilter);
        GoRouter.of(context).go("/games/$system/filter");
      }
      if (key == GamepadButton.y) {
        final gamelist = games.value;
        if (gamelist != null && gamelist.games.isNotEmpty) {
          final selectedIndex = findGame(gamelist, ref.read(selectedGameProvider(system)));
          final selectedGame = gamelist.games[selectedIndex];
          if (!selectedGame.isFolder) {
            ref.read(selectedGameProvider(system).notifier).state = selectedGame;
            GoRouter.of(context).push("/games/$system/game/${selectedGame.hash}");
          }
        }
      }
      if (key == GamepadButton.start) {
        GoRouter.of(context).push("/settings?source=$system");
      }
    });

    final currentFilter = ref.watch(currentGameFilterProvider(system));
    final gamelistData = games.value;
    final currentSelectedGame = ref.watch(selectedGameProvider(system));
    final selectedIdx = (gamelistData != null && gamelistData.games.isNotEmpty)
        ? findGame(gamelistData, currentSelectedGame)
        : -1;
    final selectedGameToShow = (gamelistData != null && selectedIdx >= 0 && selectedIdx < gamelistData.games.length)
        ? gamelistData.games[selectedIdx]
        : null;
    final systemAchievementsMap = (gamelistData?.system.hasRetroAchievements ?? false)
        ? (ref
                  .watch(systemRetroAchievementsProvider((system: gamelistData!.system, games: gamelistData.games)))
                  .value ??
              const <String, GameRetroAchievements>{})
        : const <String, GameRetroAchievements>{};
    final selectedGameRa = selectedGameToShow != null ? systemAchievementsMap[selectedGameToShow.romPath] : null;
    final hasRaForSelected = selectedGameRa?.raGameId != null && (selectedGameRa?.numAchievements ?? 0) > 0;

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: PromptBar(
        navigations: [
          const GamepadPrompt([GamepadButton.l1, GamepadButton.r1], "Scroll"),
          const GamepadPrompt([GamepadButton.l2, GamepadButton.r2], "System"),
          GamepadPrompt(const [GamepadButton.select], "Filter: ${currentFilter.description}"),
          const GamepadPrompt([GamepadButton.start], "Menu"),
        ],
        actions: [
          if (hasRaForSelected) const GamepadPrompt([GamepadButton.l3], "Achievements"),
          const GamepadPrompt([GamepadButton.x], "Details"),
          const GamepadPrompt([GamepadButton.y], "Settings"),
          const GamepadPrompt([GamepadButton.back], "Back"),
          const GamepadPrompt([GamepadButton.confirm], "Launch"),
        ],
      ),
      body: games.when(
        data: (gamelist) {
          if (gamelist.games.isEmpty) {
            return const Center(child: Text("No games found"));
          }
          final selectedIndex = findGame(gamelist, selectedGame);
          final gameToShow = gamelist.games[selectedIndex];
          debugPrint("Selected game is $selectedIndex: ${gameToShow.rom}");
          final systemRaMap = systemAchievementsMap;

          return Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: _systemLogo(gamelist.system),
                    ),
                    Expanded(
                      child: ControllerListView.builder(
                        key: PageStorageKey("$system/${gamelist.currentFolder}"),
                        selectedIndex: selectedIndex,
                        itemCount: gamelist.games.length,
                        itemBuilder: (context, index) {
                          final game = gamelist.games[index];
                          final isSelected = index == selectedIndex;
                          final gameRa = systemRaMap[game.romPath];
                          final hasRa = gameRa?.raGameId != null && (gameRa?.numAchievements ?? 0) > 0;
                          final progressMap = ref.watch(retroAchievementsProgressMapProvider);
                          final gameProgress = (hasRa && gameRa?.raGameId != null)
                              ? progressMap[gameRa!.raGameId!]
                              : null;
                          final isMastered = gameProgress?.isMastered ?? false;
                          final isCompleted = gameProgress?.isCompleted ?? false;

                          final textScaler = MediaQuery.textScalerOf(context);
                          final fontScale = textScaler.scale(1.0);
                          final iconSize = (14.0 * fontScale).clamp(12.0, 32.0);

                          return SelectedScrollTile(
                            isSelected: isSelected,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              child: Material(
                                color: isSelected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                child: ListTile(
                                  key: ValueKey(game.romPath),
                                  visualDensity: VisualDensity.compact,
                                  horizontalTitleGap: 4,
                                  minLeadingWidth: 18 * fontScale,
                                  minVerticalPadding: 0,
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  leading: game.isFolder
                                      ? Icon(Icons.folder, size: iconSize, color: isSelected ? Colors.black : Colors.white)
                                      : game.hidden
                                      ? Icon(
                                          Icons.visibility_off_rounded,
                                          size: iconSize,
                                          color: isSelected ? Colors.black : Colors.grey,
                                        )
                                      : system != "favourites" && game.favorite
                                      ? Icon(
                                          Icons.star,
                                          size: iconSize,
                                          color: isSelected ? Colors.black : Colors.orangeAccent,
                                        )
                                      : null,
                                  selected: isSelected,
                                  selectedColor: Colors.black,
                                  selectedTileColor: Colors.transparent,
                                  trailing: hasRa
                                      ? Icon(
                                          const IconData(0x1F3C6, fontFamily: "Prompt"),
                                          size: iconSize,
                                          color: isSelected
                                              ? Colors.black87
                                              : (isMastered
                                                  ? Colors.amberAccent
                                                  : (isCompleted ? Colors.lightBlueAccent : Colors.white70)),
                                        )
                                      : null,
                                  title: Text(
                                    game.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: gamelist.system.isCollection
                                      ? Text(
                                          game.system.name,
                                          maxLines: 1,
                                          style: TextStyle(color: isSelected ? Colors.black87 : Colors.grey),
                                        )
                                      : null,
                                  onTap: () {
                                    ref.read(selectedGameProvider(system).notifier).state = game;
                                    if (game.isFolder) {
                                      ref.read(currentGameNavigationProvider(system).notifier).moveIntoFolder(game);
                                      ref.read(selectedGameProvider(system).notifier).state = null;
                                    } else {
                                      _launchGame(ref, game);
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 8,
                child: Container(
                  //color: Colors.black.brighten(10),
                  padding: const EdgeInsets.all(8.0),
                  child: gameToShow.isFolder
                      ? _gameFolder(ref, context, gameToShow)
                      : _gameDetails(
                          ref,
                          context,
                          settings,
                          gameToShow,
                          systemRaMap[gameToShow.romPath],
                          showDetails,
                          detailsScrollController,
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }

  void _launchGame(WidgetRef ref, Game game) async {
    await ref.read(recentGamesRepoProvider).saveRecentGame(game);
    final gameEmulator = await ref.read(perGameConfigurationProvider(game).future);
    final customEmulators = await ref.read(customEmulatorsProvider.future);
    if (gameEmulator != null && gameEmulator.emulator != "default") {
      final emulators = [...game.system.builtInEmulators, ...customEmulators.map((e) => e.toEmulator())];
      final emulator = emulators.firstWhereOrNull((element) => element.id == gameEmulator.emulator);
      _launchGameWithEmulator(emulator, game);
    } else {
      final alternativeEmulators = await ref.read(alternativeEmulatorsProvider.future);
      final emulators = alternativeEmulators.firstWhereOrNull((element) => element.system.id == game.system.id);
      final emulator = emulators?.defaultEmulator;
      _launchGameWithEmulator(emulator, game);
    }
  }

  void _launchGameWithEmulator(Emulator? emulator, Game game) {
    debugPrint("Launching ${game.absoluteRomPath} with ${emulator?.id}");
    emulator?.intent.toIntent(game).then((intent) => intent.launch().catchError(handleIntentError(intent)));
  }

  Widget _gameFolder(WidgetRef ref, BuildContext context, Game gameToShow) {
    final gamesInFolder = ref
        .read(gamesProvider(system))
        .value!
        .games
        .where((game) => game.folder == gameToShow.rom && game.imageUrl != null)
        .toList();
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: gamesInFolder.length,
        itemBuilder: (context, index) {
          final game = gamesInFolder[index];
          return Column(
            children: [
              Expanded(
                child: Image.file(File(game.imageUrl!), fit: BoxFit.contain, filterQuality: FilterQuality.none),
              ),
              Text(game.name, softWrap: false),
            ],
          );
        },
      ),
    );
  }

  Widget _gameDetails(
    WidgetRef ref,
    BuildContext context,
    AsyncValue<Settings> settings,
    Game gameToShow,
    GameRetroAchievements? gameRa,
    ValueNotifier<bool> showDetails,
    ScrollController detailsScrollController,
  ) {
    if (showDetails.value) {
      return _gameDetailsLong(ref, context, gameToShow, gameRa, detailsScrollController);
    } else {
      return _gameDetailsShort(ref, context, settings, gameToShow, gameRa);
    }
  }

  Widget _gameDetailsShort(
    WidgetRef ref,
    BuildContext context,
    AsyncValue<Settings> settings,
    Game gameToShow,
    GameRetroAchievements? gameRa,
  ) {
    final resolvedRa = gameRa ?? ref.watch(gameRetroAchievementsProvider(gameToShow)).value;
    final hasRa = resolvedRa?.raGameId != null && (resolvedRa?.numAchievements ?? 0) > 0;
    final textScaler = MediaQuery.textScalerOf(context);
    final fontScale = textScaler.scale(1.0);
    final starScale = 1.0 + (fontScale - 1.0) * 0.5;
    final starSize = 18.0 * starScale;
    final trophyIconSize = 10.0 * starScale;

    final progressMap = ref.watch(retroAchievementsProgressMapProvider);
    final progress = (hasRa && resolvedRa?.raGameId != null)
        ? (progressMap[resolvedRa!.raGameId!] ??
              ref.watch(gameRetroAchievementsDetailsProvider(resolvedRa.raGameId!)).value)
        : null;

    final String raText;
    if (progress != null) {
      final earnedPts = progress.userEarnedPoints;
      final totalPts = progress.calculatedTotalPoints > 0 ? progress.calculatedTotalPoints : resolvedRa!.points;
      raText = "${progress.numAwardedToUser}/${resolvedRa!.numAchievements} • $earnedPts/$totalPts pts";
    } else if (hasRa) {
      raText = "${resolvedRa!.numAchievements}";
    } else {
      raText = "";
    }

    final isMastered = progress?.isMastered ?? false;
    final isCompleted = progress?.isCompleted ?? false;
    final badgeColor = isMastered
        ? Colors.amberAccent
        : (isCompleted ? Colors.lightBlueAccent : Colors.white70);
    final badgeBgColor = isMastered
        ? Colors.amber.withValues(alpha: 0.15)
        : (isCompleted
            ? Colors.lightBlue.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08));
    final badgeBorderColor = isMastered
        ? Colors.amberAccent.withValues(alpha: 0.4)
        : (isCompleted
            ? Colors.lightBlueAccent.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.2));
    const glyph = "\u{1F3C6}";

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (gameToShow.thumbnailUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SizedBox(
              height: 48,
              child: Image.file(
                File(gameToShow.thumbnailUrl!),
                fit: BoxFit.fitHeight,
                filterQuality: FilterQuality.none,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              gameToShow.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: settings.when(
            data: (settings) => settings.showGameVideos && gameToShow.videoUrl != null
                ? _gameVideo(settings, gameToShow)
                : _gameImage(gameToShow),
            error: (_, _) => _gameImage(gameToShow),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: 6),
        RatingBarIndicator(
          rating: (gameToShow.rating ?? 0) / 2,
          itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
          itemCount: 5,
          itemSize: starSize,
          direction: Axis.horizontal,
        ),
        if (hasRa) ...[
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              GoRouter.of(context).push("/games/${gameToShow.system.id}/game/${gameToShow.hash}/achievements");
            },
            child: Container(
              height: (22.0 * fontScale).clamp(20.0, 32.0),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: badgeBorderColor, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    glyph,
                    style: TextStyle(
                      fontFamily: "Prompt",
                      fontSize: trophyIconSize,
                      color: badgeColor,
                      height: 1.0,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    raText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                      height: 1.0,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _gameImage(Game gameToShow) {
    return gameToShow.imageUrl != null
        ? Image.file(File(gameToShow.imageUrl!), filterQuality: FilterQuality.none, fit: BoxFit.contain)
        : const Text("No image");
  }

  Widget _gameVideo(Settings settings, Game gameToShow) {
    return FadeImageToVideo(key: ValueKey(gameToShow.absoluteRomPath), game: gameToShow, settings: settings);
  }

  Widget _gameDetailsLong(
    WidgetRef ref,
    BuildContext context,
    Game gameToShow,
    GameRetroAchievements? gameRa,
    ScrollController detailsScrollController,
  ) {
    final resolvedRa = gameRa ?? ref.watch(gameRetroAchievementsProvider(gameToShow)).value;
    final hasRa = resolvedRa?.raGameId != null && (resolvedRa?.numAchievements ?? 0) > 0;
    final textScaler = MediaQuery.textScalerOf(context);
    final fontScale = textScaler.scale(1.0);
    final starScale = 1.0 + (fontScale - 1.0) * 0.5;
    final starSize = 18.0 * starScale;
    final trophyIconSize = 11.0 * starScale;

    final progressMap = ref.watch(retroAchievementsProgressMapProvider);
    final progress = (hasRa && resolvedRa?.raGameId != null)
        ? (progressMap[resolvedRa!.raGameId!] ??
              ref.watch(gameRetroAchievementsDetailsProvider(resolvedRa.raGameId!)).value)
        : null;

    final String raText;
    if (progress != null) {
      final earnedPts = progress.userEarnedPoints;
      final totalPts = progress.calculatedTotalPoints > 0 ? progress.calculatedTotalPoints : resolvedRa!.points;
      raText = "${progress.numAwardedToUser}/${resolvedRa!.numAchievements} • $earnedPts/$totalPts pts";
    } else if (hasRa) {
      raText = "${resolvedRa!.numAchievements}";
    } else {
      raText = "";
    }
    final isMastered = progress?.isMastered ?? false;
    final isCompleted = progress?.isCompleted ?? false;
    final badgeColor = isMastered
        ? Colors.amberAccent
        : (isCompleted ? Colors.lightBlueAccent : Colors.white70);
    final badgeBgColor = isMastered
        ? Colors.amber.withValues(alpha: 0.15)
        : (isCompleted
            ? Colors.lightBlue.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08));
    final badgeBorderColor = isMastered
        ? Colors.amberAccent.withValues(alpha: 0.4)
        : (isCompleted
            ? Colors.lightBlueAccent.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.2));
    const glyph = "\u{1F3C6}";

    return Scrollbar(
      controller: detailsScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: detailsScrollController,
        child: Column(
          children: [
            gameToShow.thumbnailUrl != null
                ? SizedBox(
                    height: 60,
                    child: Image.file(
                      File(gameToShow.thumbnailUrl!),
                      fit: BoxFit.fitHeight,
                      filterQuality: FilterQuality.none,
                    ),
                  )
                : Text(gameToShow.name, textScaler: const TextScaler.linear(2)),
            Text(gameToShow.rom),
            const SizedBox(height: 4),
            RatingBarIndicator(
              rating: (gameToShow.rating ?? 0) / 2,
              itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: starSize,
              direction: Axis.horizontal,
            ),
            if (hasRa) ...[
              const SizedBox(height: 4),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  GoRouter.of(context).push("/games/${gameToShow.system.id}/game/${gameToShow.hash}/achievements");
                },
                child: Container(
                  height: (22.0 * fontScale).clamp(20.0, 32.0),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeBorderColor, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        glyph,
                        style: TextStyle(
                          fontFamily: "Prompt",
                          fontSize: trophyIconSize,
                          color: badgeColor,
                          height: 1.0,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        raText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                          height: 1.0,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            gameToShow.players != null ? Text("Players: ${gameToShow.players}") : const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(gameToShow.description ?? "No description", style: const TextStyle(color: Colors.grey)),
            ),
            InfoTiles(
              columnCount: 1,
              children: [
                if (hasRa)
                  InfoTile(
                    title: "Achievements",
                    subtitle: "${resolvedRa!.numAchievements} (${resolvedRa.points} pts)",
                  ),
                InfoTile(title: "Genre", subtitle: gameToShow.genreToShow),
                InfoTile(title: "Released", subtitle: gameToShow.year?.toString() ?? "-"),
                InfoTile(title: "Developer", subtitle: gameToShow.developer ?? "-"),
                InfoTile(title: "Publisher", subtitle: gameToShow.publisher ?? "-"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemLogo(System system) {
    switch (system.id) {
      case "favourites":
        return _collectionLogo("\u{2605}", "Favourites", glyphYOffset: -6.0);
      case "recent":
        return _collectionLogo("\u{23F2}", "Recent");
      case "all":
        return _collectionLogo("\u{1F579}", "All Games");
      case "no_metadata":
        return _collectionLogo("\u{2753}", "No Metadata");
      default:
        return Image.asset(
          "assets/images/white/${system.logo}",
          fit: BoxFit.fitHeight,
          filterQuality: FilterQuality.none,
          errorBuilder: (context, url, error) => const Icon(Icons.error),
        );
    }
  }

  Widget _collectionLogo(String glyph, String text, {double glyphYOffset = -2.0}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.translate(
          offset: Offset(0, glyphYOffset),
          child: Text(
            glyph,
            style: const TextStyle(
              fontFamily: "Prompt",
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontFamily: "KarenFat",
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  int findGame(GameList? gamelist, Game? selectedGame) {
    if (gamelist == null || gamelist.games.isEmpty) {
      return 0;
    }
    if (selectedGame == null) {
      return 0;
    }
    final index = gamelist.indexOf(selectedGame);
    if (index != -1) {
      return index;
    }
    return 0;
  }
}

Function handleIntentError(AndroidIntent intent) {
  return (err) {
    debugPrint(err.toString());
    Fluttertoast.showToast(
      msg: "Unable to run ${intent.package}. Please make sure the app is installed.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  };
}
