import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:titanius/data/android_apps.dart';

import '../data/state.dart';
import '../gamepad.dart';
import '../widgets/appbar.dart';
import '../widgets/prompt_bar.dart';

const double verticalSpacing = 10;

class AndroidPage extends HookConsumerWidget {
  const AndroidPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allApps = ref.watch(installedAppsProvider);
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
          GamepadPrompt([GamepadButton.y], "Manage"),
          GamepadPrompt([GamepadButton.b], "Back"),
          GamepadPrompt([GamepadButton.a], "Launch"),
        ],
      ),
      body: allApps.when(
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(
              child: Text("No games found"),
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
                      child: Column(
                        children: [
                          Expanded(
                            child: ScrollablePositionedList.builder(
                              itemScrollController: scrollController,
                              itemPositionsListener: itemPositionsListener,
                              key: const PageStorageKey("android/apps_list"),
                              initialScrollIndex: index,
                              itemCount: apps.length,
                              itemBuilder: (context, index) {
                                return _appTile(selectedApp, index, apps[index], ref, context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _appDetails(appToShow),
                    ),
                  ],
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 100),
                  key: const PageStorageKey("android/apps_grid"),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    return _appTile(selectedApp, index, apps[index], ref, context);
                  },
                );
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }

  ListTile _appTile(
      ApplicationWithIcon? selectedApp, int index, ApplicationWithIcon app, WidgetRef ref, BuildContext context) {
    return ListTile(
      autofocus: selectedApp == null ? index == 0 : app.packageName == selectedApp.packageName,
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

  Widget _appDetails(ApplicationWithIcon appToShow) {
    return Text(appToShow.packageName);
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
