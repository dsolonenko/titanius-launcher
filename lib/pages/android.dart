import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:titanius/data/android_apps.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/appbar.dart';
import 'package:titanius/widgets/info_tile.dart';
import 'package:titanius/widgets/prompt_bar.dart';

const double verticalSpacing = 10;

class AndroidPage extends HookConsumerWidget {
  const AndroidPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allApps = ref.watch(selectedAndroidAppsProvider);
    final selectedApp = ref.watch(selectedAppProvider);

    final showDetals = useState(false);

    final scrollController = ItemScrollController();
    final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

    useGamepad(ref, (location, key) {
      if (location != "/games/android") return;
      final apps = allApps.value;
      if (apps == null || apps.isEmpty) {
        if (key == GamepadButton.b) {
          GoRouter.of(context).go("/");
        }
        if (key == GamepadButton.y) {
          GoRouter.of(context).go("/select_apps");
        }
        return;
      }

      int currentIndex = apps.indexOf(selectedApp ?? apps.first);
      if (currentIndex == -1) currentIndex = 0;

      if (key == GamepadButton.up) {
        if (currentIndex > 0) {
          final newIndex = currentIndex - 1;
          ref.read(selectedAppProvider.notifier).state = apps[newIndex];
          if (showDetals.value) {
            _ensureVisible(scrollController, itemPositionsListener, newIndex);
          }
        }
      }
      if (key == GamepadButton.down) {
        if (currentIndex < apps.length - 1) {
          final newIndex = currentIndex + 1;
          ref.read(selectedAppProvider.notifier).state = apps[newIndex];
          if (showDetals.value) {
            _ensureVisible(scrollController, itemPositionsListener, newIndex);
          }
        }
      }
      if (key == GamepadButton.left) {
        if (!showDetals.value && currentIndex > 0) {
          final newIndex = currentIndex - 1;
          ref.read(selectedAppProvider.notifier).state = apps[newIndex];
        }
      }
      if (key == GamepadButton.right) {
        if (!showDetals.value && currentIndex < apps.length - 1) {
          final newIndex = currentIndex + 1;
          ref.read(selectedAppProvider.notifier).state = apps[newIndex];
        }
      }
      if (key == GamepadButton.a) {
        final app = apps[currentIndex];
        ref.read(selectedAppProvider.notifier).state = app;
        InstalledApps.startApp(app.packageName).catchError(handleIntentError(context, app.name));
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
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/");
      }
      if (key == GamepadButton.x) {
        showDetals.value = !showDetals.value;
      }
      if (key == GamepadButton.y) {
        GoRouter.of(context).go("/select_apps");
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.upDown, GamepadButton.leftRight], "Select"),
          GamepadPrompt([GamepadButton.l2, GamepadButton.r2], "System"),
          GamepadPrompt([GamepadButton.start], "Menu"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.x], "Details"),
          GamepadPrompt([GamepadButton.y], "Select Apps"),
          GamepadPrompt([GamepadButton.b], "Back"),
          GamepadPrompt([GamepadButton.a], "Launch"),
        ],
      ),
      body: allApps.when(
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(
              child: Text("No apps selected"),
            );
          }
          final appToShow = selectedApp ?? apps.first;
          final index = apps.indexOf(appToShow).clamp(0, apps.length - 1);
          return showDetals.value
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ScrollablePositionedList.builder(
                        itemScrollController: scrollController,
                        itemPositionsListener: itemPositionsListener,
                        key: const PageStorageKey("android/apps_list"),
                        initialScrollIndex: index,
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          final selected =
                              selectedApp == null ? index == 0 : app.packageName == selectedApp.packageName;
                          return _appTileList(context, ref, app, selected);
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: InfoTiles(
                        children: [
                          InfoTile(title: "Name", subtitle: appToShow.name),
                          InfoTile(title: "Package", subtitle: appToShow.packageName),
                          InfoTile(title: "Version", subtitle: appToShow.versionName),
                        ],
                      ),
                    ),
                  ],
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 100),
                  key: const PageStorageKey("android/apps_grid"),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    final selected = selectedApp == null ? index == 0 : app.packageName == selectedApp.packageName;
                    return _appTileGrid(context, ref, app, selected);
                  },
                );
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }

  Widget _appTileGrid(BuildContext context, WidgetRef ref, AppInfo app, bool selected) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: ListTile(
          key: ValueKey("android/grid/${app.packageName}"),
          selected: selected,
          selectedColor: Colors.black,
          selectedTileColor: Colors.transparent,
          title: app.icon != null
              ? CachedMemoryImage(
                  uniqueKey: app.packageName,
                  bytes: app.icon!,
                  fit: BoxFit.contain,
                )
              : Icon(Icons.android, color: selected ? Colors.black : Colors.white),
          subtitle: Text(
            textAlign: TextAlign.center,
            app.name,
            softWrap: false,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () async {
            ref.read(selectedAppProvider.notifier).state = app;
            InstalledApps.startApp(app.packageName).catchError(handleIntentError(context, app.name));
          },
        ),
      ),
    );
  }

  Widget _appTileList(BuildContext context, WidgetRef ref, AppInfo app, bool selected) {
    return Container(
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
              ? CachedMemoryImage(
                  uniqueKey: app.packageName,
                  bytes: app.icon!,
                  fit: BoxFit.contain,
                )
              : Icon(Icons.android, color: selected ? Colors.black : Colors.white),
          title: Text(
            app.name,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () async {
            ref.read(selectedAppProvider.notifier).state = app;
            InstalledApps.startApp(app.packageName).catchError(handleIntentError(context, app.name));
          },
        ),
      ),
    );
  }
}

void _ensureVisible(
    ItemScrollController scrollController, ItemPositionsListener itemPositionsListener, int targetIndex) {
  if (!scrollController.isAttached) return;
  final positions = itemPositionsListener.itemPositions.value.toList();
  if (positions.isEmpty) {
    scrollController.jumpTo(index: targetIndex, alignment: 0.0);
    return;
  }
  positions.sort((a, b) => a.index.compareTo(b.index));
  final firstItem = positions.first;
  final lastItem = positions.last;

  if (targetIndex < firstItem.index || (targetIndex == firstItem.index && firstItem.itemLeadingEdge < 0.0)) {
    scrollController.jumpTo(index: targetIndex, alignment: 0.0);
  } else if (targetIndex > lastItem.index || (targetIndex == lastItem.index && lastItem.itemTrailingEdge > 1.0)) {
    scrollController.jumpTo(index: targetIndex, alignment: 1.0);
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
        fontSize: 16.0);
  };
}
