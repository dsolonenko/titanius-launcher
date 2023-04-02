import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const GamesPage(this.system, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGames = ref.watch(gamesProvider(system));
    final selectedGame = ref.watch(selectedGameProvider(system));
    final selectedFolder = ref.watch(selectedFolderProvider(system));

    useGamepad(ref, (location, key) {
      if (location != "/games/$system") return;
      if (key == GamepadButton.b) {
        if (selectedFolder == ".") {
          GoRouter.of(context).go("/");
        } else {
          ref.read(selectedFolderProvider(system).notifier).set(
              selectedFolder.substring(0, selectedFolder.lastIndexOf("/")));
        }
      }
      if (key == GamepadButton.y) {
        final selectedGame = ref.read(selectedGameProvider(system));
        if (selectedGame != null && !selectedGame.isFolder) {
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
        navigations: {
          GamepadButton.l1: "",
          GamepadButton.r1: "System",
          GamepadButton.start: "Menu",
          //GamepadButton.select: "Filter",
        },
        actions: {
          GamepadButton.y: "Favourite",
          //GamepadButton.x: "Settings",
          GamepadButton.b: "Back",
          GamepadButton.a: "Launch",
        },
      ),
      body: allGames.when(
        data: (gamelist) {
          final gamesInFolder = gamelist.games
              .where((game) => game.folder == selectedFolder)
              .toList();
          if (gamesInFolder.isEmpty) {
            return const Center(
              child: Text("No games found"),
            );
          }
          final gameToShow = selectedGame ?? gamesInFolder.first;
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
                        itemCount: gamesInFolder.length,
                        itemBuilder: (context, index) {
                          final game = gamesInFolder[index];
                          final isSelected = game.romPath == gameToShow.romPath;
                          return ListTile(
                            visualDensity: VisualDensity.compact,
                            horizontalTitleGap: 0,
                            minLeadingWidth: 22,
                            leading: game.isFolder
                                ? const Icon(Icons.folder, size: 14)
                                : game.favorite
                                    ? const Icon(Icons.star, size: 14)
                                    : null,
                            autofocus: isSelected,
                            onFocusChange: (value) {
                              if (value) {
                                ref
                                    .read(selectedGameProvider(system).notifier)
                                    .set(game);
                              }
                            },
                            title: Text(
                              game.name,
                              softWrap: false,
                            ),
                            onTap: () async {
                              if (game.isFolder) {
                                ref
                                    .read(selectedGameProvider(system).notifier)
                                    .reset();
                                ref
                                    .read(
                                        selectedFolderProvider(system).notifier)
                                    .set(game.rom);
                              } else {
                                ref
                                    .read(selectedGameProvider(system).notifier)
                                    .set(game);
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
    print(
        "PlatformException code=${(err as PlatformException).code} details=${(err).details}");
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
