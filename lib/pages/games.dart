import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:titanius/data/models.dart';

import '../data/settings.dart';
import '../data/state.dart';
import '../gamepad.dart';
import '../data/games.dart';
import '../widgets/appbar.dart';
import '../widgets/prompt_bar.dart';

const double verticalSpacing = 10;

class GamesPage extends HookConsumerWidget {
  final String system;
  const GamesPage({super.key, required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGames = ref.watch(gamesProvider(system));
    final navigation = ref.watch(currentGameNavigationProvider(system));

    final scrollController = useScrollController();

    useGamepad(ref, (location, key) {
      if (location != "/games/$system") return;
      if (key == GamepadButton.b) {
        final navigation = ref.read(currentGameNavigationProvider(system));
        debugPrint("Back: $navigation");
        if (navigation.isAtRoot) {
          GoRouter.of(context).go("/");
        } else {
          ref.read(currentGameNavigationProvider(system).notifier).goBack();
        }
      }
      if (key == GamepadButton.y) {
        final navigation = ref.read(currentGameNavigationProvider(system));
        debugPrint("Favourite: $navigation");
        if (navigation.isGame) {
          ref
              .read(settingsRepoProvider)
              .value!
              .saveFavourite(
                  navigation.game!.romPath, !navigation.game!.favorite)
              .then((value) => ref.refresh(settingsProvider));
        }
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.l2, GamepadButton.r2], "System"),
          GamepadPrompt([GamepadButton.start], "Menu"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.y], "Favourite"),
          GamepadPrompt([GamepadButton.b], "Back"),
          GamepadPrompt([GamepadButton.a], "Launch"),
        ],
      ),
      body: allGames.when(
        data: (gamelist) {
          final gamesInFolder = gamelist.games
              .where((game) => game.folder == navigation.folder)
              .toList();
          if (gamesInFolder.isEmpty) {
            return const Center(
              child: Text("No games found"),
            );
          }
          final gameToShow = navigation.game ?? gamesInFolder.first;
          debugPrint("Navigation=$navigation, show=${gameToShow.rom}");
          return Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: Image.asset(
                        "assets/images/white/${gamelist.system!.logo}",
                        fit: BoxFit.fitHeight,
                        errorBuilder: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        key: PageStorageKey("$system/${navigation.folder}"),
                        itemCount: gamesInFolder.length,
                        itemBuilder: (context, index) {
                          final game = gamesInFolder[index];
                          final isSelected = game.romPath == gameToShow.romPath;
                          return ListTile(
                            key: ValueKey(game.romPath),
                            visualDensity: VisualDensity.compact,
                            horizontalTitleGap: 0,
                            minLeadingWidth: 22,
                            leading: game.isFolder
                                ? const Icon(Icons.folder, size: 14)
                                : game.favorite
                                    ? const Icon(Icons.star, size: 14)
                                    : null,
                            autofocus: isSelected,
                            selected: isSelected,
                            onFocusChange: (value) {
                              if (value) {
                                debugPrint(
                                    "Focus on ${game.rom}, scroll ${scrollController.offset}");
                                ref
                                    .read(currentGameNavigationProvider(system)
                                        .notifier)
                                    .selectGame(game);
                              }
                            },
                            title: Text(
                              game.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            onTap: () async {
                              if (game.isFolder) {
                                ref
                                    .read(currentGameNavigationProvider(system)
                                        .notifier)
                                    .moveIntoFolder();
                              } else {
                                final intent =
                                    gamelist.emulator!.toIntent(game);
                                intent.launch().catchError(
                                    handleIntentError(context, intent));
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
                    ? _gameFolder(context, gamelist, gameToShow)
                    : Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Expanded(
                              child: gameToShow.imageUrl != null
                                  ? Image.file(
                                      File(gameToShow.imageUrl!),
                                      fit: BoxFit.contain,
                                    )
                                  : const Text("No image"),
                            ),
                            const SizedBox(height: verticalSpacing),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }

  _gameFolder(BuildContext context, GameList gamelist, Game gameToShow) {
    final gamesInFolder = gamelist.games
        .where((game) => game.folder == gameToShow.rom && game.imageUrl != null)
        .toList();
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
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
}

Function handleIntentError(BuildContext context, AndroidIntent intent) {
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
        fontSize: 16.0);
  };
}
