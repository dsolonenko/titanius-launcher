import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ndialog/ndialog.dart';
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
    final selectedIndex = ref.watch(selectedGameProvider("android"));

    final pageController = PageController(initialPage: selectedIndex);

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const PromptBar(
        navigations: {
          GamepadButton.l1: "",
          GamepadButton.r1: "System",
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
          return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 100),
              key: const PageStorageKey("android/games"),
              controller: pageController,
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return ListTile(
                  autofocus: selectedIndex < apps.length
                      ? index == selectedIndex
                      : index == 0,
                  onFocusChange: (value) {
                    if (value) {
                      ref
                          .read(selectedGameProvider("android").notifier)
                          .set(index);
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
                    app.openApp().catchError(handleIntentError(context));
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
