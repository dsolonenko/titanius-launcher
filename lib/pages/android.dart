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

class AndroidPage extends HookConsumerWidget {
  const AndroidPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allApps = ref.watch(selectedAndroidAppsProvider);
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
      final apps = allApps.value;
      if (apps == null || apps.isEmpty) {
        if (key == GamepadButton.back) {
          GoRouter.of(context).go("/");
        }
        if (key == GamepadButton.y) {
          GoRouter.of(context).go("/select_apps");
        }
        return;
      }

      int currentIndex = apps.indexOf(selectedApp ?? apps.first);
      if (currentIndex == -1) currentIndex = 0;

      final screenWidth = MediaQuery.of(context).size.width - 24;
      final columns = showDetals.value
          ? 1
          : (screenWidth / 150).ceil().clamp(1, 20);

      if (key == GamepadButton.up) {
        if (showDetals.value) {
          if (currentIndex > 0) {
            ref.read(selectedAppProvider.notifier).state = apps[currentIndex - 1];
          }
        } else {
          final newIndex = (currentIndex - columns).clamp(0, apps.length - 1);
          ref.read(selectedAppProvider.notifier).state = apps[newIndex];
        }
      }
      if (key == GamepadButton.down) {
        if (showDetals.value) {
          if (currentIndex < apps.length - 1) {
            ref.read(selectedAppProvider.notifier).state = apps[currentIndex + 1];
          }
        } else {
          final newIndex = (currentIndex + columns).clamp(0, apps.length - 1);
          ref.read(selectedAppProvider.notifier).state = apps[newIndex];
        }
      }
      if (key == GamepadButton.left) {
        if (currentIndex > 0) {
          final newIndex = currentIndex - 1;
          ref.read(selectedAppProvider.notifier).state = apps[newIndex];
        }
      }
      if (key == GamepadButton.right) {
        if (currentIndex < apps.length - 1) {
          final newIndex = currentIndex + 1;
          ref.read(selectedAppProvider.notifier).state = apps[newIndex];
        }
      }
      if (key == GamepadButton.confirm) {
        final app = apps[currentIndex];
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
      body: allApps.when(
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(child: Text("No apps selected"));
          }
          final matchedIndex = selectedApp == null
              ? 0
              : apps.indexWhere(
                  (app) => app.packageName == selectedApp.packageName,
                );
          final selectedIndex = matchedIndex < 0 ? 0 : matchedIndex;
          final appToShow = apps[selectedIndex];
          return showDetals.value
              ? Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: ControllerListView.builder(
                        key: const PageStorageKey("android/apps_list"),
                        selectedIndex: selectedIndex,
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          final selected = index == selectedIndex;
                          return _appTileList(context, ref, app, selected);
                        },
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: _appDetails(appToShow, detailsScrollController),
                      ),
                    ),
                  ],
                )
              : ControllerGridView.builder(
                  maxCrossAxisExtent: 150,
                  childAspectRatio: 0.88,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  padding: const EdgeInsets.all(12),
                  key: const PageStorageKey("android/apps_grid"),
                  selectedIndex: selectedIndex,
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    final selected = index == selectedIndex;
                    return _appTileGrid(context, ref, app, selected);
                  },
                );
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) => Text(error.toString()),
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
