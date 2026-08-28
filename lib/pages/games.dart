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
          // ignore: unused_result
          ref.refresh(recentGamesProvider);
          ref.read(selectedGameProvider(system).notifier).state = null;
        });
      }
      return null;
    }, const []);

    useGamepad(ref, (location, key) {
      if (location != "/games/$system") return;
      if (key == GamepadButton.up) {
        final gamelist = games.value;
        if (gamelist != null && gamelist.games.isNotEmpty) {
          final selectedIndex = findGame(
            gamelist,
            ref.read(selectedGameProvider(system)),
          );
          if (selectedIndex > 0) {
            final newIndex = selectedIndex - 1;
            ref.read(selectedGameProvider(system).notifier).state =
                gamelist.games[newIndex];
          }
        }
      }
      if (key == GamepadButton.down) {
        final gamelist = games.value;
        if (gamelist != null && gamelist.games.isNotEmpty) {
          final selectedIndex = findGame(
            gamelist,
            ref.read(selectedGameProvider(system)),
          );
          if (selectedIndex < gamelist.games.length - 1) {
            final newIndex = selectedIndex + 1;
            ref.read(selectedGameProvider(system).notifier).state =
                gamelist.games[newIndex];
          }
        }
      }
      if (key == GamepadButton.a) {
        final gamelist = games.value;
        if (gamelist != null && gamelist.games.isNotEmpty) {
          final selectedIndex = findGame(
            gamelist,
            ref.read(selectedGameProvider(system)),
          );
          final game = gamelist.games[selectedIndex];
          if (game.isFolder) {
            ref
                .read(currentGameNavigationProvider(system).notifier)
                .moveIntoFolder(game);
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
        final current = findGame(
          gamelist,
          ref.read(selectedGameProvider(system)),
        );
        final index = key == GamepadButton.l1
            ? max(current - pageSize, 0)
            : min(gamelist.games.length - 1, current + pageSize);
        debugPrint("Go to index=$index page=$pageSize");
        ref.read(selectedGameProvider(system).notifier).state =
            gamelist.games[index];
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
      if (key == GamepadButton.b) {
        final navigation = ref.read(currentGameNavigationProvider(system));
        debugPrint("Back: $navigation");
        if (navigation.isAtRoot) {
          GoRouter.of(context).go("/");
        } else {
          Game game = ref
              .read(currentGameNavigationProvider(system).notifier)
              .goBack();
          ref.read(selectedGameProvider(system).notifier).state = game;
        }
      }
      if (key == GamepadButton.x) {
        showDetails.value = !showDetails.value;
      }
      if (key == GamepadButton.rightStickUp ||
          key == GamepadButton.rightStickDown) {
        if (!showDetails.value || !detailsScrollController.hasClients) return;
        const scrollStep = 56.0;
        final delta = key == GamepadButton.rightStickUp
            ? -scrollStep
            : scrollStep;
        final position = detailsScrollController.position;
        final target = (detailsScrollController.offset + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        detailsScrollController.jumpTo(target);
      }
      if (key == GamepadButton.select) {
        final currentFilter = ref.read(currentGameFilterProvider(system));
        ref
            .read(temporaryGameFilterProvider(system).notifier)
            .set(currentFilter);
        GoRouter.of(context).go("/games/$system/filter");
      }
      if (key == GamepadButton.y) {
        final selectedGame = ref.read(selectedGameProvider(system));
        if (selectedGame != null && !selectedGame.isFolder) {
          GoRouter.of(context).push("/games/$system/game/${selectedGame.hash}");
        }
      }
      if (key == GamepadButton.start) {
        GoRouter.of(context).push("/settings?source=$system");
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: PromptBar(
        navigations: const [
          GamepadPrompt([GamepadButton.l1, GamepadButton.r1], "Scroll"),
          GamepadPrompt([GamepadButton.l2, GamepadButton.r2], "System"),
          GamepadPrompt([GamepadButton.select], "Filter"),
          GamepadPrompt([GamepadButton.start], "Menu"),
        ],
        actions: const [
          GamepadPrompt([GamepadButton.x], "Details"),
          GamepadPrompt([GamepadButton.y], "Settings"),
          GamepadPrompt([GamepadButton.b], "Back"),
          GamepadPrompt([GamepadButton.a], "Launch"),
        ],
        text:
            "Filter: ${ref.read(currentGameFilterProvider(system)).description}",
      ),
      body: games.when(
        data: (gamelist) {
          if (gamelist.games.isEmpty) {
            return const Center(child: Text("No games found"));
          }
          final selectedIndex = findGame(gamelist, selectedGame);
          final gameToShow = gamelist.games[selectedIndex];
          debugPrint("Selected game is $selectedIndex: ${gameToShow.rom}");
          return Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: _systemLogo(gamelist.system),
                    ),
                    Expanded(
                      child: ControllerListView.builder(
                        key: PageStorageKey(
                          "$system/${gamelist.currentFolder}",
                        ),
                        selectedIndex: selectedIndex,
                        itemCount: gamelist.games.length,
                        itemBuilder: (context, index) {
                          final game = gamelist.games[index];
                          final isSelected = index == selectedIndex;
                          return SelectedScrollTile(
                            isSelected: isSelected,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              child: Material(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                child: ListTile(
                                  key: ValueKey(game.romPath),
                                  visualDensity: VisualDensity.compact,
                                  horizontalTitleGap: 4,
                                  minLeadingWidth: 18,
                                  minVerticalPadding: 0,
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
                                  leading: game.isFolder
                                      ? Icon(
                                          Icons.folder,
                                          size: 14,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white,
                                        )
                                      : game.hidden
                                      ? Icon(
                                          Icons.visibility_off_rounded,
                                          size: 14,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.grey,
                                        )
                                      : system != "favourites" && game.favorite
                                      ? Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.orangeAccent,
                                        )
                                      : null,
                                  selected: isSelected,
                                  selectedColor: Colors.black,
                                  selectedTileColor: Colors.transparent,
                                  title: Text(
                                    game.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: gamelist.system.isCollection
                                      ? Text(
                                          game.system.name,
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.black87
                                                : Colors.grey,
                                          ),
                                        )
                                      : null,
                                  onTap: () {
                                    ref
                                            .read(
                                              selectedGameProvider(
                                                system,
                                              ).notifier,
                                            )
                                            .state =
                                        game;
                                    if (game.isFolder) {
                                      ref
                                          .read(
                                            currentGameNavigationProvider(
                                              system,
                                            ).notifier,
                                          )
                                          .moveIntoFolder(game);
                                      ref
                                              .read(
                                                selectedGameProvider(
                                                  system,
                                                ).notifier,
                                              )
                                              .state =
                                          null;
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
                          settings,
                          gameToShow,
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
    final gameEmulator = await ref.read(
      perGameConfigurationProvider(game).future,
    );
    final customEmulators = await ref.read(customEmulatorsProvider.future);
    if (gameEmulator != null && gameEmulator.emulator != "default") {
      final emulators = [
        ...game.system.builtInEmulators,
        ...customEmulators.map((e) => e.toEmulator()),
      ];
      final emulator = emulators.firstWhereOrNull(
        (element) => element.id == gameEmulator.emulator,
      );
      _launchGameWithEmulator(emulator, game);
    } else {
      final alternativeEmulators = await ref.read(
        alternativeEmulatorsProvider.future,
      );
      final emulators = alternativeEmulators.firstWhereOrNull(
        (element) => element.system.id == game.system.id,
      );
      final emulator = emulators?.defaultEmulator;
      _launchGameWithEmulator(emulator, game);
    }
  }

  void _launchGameWithEmulator(Emulator? emulator, Game game) {
    debugPrint("Launching ${game.absoluteRomPath} with ${emulator?.id}");
    emulator?.intent
        .toIntent(game)
        .then(
          (intent) => intent.launch().catchError(handleIntentError(intent)),
        );
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
                child: Image.file(
                  File(game.imageUrl!),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              Text(game.name, softWrap: false),
            ],
          );
        },
      ),
    );
  }

  Widget _gameDetails(
    AsyncValue<Settings> settings,
    Game gameToShow,
    ValueNotifier<bool> showDetails,
    ScrollController detailsScrollController,
  ) {
    if (showDetails.value) {
      return _gameDetailsLong(gameToShow, detailsScrollController);
    } else {
      return _gameDetailsShort(settings, gameToShow);
    }
  }

  Widget _gameDetailsShort(AsyncValue<Settings> settings, Game gameToShow) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: settings.when(
            data: (settings) =>
                settings.showGameVideos && gameToShow.videoUrl != null
                ? _gameVideo(settings, gameToShow)
                : _gameImage(gameToShow),
            error: (_, _) => _gameImage(gameToShow),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: verticalSpacing),
        RatingBarIndicator(
          rating: gameToShow.rating ?? 0,
          itemBuilder: (context, index) =>
              const Icon(Icons.star, color: Colors.amber),
          itemCount: 10,
          itemSize: 14.0,
          direction: Axis.horizontal,
        ),
        Text(gameToShow.genreToShow),
        Text(
          "${gameToShow.developer ?? "Unknown"}, ${gameToShow.year?.toString() ?? "?"}",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _gameImage(Game gameToShow) {
    return gameToShow.imageUrl != null
        ? Image.file(
            File(gameToShow.imageUrl!),
            filterQuality: FilterQuality.none,
            fit: BoxFit.contain,
          )
        : const Text("No image");
  }

  Widget _gameVideo(Settings settings, Game gameToShow) {
    return FadeImageToVideo(
      key: ValueKey(gameToShow.romPath),
      game: gameToShow,
      settings: settings,
    );
  }

  Widget _gameDetailsLong(
    Game gameToShow,
    ScrollController detailsScrollController,
  ) {
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
            RatingBarIndicator(
              rating: gameToShow.rating ?? 0,
              itemBuilder: (context, index) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 10,
              itemSize: 14.0,
              direction: Axis.horizontal,
            ),
            gameToShow.players != null
                ? Text("Players: ${gameToShow.players}")
                : const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                gameToShow.description ?? "No description",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            InfoTiles(
              columnCount: 1,
              children: [
                InfoTile(title: "Genre", subtitle: gameToShow.genreToShow),
                InfoTile(
                  title: "Released",
                  subtitle: gameToShow.year?.toString() ?? "-",
                ),
                InfoTile(
                  title: "Developer",
                  subtitle: gameToShow.developer ?? "-",
                ),
                InfoTile(
                  title: "Publisher",
                  subtitle: gameToShow.publisher ?? "-",
                ),
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
        return _collectionLogo(Icons.star_rounded, "Favourites");
      case "recent":
        return _collectionLogo(Icons.history, "Recent");
      case "all":
        return _collectionLogo(Icons.apps, "All Games");
      default:
        return Image.asset(
          "assets/images/white/${system.logo}",
          fit: BoxFit.fitHeight,
          filterQuality: FilterQuality.none,
          errorBuilder: (context, url, error) => const Icon(Icons.error),
        );
    }
  }

  Widget _collectionLogo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
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
    final index = gamelist.games.indexWhere((g) => g.hash == selectedGame.hash);
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
      msg:
          "Unable to run ${intent.package}. Please make sure the app is installed.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  };
}
