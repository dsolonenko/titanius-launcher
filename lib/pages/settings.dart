import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titanius/data/models.dart';

import '../data/android_apps.dart';
import '../data/emulators.dart';
import '../data/settings.dart';
import '../data/systems.dart';
import '../gamepad.dart';

part 'settings/systems.dart';
part 'settings/emulators.dart';
part 'settings/ui.dart';
part 'settings/roms.dart';

const toggleSize = 40.0;
const toggleOnIcon = Icon(
  Icons.toggle_on_outlined,
  size: toggleSize,
);
const toggleOffIcon = Icon(
  Icons.toggle_off_outlined,
  size: toggleSize,
  color: Colors.grey,
);

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);

    useGamepad(ref, (location, key) {
      if (location != "/settings") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      bottomNavigationBar: packageInfo.when(
          data: (data) => Text("${data.appName} ${data.version}", textScaleFactor: 0.7, textAlign: TextAlign.center),
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text(error.toString())),
      body: ListView(
        children: [
          ListTile(
            autofocus: true,
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/roms");
            },
            title: const Text('ROMs Folders'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/systems");
            },
            title: const Text('Systems'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/emulators");
            },
            title: const Text('Emulators'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/ui");
            },
            title: const Text('UI Settings'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }
}
