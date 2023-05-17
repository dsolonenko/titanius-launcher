import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    if (game == null) {
      return const Scaffold(
        body: Center(
          child: Text("Game not found"),
        ),
      );
    }

    final selectedEmulator = useState(0);
    final selected = useState("");

    useGamepad(ref, (location, key) {
      if (location != "/games/$system/game/$hash") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/games/$system");
      }
      if (key == GamepadButton.right) {
        if (selected.value == "emulator") {
          int next = selectedEmulator.value + 1;
          if (next > game.system.emulators.length) {
            next = 0;
          }
          selectedEmulator.value = next;
        }
      }
      if (key == GamepadButton.left) {
        if (selected.value == "emulator") {
          int prev = selectedEmulator.value - 1;
          if (prev < 0) {
            prev = game.system.emulators.length;
          }
          selectedEmulator.value = prev;
        }
      }
    });

    final elements = [
      SettingElement(
        group: "Game",
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
            ref.read(settingsRepoProvider).value!.saveFavourite(game.romPath, !game.favorite).then((value) {
              final _ = ref.refresh(settingsProvider);
              GoRouter.of(context).pop();
            });
          },
        ),
      ),
      SettingElement(
        group: "Options",
        widget: ListTile(
          title: const Text("Emulator"),
          trailing: SelectorWidget(
              text: selectedEmulator.value == 0 ? "Default" : game.system.emulators[selectedEmulator.value - 1].name),
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
      body: GroupedListView<SettingElement, String>(
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
