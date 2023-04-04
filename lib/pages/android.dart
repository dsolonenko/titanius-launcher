import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

    useGamepad(ref, (location, key) {
      if (location != "/games/android") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/");
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.l2, GamepadButton.r2], "System"),
          GamepadPrompt([GamepadButton.start], "Menu"),
        ],
        actions: [
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
          return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 100),
              key: const PageStorageKey("android/games"),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return ListTile(
                  autofocus: selectedApp == null
                      ? index == 0
                      : app.packageName == selectedApp.packageName,
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
                    app
                        .openApp()
                        .catchError(handleIntentError(context, app.appName));
                  },
                );
              });
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) => Text(error.toString()),
      ),
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
