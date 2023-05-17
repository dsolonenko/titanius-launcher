import 'dart:io';

import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/repo.dart';
import '../data/state.dart';
import '../gamepad.dart';
import '../widgets/prompt_bar.dart';

const checkBoxSize = 40.0;
const checkBoxOnIcon = Icon(
  Icons.check_box_outlined,
  size: checkBoxSize,
);
const checkBoxOffIcon = Icon(
  Icons.check_box_outline_blank_outlined,
  size: checkBoxSize,
  color: Colors.grey,
);

class GameSettingsPage extends HookConsumerWidget {
  final String system;
  final int hash;
  const GameSettingsPage({super.key, required this.system, required this.hash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(filteredGamesInFolderProvider(system));

    useGamepad(ref, (location, key) {
      if (location != "/games/$system/game/$hash") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/games/$system");
      }
    });

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
      body: games.when(
        data: (gamelist) {
          final game = gamelist.games.firstWhere((element) => element.hash == hash);
          final elements = [
            SettingElement(
              id: "gameDetails",
              group: "Game",
              widget: ListTile(
                title: Text(game.name),
                subtitle: Text(game.romPath),
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
                onFocusChange: (value) {},
              ),
            ),
            SettingElement(
              id: "favourite",
              group: "Collections",
              widget: ListTile(
                autofocus: true,
                title: game.favorite ? const Text("Remove From Favourites") : const Text("Set As Favourite"),
                onFocusChange: (value) {},
                onTap: () {
                  ref.read(settingsRepoProvider).value!.saveFavourite(game.romPath, !game.favorite).then((value) {
                    final _ = ref.refresh(settingsProvider);
                    GoRouter.of(context).pop();
                  });
                },
              ),
            ),
          ];
          return GroupedListView<SettingElement, String>(
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }
}

class SettingElement {
  final String id;
  final String group;
  final Widget widget;

  const SettingElement({
    required this.id,
    required this.group,
    required this.widget,
  });
}
