import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:toast/toast.dart';

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
    final selectedGameIndex = ref.watch(selectedGameProvider(system));
    final scrollController = ref.watch(gameScrollProvider(system));

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.isAttached) {
          scrollController.jumpTo(index: selectedGameIndex);
        }
      });
      return null;
    }, []);

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
                      child: ScrollablePositionedList.builder(
                        itemScrollController: scrollController,
                        key:
                            PageStorageKey("${gamelist.system!.id}/games/list"),
                        itemCount: gamelist.games.length,
                        itemBuilder: (context, index) {
                          final game = gamelist.games[index];
                          final isSelected =
                              selectedGameIndex < gamelist.games.length
                                  ? index == selectedGameIndex
                                  : index == 0;
                          return ListTile(
                            visualDensity: VisualDensity.compact,
                            horizontalTitleGap: 0,
                            minLeadingWidth: 22,
                            leading: game.favorite
                                ? const Icon(
                                    Icons.star,
                                    size: 14,
                                  )
                                : null,
                            autofocus: isSelected,
                            onFocusChange: (value) {
                              if (value) {
                                ref
                                    .read(selectedGameProvider(system).notifier)
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
                              intent.launch().catchError(
                                  handleIntentError(context, intent));
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
    Toast.show("Unable to run ${intent.package}}",
        duration: Toast.lengthShort, gravity: Toast.bottom);
  };
}
