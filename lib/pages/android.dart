import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import 'package:titanius/data/android_apps.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/appbar.dart';
import 'package:titanius/widgets/info_tile.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/selected_scroll_tile.dart';

const double verticalSpacing = 10;

class _AndroidSectionData {
  final String title;
  final IconData icon;
  final List<AppInfo> items;

  const _AndroidSectionData(this.title, this.icon, this.items);
}

class _AndroidGridRow {
  final _AndroidSectionData? headerSection;
  final bool isFirstSection;
  final List<AppInfo> items;
  _AndroidGridRow({
    this.headerSection,
    this.isFirstSection = false,
    required this.items,
  });
}

class _AndroidListRow {
  final _AndroidSectionData? headerSection;
  final bool isFirstSection;
  final AppInfo app;
  _AndroidListRow({
    this.headerSection,
    this.isFirstSection = false,
    required this.app,
  });
}

class AndroidPage extends HookConsumerWidget {
  const AndroidPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorizedData = ref.watch(categorizedAndroidAppsProvider);
    final selectedApp = ref.watch(selectedAppProvider);

    final showDetals = useState(false);
    final detailsScrollController = useScrollController();

    useValueChanged<AppInfo?, void>(selectedApp, (previous, _) {
      if (detailsScrollController.hasClients) {
        detailsScrollController.jumpTo(0);
      }
    });

    useGamepad(ref, (location, key) {
      if (location != "/games/android") return;
      final data = categorizedData.value;
      if (data == null || data.isEmpty) {
        if (key == GamepadButton.back) {
          GoRouter.of(context).go("/");
        }
        if (key == GamepadButton.y) {
          GoRouter.of(context).go("/select_apps");
        }
        return;
      }

      final sections = [
        if (data.games.isNotEmpty)
          _AndroidSectionData("Games", Icons.sports_esports, data.games),
        if (data.emulators.isNotEmpty)
          _AndroidSectionData(
            "Emulators",
            Icons.videogame_asset,
            data.emulators,
          ),
        if (data.apps.isNotEmpty)
          _AndroidSectionData("Apps", Icons.apps, data.apps),
      ];

      if (sections.isEmpty) return;

      int currentSectionIndex = -1;
      int itemIndex = -1;

      if (selectedApp != null) {
        for (int s = 0; s < sections.length; s++) {
          final idx = sections[s].items.indexWhere(
            (app) => app.packageName == selectedApp.packageName,
          );
          if (idx != -1) {
            currentSectionIndex = s;
            itemIndex = idx;
            break;
          }
        }
      }

      if (currentSectionIndex == -1) {
        currentSectionIndex = 0;
        itemIndex = 0;
      }

      // L1 / R1 jumps directly between sections
      if (key == GamepadButton.r1) {
        final nextSec = (currentSectionIndex + 1) % sections.length;
        ref.read(selectedAppProvider.notifier).state =
            sections[nextSec].items.first;
        return;
      }
      if (key == GamepadButton.l1) {
        final prevSec =
            (currentSectionIndex - 1 + sections.length) % sections.length;
        ref.read(selectedAppProvider.notifier).state =
            sections[prevSec].items.first;
        return;
      }

      if (showDetals.value) {
        if (key == GamepadButton.up) {
          if (itemIndex > 0) {
            ref.read(selectedAppProvider.notifier).state =
                sections[currentSectionIndex].items[itemIndex - 1];
          } else if (currentSectionIndex > 0) {
            final prevSec = sections[currentSectionIndex - 1];
            ref.read(selectedAppProvider.notifier).state = prevSec.items.last;
          }
        }
        if (key == GamepadButton.down) {
          if (itemIndex < sections[currentSectionIndex].items.length - 1) {
            ref.read(selectedAppProvider.notifier).state =
                sections[currentSectionIndex].items[itemIndex + 1];
          } else if (currentSectionIndex < sections.length - 1) {
            final nextSec = sections[currentSectionIndex + 1];
            ref.read(selectedAppProvider.notifier).state = nextSec.items.first;
          }
        }
      } else {
        final screenWidth = MediaQuery.of(context).size.width - 24;
        final columns = (screenWidth / 150).ceil().clamp(1, 20);
        final currentSection = sections[currentSectionIndex];

        if (key == GamepadButton.left) {
          if (itemIndex > 0) {
            ref.read(selectedAppProvider.notifier).state =
                currentSection.items[itemIndex - 1];
          } else if (currentSectionIndex > 0) {
            ref.read(selectedAppProvider.notifier).state =
                sections[currentSectionIndex - 1].items.last;
          }
        }
        if (key == GamepadButton.right) {
          if (itemIndex < currentSection.items.length - 1) {
            ref.read(selectedAppProvider.notifier).state =
                currentSection.items[itemIndex + 1];
          } else if (currentSectionIndex < sections.length - 1) {
            ref.read(selectedAppProvider.notifier).state =
                sections[currentSectionIndex + 1].items.first;
          }
        }
        if (key == GamepadButton.up) {
          if (itemIndex - columns >= 0) {
            ref.read(selectedAppProvider.notifier).state =
                currentSection.items[itemIndex - columns];
          } else if (currentSectionIndex > 0) {
            final prevSec = sections[currentSectionIndex - 1];
            final col = itemIndex % columns;
            final prevRows = (prevSec.items.length / columns).ceil();
            final targetIdx = ((prevRows - 1) * columns + col).clamp(
              0,
              prevSec.items.length - 1,
            );
            ref.read(selectedAppProvider.notifier).state =
                prevSec.items[targetIdx];
          }
        }
        if (key == GamepadButton.down) {
          if (itemIndex + columns < currentSection.items.length) {
            ref.read(selectedAppProvider.notifier).state =
                currentSection.items[itemIndex + columns];
          } else if (currentSectionIndex < sections.length - 1) {
            final nextSec = sections[currentSectionIndex + 1];
            final col = itemIndex % columns;
            final targetIdx = col.clamp(0, nextSec.items.length - 1);
            ref.read(selectedAppProvider.notifier).state =
                nextSec.items[targetIdx];
          }
        }
      }

      if (key == GamepadButton.confirm) {
        final currentSection = sections[currentSectionIndex];
        final app = currentSection.items[itemIndex];
        ref.read(selectedAppProvider.notifier).state = app;
        InstalledApps.startApp(
          app.packageName,
        ).catchError(handleIntentError(context, app.name));
      }
      if (key == GamepadButton.l2 || key == GamepadButton.r2) {
        final allSystems = ref.read(detectedSystemsProvider).value ?? [];
        if (allSystems.isNotEmpty) {
          final currentIdx = allSystems.indexWhere((s) => s.id == "android");
          if (currentIdx != -1) {
            final nextIdx = key == GamepadButton.r2
                ? (currentIdx + 1) % allSystems.length
                : (currentIdx - 1 + allSystems.length) % allSystems.length;
            ref.read(selectedSystemProvider.notifier).state = nextIdx;
            GoRouter.of(context).go("/games/${allSystems[nextIdx].id}");
          }
        }
      }
      if (key == GamepadButton.start) {
        GoRouter.of(context).push("/settings?source=android");
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).go("/");
      }
      if (key == GamepadButton.x) {
        showDetals.value = !showDetals.value;
      }
      if (key == GamepadButton.rightStickUp ||
          key == GamepadButton.rightStickDown) {
        if (!showDetals.value || !detailsScrollController.hasClients) return;
        const scrollStep = 56.0;
        final delta = key == GamepadButton.rightStickUp
            ? -scrollStep
            : scrollStep;
        final position = detailsScrollController.position;
        final target = (detailsScrollController.offset + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        detailsScrollController.jumpTo(target);
      }
      if (key == GamepadButton.y) {
        GoRouter.of(context).go("/select_apps");
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([
            GamepadButton.upDown,
            GamepadButton.leftRight,
          ], "Select"),
          GamepadPrompt([GamepadButton.l1, GamepadButton.r1], "Section"),
          GamepadPrompt([GamepadButton.l2, GamepadButton.r2], "System"),
          GamepadPrompt([GamepadButton.start], "Menu"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.x], "Details"),
          GamepadPrompt([GamepadButton.y], "Select Apps"),
          GamepadPrompt([GamepadButton.back], "Back"),
          GamepadPrompt([GamepadButton.confirm], "Launch"),
        ],
      ),
      body: categorizedData.when(
        data: (data) {
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.android, size: 64, color: Colors.white38),
                  const SizedBox(height: 16),
                  const Text(
                    "No apps selected",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Press Y to configure Games, Emulators, and Apps",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          final sections = [
            if (data.games.isNotEmpty)
              _AndroidSectionData("Games", Icons.sports_esports, data.games),
            if (data.emulators.isNotEmpty)
              _AndroidSectionData(
                "Emulators",
                Icons.videogame_asset,
                data.emulators,
              ),
            if (data.apps.isNotEmpty)
              _AndroidSectionData("Apps", Icons.apps, data.apps),
          ];

          final allVisible = data.allVisible;
          final currentApp =
              selectedApp == null ||
                  !allVisible.any(
                    (a) => a.packageName == selectedApp.packageName,
                  )
              ? allVisible.first
              : selectedApp;

          if (showDetals.value) {
            final listRows = <_AndroidListRow>[];
            var selectedRow = 0;
            for (var sIdx = 0; sIdx < sections.length; sIdx++) {
              final section = sections[sIdx];
              for (var i = 0; i < section.items.length; i++) {
                final app = section.items[i];
                if (app.packageName == currentApp.packageName) {
                  selectedRow = listRows.length;
                }
                listRows.add(
                  _AndroidListRow(
                    headerSection: i == 0 ? section : null,
                    isFirstSection: i == 0 && sIdx == 0,
                    app: app,
                  ),
                );
              }
            }

            return Row(
              children: [
                Expanded(
                  flex: 10,
                  child: ControllerListView.builder(
                    key: const PageStorageKey("android/sections_list"),
                    selectedIndex: selectedRow,
                    itemCount: listRows.length,
                    itemBuilder: (context, index) {
                      final row = listRows[index];
                      final selected =
                          row.app.packageName == currentApp.packageName;
                      final tile = _appTileList(
                        context,
                        ref,
                        row.app,
                        selected,
                      );
                      if (row.headerSection == null) return tile;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _sectionHeader(
                            row.headerSection!.title,
                            row.headerSection!.icon,
                            row.headerSection!.items.length,
                            topPadding: row.isFirstSection ? 4.0 : 16.0,
                          ),
                          tile,
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: _appDetails(currentApp, detailsScrollController),
                  ),
                ),
              ],
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              const horizontalPadding = 24.0;
              final screenWidth = (constraints.maxWidth - horizontalPadding)
                  .clamp(0.0, double.infinity);
              final columns = (screenWidth / 150).ceil().clamp(1, 20);
              const crossAxisSpacing = 10.0;
              final totalSpacing = crossAxisSpacing * (columns - 1);
              final cellWidth = (screenWidth - totalSpacing) / columns;
              final cellHeight = cellWidth / 0.88;

              final gridRows = <_AndroidGridRow>[];
              var selectedRow = 0;
              for (var sIdx = 0; sIdx < sections.length; sIdx++) {
                final section = sections[sIdx];
                for (var i = 0; i < section.items.length; i += columns) {
                  final chunk = section.items.sublist(
                    i,
                    (i + columns).clamp(0, section.items.length),
                  );
                  final isFirstChunk = (i == 0);
                  if (chunk.any(
                    (a) => a.packageName == currentApp.packageName,
                  )) {
                    selectedRow = gridRows.length;
                  }
                  gridRows.add(
                    _AndroidGridRow(
                      headerSection: isFirstChunk ? section : null,
                      isFirstSection: isFirstChunk && sIdx == 0,
                      items: chunk,
                    ),
                  );
                }
              }

              return ControllerListView.builder(
                key: const PageStorageKey("android/sections_grid"),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                selectedIndex: selectedRow,
                itemCount: gridRows.length,
                itemBuilder: (context, index) {
                  final row = gridRows[index];
                  final rowWidget = Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: cellHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(columns, (colIdx) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: colIdx < columns - 1
                                  ? crossAxisSpacing
                                  : 0,
                            ),
                            child: colIdx < row.items.length
                                ? _appTileGrid(
                                    context,
                                    ref,
                                    row.items[colIdx],
                                    row.items[colIdx].packageName ==
                                        currentApp.packageName,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }),
                    ),
                  );

                  if (row.headerSection == null) return rowWidget;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sectionHeader(
                        row.headerSection!.title,
                        row.headerSection!.icon,
                        row.headerSection!.items.length,
                        topPadding: row.isFirstSection ? 4.0 : 16.0,
                      ),
                      rowWidget,
                    ],
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    int count, {
    double topPadding = 14.0,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 4, right: 4, top: topPadding, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
        ],
      ),
    );
  }

  Widget _appTileGrid(
    BuildContext context,
    WidgetRef ref,
    AppInfo app,
    bool selected,
  ) {
    return SelectedScrollTile(
      isSelected: selected,
      child: Material(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        elevation: selected ? 4 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            ref.read(selectedAppProvider.notifier).state = app;
            InstalledApps.startApp(
              app.packageName,
            ).catchError(handleIntentError(context, app.name));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: app.icon != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              app.icon!,
                              gaplessPlayback: true,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                          )
                        : Icon(
                            Icons.android,
                            size: 48,
                            color: selected ? Colors.black : Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  app.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appTileList(
    BuildContext context,
    WidgetRef ref,
    AppInfo app,
    bool selected,
  ) {
    return SelectedScrollTile(
      isSelected: selected,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Material(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: ListTile(
            key: ValueKey("android/list/${app.packageName}"),
            selected: selected,
            selectedColor: Colors.black,
            selectedTileColor: Colors.transparent,
            dense: true,
            leading: app.icon != null
                ? Image.memory(
                    app.icon!,
                    gaplessPlayback: true,
                    fit: BoxFit.contain,
                    width: 36,
                    height: 36,
                    filterQuality: FilterQuality.medium,
                  )
                : Icon(
                    Icons.android,
                    color: selected ? Colors.black : Colors.white,
                  ),
            title: Text(
              app.name,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () async {
              ref.read(selectedAppProvider.notifier).state = app;
              InstalledApps.startApp(
                app.packageName,
              ).catchError(handleIntentError(context, app.name));
            },
          ),
        ),
      ),
    );
  }

  Widget _appDetails(AppInfo app, ScrollController detailsScrollController) {
    return Scrollbar(
      controller: detailsScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: detailsScrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (app.icon != null)
              SizedBox(
                height: 72,
                child: Image.memory(
                  app.icon!,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              )
            else
              const Icon(Icons.android, size: 72),
            const SizedBox(height: 10),
            Text(
              app.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InfoTiles(
              columnCount: 1,
              children: [
                InfoTile(title: "Package", subtitle: app.packageName),
                InfoTile(
                  title: "Version",
                  subtitle: app.versionName.isNotEmpty ? app.versionName : "-",
                ),
                InfoTile(
                  title: "Version Code",
                  subtitle: app.versionCode.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Function handleIntentError(BuildContext context, String appName) {
  return (err) {
    debugPrint(err.toString());
    Fluttertoast.showToast(
      msg: "Unable to run $appName: $err",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  };
}
