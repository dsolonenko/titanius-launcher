import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

import 'package:titanius/data/gamelist_xml.dart';
import 'package:titanius/data/scraper.dart';
import 'package:titanius/widgets/selector.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/gamepad_prompt.dart';
import 'package:titanius/widgets/prompt_bar.dart';

class GameSettingsPage extends HookConsumerWidget {
  final String system;
  final int hash;
  const GameSettingsPage({super.key, required this.system, required this.hash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(selectedGameProvider(system));
    final gameEmulator = ref.watch(perGameConfigurationProvider(game));
    final customEmulators = ref.watch(customEmulatorsProvider);

    if (game == null) {
      return const Scaffold(
        body: Center(
          child: Text("Game not found"),
        ),
      );
    }

    final workingOnIt = useState(false);
    final confirmDelete = useState(false);
    final selected = useState("");

    useGamepad(ref, (location, key) {
      if (location != "/games/$system/game/$hash") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/games/$system");
      }
      if (key == GamepadButton.right || key == GamepadButton.left) {
        if (selected.value == "emulator" && customEmulators.hasValue) {
          final emulators = [
            "default",
            ...game.system.builtInEmulators.map((e) => e.id),
            ...customEmulators.value!.map((e) => e.toEmulator().id)
          ];
          int index = emulators.indexWhere((id) => id == (gameEmulator.value?.emulator ?? "default"));
          if (key == GamepadButton.right) {
            index++;
          } else {
            index--;
          }
          if (index < 0) {
            index = emulators.length - 1;
          }
          if (index >= emulators.length) {
            index = 0;
          }
          final emulator = emulators[index];
          ref
              .read(perGameConfigurationRepoProvider)
              .value!
              .saveGameEmulator(game, emulator)
              .then((value) => ref.refresh(perGameConfigurationProvider(game)));
          debugPrint("Selected emulator: $emulator");
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
            setFavouriteInGamelistXml(game, !game.favorite).then(
              (value) {
                if (value) {
                  // ignore: unused_result
                  ref.refresh(allGamesProvider);
                }
                GoRouter.of(context).pop();
              },
              onError: (error, stack) {
                workingOnIt.value = false;
                _showError(context, error);
              },
            );
          },
        ),
      ),
      /*
      SettingElement(
        group: "Game",
        widget: ListTile(
          title: const Text("Scrape Game"),
          onTap: () async {
            workingOnIt.value = true;
            ProgressDialog pd = ProgressDialog(context: context);
            pd.show(
              backgroundColor: Colors.black,
              msgColor: Colors.white,
            );
            final scraper = await ref.read(scraperProvider.future);
            scraper.scrape(game, (msg) => pd.update(msg: msg)).then(
              (value) {
                pd.update(msg: "Writing gamelist.xml...");
                updateGameInGamelistXml(value).then(
                  (value) {
                    if (value) {
                      // ignore: unused_result
                      ref.refresh(allGamesProvider);
                    }
                    GoRouter.of(context).pop();
                  },
                  onError: (error, stack) {
                    workingOnIt.value = false;
                    _showError(context, error);
                  },
                );
                pd.close();
                workingOnIt.value = false;
              },
              onError: (error, stack) {
                workingOnIt.value = false;
                _showError(context, error);
              },
            );
          },
          onFocusChange: (value) {
            if (value) {
              selected.value = "scrape_game";
            }
          },
        ),
      ),
      */
      SettingElement(
        group: "Game",
        widget: ListTile(
          title: game.hidden ? const Text("Show Game") : const Text("Hide Game"),
          onTap: () {
            workingOnIt.value = true;
            setHiddenGameInGamelistXml(game, !game.hidden).then(
              (value) {
                if (value) {
                  // ignore: unused_result
                  ref.refresh(allGamesProvider);
                }
                GoRouter.of(context).pop();
              },
              onError: (error, stack) {
                workingOnIt.value = false;
                _showError(context, error);
              },
            );
          },
          onFocusChange: (value) {
            if (value) {
              selected.value = "hide_game";
            }
          },
        ),
      ),
      SettingElement(
        group: "Game",
        widget: ListTile(
          title: confirmDelete.value
              ? const GamepadPromptWidget(
                  buttons: [GamepadButton.a], prompt: "Are you sure? Delete cannot be reversed.")
              : const Text("Delete Game"),
          onTap: () {
            if (confirmDelete.value) {
              workingOnIt.value = true;
              deleteGame(game).then(
                (value) {
                  if (value) {
                    // ignore: unused_result
                    ref.refresh(allGamesProvider);
                  }
                  GoRouter.of(context).pop();
                },
                onError: (error, stack) {
                  workingOnIt.value = false;
                  _showError(context, error);
                },
              );
            } else {
              confirmDelete.value = true;
            }
          },
          onFocusChange: (value) {
            if (value) {
              selected.value = "delete_game";
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
              return customEmulators.when(
                data: (customEmulators) {
                  final emulators = [...game.system.builtInEmulators, ...customEmulators.map((e) => e.toEmulator())];
                  final emulator = emulators.firstWhereOrNull((element) => element.id == data?.emulator);
                  return SelectorWidget(text: emulator?.name ?? "Default");
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => const Text("Error"),
              );
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

  void _showError(BuildContext context, err) {
    debugPrint(err.toString());
    Fluttertoast.showToast(
        msg: "Unable to change game settings: ${err.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
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
