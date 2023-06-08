import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:titanius/data/android_apps.dart';
import 'package:titanius/data/state.dart';
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
          debugPrint("show=${appToShow.packageName} index=$index");
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
                          InfoTile(title: "Name", subtitle: appToShow.appName),
                          InfoTile(title: "Package", subtitle: appToShow.packageName),
                          InfoTile(title: "Version", subtitle: appToShow.versionName ?? "-"),
                          InfoTile(title: "Category", subtitle: appToShow.category.toString()),
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

  ListTile _appTileGrid(BuildContext context, WidgetRef ref, ApplicationWithIcon app, bool selected) {
    return ListTile(
      key: ValueKey("android/grid/${app.packageName}"),
      autofocus: selected,
      selected: selected,
      onFocusChange: (value) {
        if (value) {
          ref.read(selectedAppProvider.notifier).set(app);
        }
      },
      title: CachedMemoryImage(
        uniqueKey: app.packageName,
        bytes: app.icon,
        fit: BoxFit.contain,
      ),
      subtitle: Text(
        textAlign: TextAlign.center,
        app.appName,
        softWrap: false,
      ),
      onTap: () async {
        app.openApp().catchError(handleIntentError(context, app.appName));
      },
    );
  }

  ListTile _appTileList(BuildContext context, WidgetRef ref, ApplicationWithIcon app, bool selected) {
    return ListTile(
      key: ValueKey("android/list/${app.packageName}"),
      autofocus: selected,
      selected: selected,
      onFocusChange: (value) {
        if (value) {
          ref.read(selectedAppProvider.notifier).set(app);
        }
      },
      leading: CachedMemoryImage(
        uniqueKey: app.packageName,
        bytes: app.icon,
        fit: BoxFit.contain,
      ),
      title: Text(app.appName),
      onTap: () async {
        app.openApp().catchError(handleIntentError(context, app.appName));
      },
    );
  }
}

Function handleIntentError(BuildContext context, String appName) {
  return (err) {
    debugPrint(err.toString());
    Fluttertoast.showToast(
        msg: "Unable to run $appName}: $err",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  };
}
