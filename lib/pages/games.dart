import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:ndialog/ndialog.dart';

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
    final allGames = ref.watch(gamesProvider);
    final selectedGameIndex = ref.watch(selectedGameProvider(system));
    final pageController = PageController(initialPage: selectedGameIndex);

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
          if (gamelist.games.isEmpty) {
            return const Center(
              child: Text("No games found"),
            );
          }
          final selectedGame = gamelist.games[
              selectedGameIndex < gamelist.games.length
                  ? selectedGameIndex
                  : 0];
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: const EdgeInsets.all(10),
                      alignment: Alignment.center,
                      child: Image.asset(
                        "assets/images/white/${gamelist.system!.logo}",
                        fit: BoxFit.fitHeight,
                        errorBuilder: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                          key: PageStorageKey("${gamelist.system!.id}/games"),
                          controller: pageController,
                          itemCount: gamelist.games.length,
                          itemBuilder: (context, index) {
                            final game = gamelist.games[index];
                            return ListTile(
                              horizontalTitleGap: 0,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading:
                                  game.favorite ? const Icon(Icons.star) : null,
                              autofocus:
                                  selectedGameIndex < gamelist.games.length
                                      ? index == selectedGameIndex
                                      : index == 0,
                              onFocusChange: (value) {
                                if (value) {
                                  ref
                                      .read(
                                          selectedGameProvider(system).notifier)
                                      .set(index);
                                }
                              },
                              title: Text(
                                game.name,
                                softWrap: false,
                              ),
                              onTap: () async {
                                ref
                                    .read(selectedGameProvider(system).notifier)
                                    .set(index);
                                final intent =
                                    gamelist.emulator!.toIntent(selectedGame);
                                print(intent);
                                intent.launch().catchError(
                                    handleIntentError(context, intent));
                              },
                            );
                          }),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.black,
                  //padding: const EdgeInsets.all(verticalSpacing),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Expanded(
                        child: selectedGame.imageUrl != null
                            ? Image.file(
                                File(selectedGame.imageUrl!),
                                fit: BoxFit.contain,
                              )
                            : const Text("No image"),
                      ),
                      const SizedBox(height: verticalSpacing),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Text(
                          //   selectedGame.name,
                          //   style: const TextStyle(
                          //       fontSize: 18, fontWeight: FontWeight.bold),
                          // ),
                          RatingBarIndicator(
                            rating: selectedGame.rating ?? 0,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 10,
                            itemSize: 14.0,
                            direction: Axis.horizontal,
                          ),
                          Text(selectedGame.genre ?? "Unknown"),
                          Text(
                            "${selectedGame.developer ?? "Unknown"}, ${selectedGame.year?.toString() ?? "?"}",
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
}

Function handleIntentError(BuildContext context, AndroidIntent intent) {
  return (err) {
    print(
        "PlatformException code=${(err as PlatformException).code} details=${(err).details}");
    NDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text("NDialog"),
      content: Text("This is NDialog's content"),
      actions: <Widget>[
        TextButton(
            child: Text("Okay"), onPressed: () => Navigator.pop(context)),
        TextButton(
            child: Text("Close"), onPressed: () => Navigator.pop(context)),
      ],
    ).show(context);
  };
}
