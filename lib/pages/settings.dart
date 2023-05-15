import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_storage/saf.dart' as saf;

import '../data/android_apps.dart';
import '../data/android_saf.dart';
import '../data/daijisho.dart';
import '../data/emulators.dart';
import '../data/games.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../data/state.dart';
import '../data/systems.dart';
import '../gamepad.dart';
import '../widgets/gamepad_prompt.dart';
import '../widgets/prompt_bar.dart';

part 'settings/systems.dart';
part 'settings/emulators.dart';
part 'settings/ui.dart';
part 'settings/roms.dart';
part 'settings/apps.dart';
part 'settings/daijisho.dart';

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
  final String? source;
  const SettingsPage({super.key, this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);

    useGamepad(ref, (location, key) {
      if (location != "/settings?source=$source") return;
      if (key == GamepadButton.b) {
        if (source == "root") {
          GoRouter.of(context).go("/");
        } else {
          GoRouter.of(context).go("/games/$source");
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      bottomNavigationBar: PromptBar(
        text: packageInfo.when(
            data: (data) => "${data.appName} ${data.version}",
            loading: () => "",
            error: (error, stackTrace) => error.toString()),
        actions: const [
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            autofocus: true,
            onFocusChange: (value) {},
            onTap: () {
              // ignore: unused_result
              ref.refresh(detectedSystemsProvider).whenData((value) => ref.read(allGamesProvider));
            },
            title: const Text('Refresh GameLists'),
          ),
          ListTile(
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
            title: const Text('Systems/Collections'),
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
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/daijisho");
            },
            title: const Text('Daijishō Wallpaper Pack'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }
}
