import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/emulators.dart';
import '../data/settings.dart';
import '../data/systems.dart';
import '../gamepad.dart';

part 'settings/systems.dart';
part 'settings/emulators.dart';
part 'settings/ui.dart';

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
      body: ListView(
        children: [
          ListTile(
            autofocus: true,
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
            title: const Text('Settings'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }
}
