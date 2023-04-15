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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/widgets/fade_image_to_video.dart';

import '../data/settings.dart';
import '../data/state.dart';
import '../gamepad.dart';
import '../data/games.dart';
import '../widgets/appbar.dart';
import '../widgets/prompt_bar.dart';

const double verticalSpacing = 4;

class GamesPage extends HookConsumerWidget {
  final String system;
  const GamesPage({super.key, required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesInFolderProvider(system));
    final selectedGame = ref.watch(selectedGameProvider(system));
    final settings = ref.watch(settingsProvider);

    final scrollController = ItemScrollController();
    final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

    final showDetails = useState(false);

    useGamepad(ref, (location, key) {
      if (location != "/games/$system") return;
      if (key == GamepadButton.l1 || key == GamepadButton.r1) {
        final pos = itemPositionsListener.itemPositions.value.sorted((a, b) => a.index.compareTo(b.index));
        if (pos.isEmpty) {
          return;
        }
        final pageSize = pos.last.index - pos.first.index + 1;
        final index = key == GamepadButton.l1 ? max(pos.first.index - pageSize, 0) : pos.last.index + 1;
        debugPrint("Go to index=$index page=$pageSize list=${pos.map((e) => e.index.toString()).join(",")}");
        _goTo(ref, scrollController, index);
      }
      if (key == GamepadButton.b) {
        final navigation = ref.read(currentGameNavigationProvider(system));
        debugPrint("Back: $navigation");
        if (navigation.isAtRoot) {
          GoRouter.of(context).go("/");
        } else {
          Game game = ref.read(currentGameNavigationProvider(system).notifier).goBack();
          ref.read(selectedGameProvider(system).notifier).set(game);
        }
      }
      if (key == GamepadButton.x) {
        showDetails.value = !showDetails.value;
      }
      if (key == GamepadButton.y) {
        final selectedGame = ref.read(selectedGameProvider(system));
        debugPrint("Favourite: $selectedGame");
        if (selectedGame != null) {
          ref
              .read(settingsRepoProvider)
              .value!
              .saveFavourite(selectedGame.romPath, !selectedGame.favorite)
              .then((value) => ref.refresh(settingsProvider));
        }
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.l1, GamepadButton.r1], "Scroll"),
          GamepadPrompt([GamepadButton.l2, GamepadButton.r2], "System"),
          GamepadPrompt([GamepadButton.start], "Menu"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.x], "Details"),
          GamepadPrompt([GamepadButton.y], "Favourite"),
          GamepadPrompt([GamepadButton.b], "Back"),
          GamepadPrompt([GamepadButton.a], "Launch"),
        ],
      ),
      body: games.when(
        data: (gamelist) {
          if (gamelist.games.isEmpty) {
            return const Center(
              child: Text("No games found"),
            );
          }
          final gameToShow = selectedGame ?? gamelist.games.first;
          final index = gamelist.games.indexOf(gameToShow).clamp(0, gamelist.games.length - 1);
          debugPrint("show=${gameToShow.rom}");
          return Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: _systemLogo(gamelist.system),
                    ),
                    Expanded(
                      child: ScrollablePositionedList.builder(
                        itemScrollController: scrollController,
                        itemPositionsListener: itemPositionsListener,
                        key: PageStorageKey("$system/${gamelist.currentFolder}"),
                        initialScrollIndex: index,
                        itemCount: gamelist.games.length,
                        itemBuilder: (context, index) {
                          final game = gamelist.games[index];
                          final isSelected = game.romPath == gameToShow.romPath;
                          return ListTile(
                            key: ValueKey(game.romPath),
                            dense: settings.value?.compactGameList ?? false,
                            visualDensity: VisualDensity.compact,
                            horizontalTitleGap: 0,
                            minLeadingWidth: 22,
                            leading: game.isFolder
                                ? const Icon(Icons.folder, size: 14)
                                : system != "favourites" && game.favorite
                                    ? const Icon(Icons.star, size: 14)
                                    : null,
                            autofocus: isSelected,
                            selected: isSelected,
                            onFocusChange: (value) {
                              if (value) {
                                debugPrint(
                                    "Focus on ${game.rom}, list=${itemPositionsListener.itemPositions.value.map((e) => e.index.toString()).join(",")}");
                                ref.read(selectedGameProvider(system).notifier).set(game);
                              }
                            },
                            title: Text(
                              game.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: gamelist.system.isMulti ? Text(game.system.name) : null,
                            onTap: () async {
                              if (game.isFolder) {
                                ref.read(currentGameNavigationProvider(system).notifier).moveIntoFolder(game);
                                ref.read(selectedGameProvider(system).notifier).reset();
                              } else {
                                final intent = game.emulator!.toIntent(game);
                                intent.launch().catchError(handleIntentError(context, intent));
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: gameToShow.isFolder
                    ? _gameFolder(ref, context, gameToShow)
                    : _gameDetails(settings, gameToShow, showDetails),
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }

  _gameFolder(WidgetRef ref, BuildContext context, Game gameToShow) {
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
                ),
              ),
              Text(game.name, softWrap: false),
            ],
          );
        },
      ),
    );
  }

  void _goTo(WidgetRef ref, ItemScrollController scrollController, int index) {
    scrollController.jumpTo(
      index: index,
      alignment: 0,
    );
    final games = ref.read(gamesInFolderProvider(system));
    ref
        .read(selectedGameProvider(system).notifier)
        .set(games.value!.games[index.clamp(0, games.value!.games.length - 1)]);
  }

  Widget _gameDetails(AsyncValue<Settings> settings, Game gameToShow, ValueNotifier<bool> showDetails) {
    if (showDetails.value) {
      return _gameDetailsLong(gameToShow);
    } else {
      return _gameDetailsShort(settings, gameToShow);
    }
  }

  Widget _gameDetailsShort(AsyncValue<Settings> settings, Game gameToShow) {
    return Column(
      children: [
        Expanded(
          child: settings.when(
              data: (settings) => settings.showGameVideos && gameToShow.videoUrl != null
                  ? _gameVideo(settings, gameToShow)
                  : _gameImage(gameToShow),
              error: (_, __) => _gameImage(gameToShow),
              loading: () => const Center(child: CircularProgressIndicator())),
        ),
        const SizedBox(height: verticalSpacing),
        RatingBarIndicator(
          rating: gameToShow.rating ?? 0,
          itemBuilder: (context, index) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          itemCount: 10,
          itemSize: 14.0,
          direction: Axis.horizontal,
        ),
        Text(gameToShow.genre ?? "Unknown"),
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
            filterQuality: FilterQuality.high,
            fit: BoxFit.contain,
          )
        : const Text("No image");
  }

  Widget _gameVideo(Settings settings, Game gameToShow) {
    return FadeImageToVideo(key: ValueKey(gameToShow.romPath), game: gameToShow, settings: settings);
  }

  Widget _gameDetailsLong(Game gameToShow) {
    return Column(
      children: [
        gameToShow.thumbnailUrl != null
            ? SizedBox(
                height: 60,
                child: Image.file(
                  File(gameToShow.thumbnailUrl!),
                  fit: BoxFit.fitHeight,
                ),
              )
            : Text(gameToShow.name, textScaleFactor: 2),
        Text(
          gameToShow.rom,
        ),
        RatingBarIndicator(
          rating: gameToShow.rating ?? 0,
          itemBuilder: (context, index) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          itemCount: 10,
          itemSize: 14.0,
          direction: Axis.horizontal,
        ),
        gameToShow.players != null
            ? Text("Players: ${gameToShow.players}")
            : const SizedBox(
                height: 0,
              ),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(gameToShow.description ?? "No description", style: const TextStyle(color: Colors.grey))),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double tileWidth = constraints.maxWidth / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _gameInfoTile("Genre", gameToShow.genre ?? "-", tileWidth),
                  _gameInfoTile("Released", gameToShow.year?.toString() ?? "-", tileWidth),
                  _gameInfoTile("Developer", gameToShow.developer ?? "-", tileWidth),
                  _gameInfoTile("Publisher", gameToShow.publisher ?? "-", tileWidth),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _gameInfoTile(String title, String subtitle, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
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
          errorBuilder: (context, url, error) => const Icon(Icons.error),
        );
    }
  }

  Widget _collectionLogo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ],
    );
  }
}

Function handleIntentError(BuildContext context, AndroidIntent intent) {
  return (err) {
    debugPrint(err.toString());
    Fluttertoast.showToast(
        msg: "Unable to run ${intent.package}. Please make sure the app is installed.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  };
}
