import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titanius/data/gamelist_xml.dart';
import 'package:titanius/widgets/selector.dart';
import '../data/repo.dart';
import '../data/state.dart';
import '../gamepad.dart';
import '../widgets/prompt_bar.dart';

class GameSettingsPage extends HookConsumerWidget {
  final String system;
  final int hash;
  const GameSettingsPage({super.key, required this.system, required this.hash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.read(selectedGameProvider(system));
    final gameEmulator = ref.watch(perGameConfigurationProvider(game));

    if (game == null) {
      return const Scaffold(
        body: Center(
          child: Text("Game not found"),
        ),
      );
    }

    final workingOnIt = useState(false);
    final selected = useState("");

    useGamepad(ref, (location, key) {
      if (location != "/games/$system/game/$hash") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/games/$system");
      }
      if (key == GamepadButton.right || key == GamepadButton.left) {
        if (selected.value == "emulator") {
          final emulators = ["default", ...game.system.emulators.map((e) => e.id)];
          int index = emulators.indexWhere((id) => id == (gameEmulator.value?.emulator ?? "default"));
          if (key == GamepadButton.right) {
            index++;
          } else {
            index--;
          }
          if (index < 0) {
            index = game.system.emulators.length - 1;
          }
          if (index >= game.system.emulators.length) {
            index = 0;
          }
          final emulator = emulators[index];
          ref
              .read(perGameConfigurationRepoProvider)
              .value!
              .saveGameEmulator(game, emulator)
              .then((value) => ref.refresh(perGameConfigurationProvider(game)));
        }
      }
    });

    final elements = [
      SettingElement(
        group: "Details",
        widget: ListTile(
          title: Text(game.name),
          subtitle: Text(game.rom),
          trailing: game.thumbnailUrl != null
              ? SizedBox(
                  height: 48,
                  child: Image.file(
                    File(game.thumbnailUrl!),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                )
              : null,
          onTap: () {},
          onFocusChange: (value) {
            if (value) {
              selected.value = "game";
            }
          },
        ),
      ),
      SettingElement(
        group: "Collections",
        widget: ListTile(
          autofocus: true,
          title: game.favorite ? const Text("Remove From Favourites") : const Text("Set As Favourite"),
          onFocusChange: (value) {
            if (value) {
              selected.value = "favourite";
            }
          },
          onTap: () {
            workingOnIt.value = true;
            setFavouriteInGamelistXml(game, !game.favorite).then((value) {
              if (value) {
                game.favorite = !game.favorite;
              }
              GoRouter.of(context).pop();
            });
          },
        ),
      ),
      SettingElement(
        group: "Game",
        widget: ListTile(
          title: game.hidden ? const Text("Show Game") : const Text("Hide Game"),
          onTap: () {
            workingOnIt.value = true;
            setHiddenGameInGamelistXml(game, !game.hidden).then((value) {
              if (value) {
                game.hidden = !game.hidden;
                if (game.hidden) {
                  ref.read(hiddenGamesProvider(system).notifier).unhideGame(game);
                } else {
                  ref.read(hiddenGamesProvider(system).notifier).hideGame(game);
                }
              }
              GoRouter.of(context).pop();
            });
          },
          onFocusChange: (value) {
            if (value) {
              selected.value = "hide_game";
            }
          },
        ),
      ),
      SettingElement(
        group: "Options",
        widget: ListTile(
          title: const Text("Emulator"),
          trailing: gameEmulator.when(
            data: (data) {
              final emulator = game.system.emulators.firstWhereOrNull((element) => element.id == data?.emulator);
              return SelectorWidget(text: emulator?.name ?? "Default");
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => const Text("Error"),
          ),
          onFocusChange: (value) {
            if (value) {
              selected.value = "emulator";
            }
          },
          onTap: () {},
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Settings'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: workingOnIt.value
          ? Center(
              child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                Container(
                  width: 8,
                ),
                const Text("Working on it...")
              ],
            ))
          : GroupedListView<SettingElement, String>(
              key: PageStorageKey("/games/$system/game/$hash"),
              elements: elements,
              groupBy: (element) => element.group,
              groupSeparatorBuilder: (String value) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              itemBuilder: (context, element) {
                return element.widget;
              },
              sort: false,
            ),
    );
  }
}

class SettingElement {
  final String group;
  final Widget widget;

  const SettingElement({
    required this.group,
    required this.widget,
  });
}
