import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_storage/saf.dart' as saf;

import 'package:titanius/data/android_apps.dart';
import 'package:titanius/data/android_saf.dart';
import 'package:titanius/data/daijisho.dart';
import 'package:titanius/data/emulators.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/gamepad_prompt.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/icons.dart';

part 'package:titanius/pages/settings/systems.dart';
part 'package:titanius/pages/settings/emulators.dart';
part 'package:titanius/pages/settings/ui.dart';
part 'package:titanius/pages/settings/roms.dart';
part 'package:titanius/pages/settings/apps.dart';
part 'package:titanius/pages/settings/daijisho.dart';

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
          /*
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/scraper");
            },
            title: const Text('Scraper'),
            trailing: arrowRight,
          ),
          */
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/roms");
            },
            title: const Text('ROMs Folders'),
            trailing: arrowRight,
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/systems");
            },
            title: const Text('Systems/Collections'),
            trailing: arrowRight,
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/emulators");
            },
            title: const Text('Emulators'),
            trailing: arrowRight,
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/ui");
            },
            title: const Text('UI Settings'),
            trailing: arrowRight,
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/settings/daijisho");
            },
            title: const Text('Daijishō Wallpaper Pack'),
            trailing: arrowRight,
          ),
        ],
      ),
    );
  }
}
