import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

import 'package:titanius/data/gamelist_xml.dart';
import 'package:titanius/data/scraper.dart';
import 'package:titanius/widgets/selector.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/selected_scroll_tile.dart';

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
      return const Scaffold(body: Center(child: Text("Game not found")));
    }

    final workingOnIt = useState(false);
    final confirmDelete = useState(false);
    final selectedIndex = usePersistentSelection(
      '/games/$system/game/$hash',
      initialIndex: 1,
    );
    final inPrompt = useState(false);

    void cycleEmulator(bool next) {
      if (!customEmulators.hasValue) return;
      final emulators = [
        "default",
        ...game.system.builtInEmulators.map((e) => e.id),
        ...customEmulators.value!.map((e) => e.toEmulator().id),
      ];
      int index = emulators.indexWhere(
        (id) => id == (gameEmulator.value?.emulator ?? "default"),
      );
      if (next) {
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
          .saveGameEmulator(game, emulator)
          .then((value) => ref.refresh(perGameConfigurationProvider(game)));
      debugPrint("Selected emulator: $emulator");
    }

    Future<void> toggleFavourite() async {
      workingOnIt.value = true;
      setFavouriteInGamelistXml(game, !game.favorite).then(
        (value) {
          if (value) {
            game.favorite = !game.favorite;
            ref.read(gameLibraryProvider).invalidateSystem(game.system.id);
            ref.invalidate(systemGamesProvider(game.system.id));
            ref.invalidate(allGamesProvider);
          }
          if (context.mounted) {
            GoRouter.of(context).pop();
          }
        },
        onError: (error, stack) {
          workingOnIt.value = false;
          if (context.mounted) {
            _showError(context, error);
          }
        },
      );
    }

    Future<void> scrapeGame() async {
      final scraperService = ref.read(scraperServiceProvider);
      if (await scraperService.isRunning()) {
        if (context.mounted) {
          _showError(context, "Scraper already running...");
        }
        return;
      }
      if (!context.mounted) return;
      workingOnIt.value = true;
      ProgressDialog pd = ProgressDialog(context: context);
      pd.show(backgroundColor: Colors.black);
      final scraper = await ref.read(scraperProvider.future);
      scraper
          .scrape(game, (msg) => pd.update(msg: msg))
          .then(
            (scrapedGame) {
              pd.update(msg: "Writing gamelist.xml...");
              updateGameInGamelistXml(scrapedGame).then(
                (value) {
                  if (value) {
                    imageCache.clear();
                    imageCache.clearLiveImages();
                    game.update(scrapedGame);
                    ref
                        .read(gameLibraryProvider)
                        .invalidateSystem(game.system.id);
                    ref.invalidate(systemGamesProvider(game.system.id));
                    ref.invalidate(allGamesProvider);
                  }
                  if (context.mounted) {
                    GoRouter.of(context).pop();
                  }
                },
                onError: (error, stack) {
                  pd.close();
                  workingOnIt.value = false;
                  if (context.mounted) {
                    _showError(context, error);
                  }
                },
              );
              pd.close();
              workingOnIt.value = false;
            },
            onError: (error, stack) {
              pd.close();
              workingOnIt.value = false;
              if (context.mounted) {
                _showError(context, error);
              }
            },
          );
    }

    Future<void> scrapeGameById() async {
      inPrompt.value = true;
      try {
        final scraperService = ref.read(scraperServiceProvider);
        if (await scraperService.isRunning()) {
          if (context.mounted) {
            _showError(context, "Scraper already running...");
          }
          return;
        }
        if (!context.mounted) return;
        final gameId = await prompt(
          context,
          title: const Text("Game ID"),
          validator: (s) {
            if (s == null || s.isEmpty) {
              return "Id cannot be empty";
            }
            final id = int.tryParse(s);
            if (id == null) {
              return "Id must be a number";
            }
            return null;
          },
        );
        if (gameId == null || !context.mounted) {
          return;
        }
        workingOnIt.value = true;
        ProgressDialog pd = ProgressDialog(context: context);
        pd.show(backgroundColor: Colors.black);
        final scraper = await ref.read(scraperProvider.future);
        scraper
            .scrape(
              game,
              (msg) => pd.update(msg: msg),
              gameId: int.parse(gameId),
            )
            .then(
              (scrapedGame) {
                pd.update(msg: "Writing gamelist.xml...");
                updateGameInGamelistXml(scrapedGame).then(
                  (value) {
                    if (value) {
                      imageCache.clear();
                      imageCache.clearLiveImages();
                      game.update(scrapedGame);
                      ref
                          .read(gameLibraryProvider)
                          .invalidateSystem(game.system.id);
                      ref.invalidate(systemGamesProvider(game.system.id));
                      ref.invalidate(allGamesProvider);
                    }
                    if (context.mounted) {
                      GoRouter.of(context).pop();
                    }
                  },
                  onError: (error, stack) {
                    pd.close();
                    workingOnIt.value = false;
                    if (context.mounted) {
                      _showError(context, error);
                    }
                  },
                );
                pd.close();
                workingOnIt.value = false;
              },
              onError: (error, stack) {
                pd.close();
                workingOnIt.value = false;
                if (context.mounted) {
                  _showError(context, error);
                }
              },
            );
      } finally {
        inPrompt.value = false;
      }
    }

    Future<void> toggleHidden() async {
      workingOnIt.value = true;
      setHiddenGameInGamelistXml(game, !game.hidden).then(
        (value) {
          if (value) {
            game.hidden = !game.hidden;
            ref.read(gameLibraryProvider).invalidateSystem(game.system.id);
            ref.invalidate(systemGamesProvider(game.system.id));
            ref.invalidate(allGamesProvider);
          }
          if (context.mounted) {
            GoRouter.of(context).pop();
          }
        },
        onError: (error, stack) {
          workingOnIt.value = false;
          if (context.mounted) {
            _showError(context, error);
          }
        },
      );
    }

    Future<void> handleDeleteGame() async {
      if (confirmDelete.value) {
        workingOnIt.value = true;
        deleteGame(game).then(
          (value) {
            if (value) {
              ref.read(gameLibraryProvider).invalidateSystem(game.system.id);
              ref.invalidate(systemGamesProvider(game.system.id));
              ref.invalidate(allGamesProvider);
            }
            if (context.mounted) {
              GoRouter.of(context).pop();
            }
          },
          onError: (error, stack) {
            workingOnIt.value = false;
            if (context.mounted) {
              _showError(context, error);
            }
          },
        );
      } else {
        confirmDelete.value = true;
      }
    }

    final items = [
      (
        title: game.name,
        subtitle: game.rom,
        trailing: game.thumbnailUrl != null
            ? SizedBox(
                height: 48,
                child: Image.file(
                  File(game.thumbnailUrl!),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              )
            : null as Widget?,
        onTap: () {},
      ),
      (
        title: game.favorite ? "Remove From Favourites" : "Set As Favourite",
        subtitle: null as String?,
        trailing: null as Widget?,
        onTap: toggleFavourite,
      ),
      (
        title: "Scrape Game",
        subtitle: null as String?,
        trailing: null as Widget?,
        onTap: scrapeGame,
      ),
      (
        title: "Scrape Game By Id",
        subtitle: null as String?,
        trailing: null as Widget?,
        onTap: scrapeGameById,
      ),
      (
        title: game.hidden ? "Show Game" : "Hide Game",
        subtitle: null as String?,
        trailing: null as Widget?,
        onTap: toggleHidden,
      ),
      (
        title: confirmDelete.value
            ? "Are you sure? Delete cannot be reversed."
            : "Delete Game",
        subtitle: null as String?,
        trailing: null as Widget?,
        onTap: handleDeleteGame,
      ),
      (
        title: "Emulator",
        subtitle: null as String?,
        trailing:
            gameEmulator.when(
                  data: (data) {
                    return customEmulators.when(
                      data: (customEmulators) {
                        final emulators = [
                          ...game.system.builtInEmulators,
                          ...customEmulators.map((e) => e.toEmulator()),
                        ];
                        final emulator = emulators.firstWhereOrNull(
                          (element) => element.id == data?.emulator,
                        );
                        return SelectorWidget(
                          text: emulator?.name ?? "Default",
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => const Text("Error"),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => const Text("Error"),
                )
                as Widget?,
        onTap: () => cycleEmulator(true),
      ),
    ];

    useGamepad(ref, (location, key) {
      if (inPrompt.value) {
        return;
      }
      if (location != "/games/$system/game/$hash") return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.left) {
        if (selectedIndex.value == 6) {
          cycleEmulator(false);
        }
      }
      if (key == GamepadButton.right) {
        if (selectedIndex.value == 6) {
          cycleEmulator(true);
        }
      }
      if (key == GamepadButton.confirm) {
        items[selectedIndex.value].onTap();
      }
      if (key == GamepadButton.back) {
        if (confirmDelete.value) {
          confirmDelete.value = false;
        } else {
          GoRouter.of(context).go("/games/$system");
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Game Settings')),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.confirm], "Select"),
          GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: workingOnIt.value
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  Container(width: 8),
                  const Text("Working on it..."),
                ],
              ),
            )
          : ControllerListView.builder(
              key: PageStorageKey("/games/$system/game/$hash"),
              selectedIndex: selectedIndex.value,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex.value;
                return SelectedScrollTile(
                  isSelected: isSelected,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    child: Material(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      child: ListTile(
                        selected: isSelected,
                        selectedColor: Colors.black,
                        selectedTileColor: Colors.transparent,
                        dense: true,
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : (index == 5 && confirmDelete.value
                                      ? Colors.red
                                      : Colors.white),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: item.subtitle != null
                            ? Text(
                                item.subtitle!,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              )
                            : null,
                        trailing: item.trailing,
                        onTap: () {
                          selectedIndex.value = index;
                          item.onTap();
                        },
                      ),
                    ),
                  ),
                );
              },
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
      fontSize: 16.0,
    );
  }
}

class SettingElement {
  final String group;
  final Widget widget;

  const SettingElement({required this.group, required this.widget});
}
