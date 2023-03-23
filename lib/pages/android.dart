import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndialog/ndialog.dart';
import 'package:titanius/data/android_apps.dart';

import '../data/state.dart';
import '../gamepad.dart';
import '../data/systems.dart';
import '../widgets/appbar.dart';
import '../widgets/prompt_bar.dart';

const double verticalSpacing = 10;

class AndroidPage extends HookConsumerWidget {
  const AndroidPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSystems = ref.watch(detectedSystemsProvider);
    final allApps = ref.watch(installedAppsProvider);
    final selectedIndex = ref.watch(selectedGameProvider("android"));

    final pageController = PageController(initialPage: selectedIndex);

    useGamepad(ref, (location, key) {
      if (location != "/android") return;
      if (allSystems.value == null || allSystems.value!.isEmpty) return;
      if (key == GamepadButton.r2 || key == GamepadButton.right) {
        final currentSystem = ref.read(selectedSystemProvider);
        final next = (currentSystem + 1) % allSystems.value!.length;
        ref.read(selectedSystemProvider.notifier).set(next);
      }
      if (key == GamepadButton.l2 || key == GamepadButton.left) {
        final currentSystem = ref.read(selectedSystemProvider);
        final prev = currentSystem - 1 < 0
            ? allSystems.value!.length - 1
            : currentSystem - 1;
        ref.read(selectedSystemProvider.notifier).set(prev);
      }
      if (key == GamepadButton.y) {}
      if (key == GamepadButton.start) {
        GoRouter.of(context).push("/settings");
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/");
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const PromptBar(
        navigations: {
          GamepadButton.leftRight: "System",
          GamepadButton.start: "Menu",
          //GamepadButton.select: "Filter",
        },
        actions: {
          //GamepadButton.y: "Favourite",
          //GamepadButton.x: "Settings",
          GamepadButton.b: "Back",
          GamepadButton.a: "Launch",
        },
      ),
      body: allApps.when(
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(
              child: Text("No games found"),
            );
          }
          final selectedApp =
              apps[selectedIndex < apps.length ? selectedIndex : 0];
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Image.asset(
                        "assets/images/small/Android.png",
                        fit: BoxFit.fitHeight,
                        errorBuilder: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                          key: const PageStorageKey("android/games"),
                          controller: pageController,
                          itemCount: apps.length,
                          itemBuilder: (context, index) {
                            final app = apps[index];
                            return ListTile(
                              horizontalTitleGap: 0,
                              //dense: true,
                              visualDensity: VisualDensity.compact,
                              autofocus: selectedIndex < apps.length
                                  ? index == selectedIndex
                                  : index == 0,
                              onFocusChange: (value) {
                                if (value) {
                                  ref
                                      .read(selectedGameProvider("android")
                                          .notifier)
                                      .set(index);
                                }
                              },
                              title: Text(
                                app.appName,
                                softWrap: false,
                              ),
                              onTap: () async {
                                app
                                    .openApp()
                                    .catchError(handleIntentError(context));
                              },
                            );
                          }),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey.shade800,
                  padding: const EdgeInsets.all(verticalSpacing),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.memory(
                          selectedApp.icon,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: verticalSpacing),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(selectedApp.packageName),
                          Text(
                            selectedApp.versionName ?? "Unknown version",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }
}

Function handleIntentError(BuildContext context) {
  return (err) {
    print(
        "PlatformException code=${(err as PlatformException).code} details=${(err).details}");
    NDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text("NDialog"),
      content: Text("This is NDialog's content"),
      actions: <Widget>[
        TextButton(
            child: Text("Okay"), onPressed: () => Navigator.pop(context)),
        TextButton(
            child: Text("Close"), onPressed: () => Navigator.pop(context)),
      ],
    ).show(context);
  };
}
