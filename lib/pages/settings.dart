import 'package:cached_network_image/cached_network_image.dart';
import 'package:installed_apps/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:titanius/widgets/prompt_dialog.dart';
import 'package:saf/saf.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:titanius/data/android_apps.dart';
import 'package:titanius/data/android_saf.dart';
import 'package:titanius/data/daijisho.dart';
import 'package:titanius/data/daijisho_platforms.dart';
import 'package:titanius/data/emulators.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/retroachievements.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/gamepad_prompt.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/icons.dart';
import 'package:titanius/widgets/selected_scroll_tile.dart';
import 'package:titanius/widgets/selector.dart';

part 'package:titanius/pages/settings/systems.dart';
part 'package:titanius/pages/settings/emulators.dart';
part 'package:titanius/pages/settings/cemulators.dart';
part 'package:titanius/pages/settings/controller.dart';
part 'package:titanius/pages/settings/ui.dart';
part 'package:titanius/pages/settings/roms.dart';
part 'package:titanius/pages/settings/apps.dart';
part 'package:titanius/pages/settings/daijisho.dart';
part 'package:titanius/pages/settings/retroachievements.dart';

class SettingsPage extends HookConsumerWidget {
  final String? source;
  const SettingsPage({super.key, this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final selectedIndex = usePersistentSelection('/settings');

    final settings = ref.watch(settingsProvider);
    final s = settings.value;

    final items = [
      (
        title: 'Refresh GameLists',
        subtitle: null as String?,
        trailing: null as Widget?,
        onTap: () {
          ref.invalidate(detectedSystemsProvider);
          ref.invalidate(loadedSystemsProvider);
          ref.read(gameLibraryProvider).clear();
          ref.invalidate(systemGamesProvider);
          ref.read(allGamesProvider.future);
        },
      ),
      (
        title: 'Scraper',
        subtitle: null as String?,
        trailing: arrowRight,
        onTap: () {
          context.push("/settings/scraper");
        },
      ),
      (
        title: 'RetroAchievements',
        subtitle: s?.hasRetroAchievements == true
            ? s!.retroAchievementsUser
            : 'Not configured',
        trailing: arrowRight,
        onTap: () {
          context.push("/settings/retroachievements");
        },
      ),
      (
        title: 'ROMs Folders',
        subtitle: null as String?,
        trailing: arrowRight,
        onTap: () {
          context.push("/settings/roms");
        },
      ),
      (
        title: 'Systems/Collections',
        subtitle: null as String?,
        trailing: arrowRight,
        onTap: () {
          context.push("/settings/systems");
        },
      ),
      (
        title: 'Emulators',
        subtitle: null as String?,
        trailing: arrowRight,
        onTap: () {
          context.push("/settings/emulators");
        },
      ),
      (
        title: 'Refresh Daijishō Emulators',
        subtitle: null as String?,
        trailing: null as Widget?,
        onTap: () {
          _refreshDaijishoEmulators(context, ref);
        },
      ),
      (
        title: 'Custom Emulators',
        subtitle: null as String?,
        trailing: arrowRight,
        onTap: () {
          context.push("/settings/cemulators");
        },
      ),
      (
        title: 'Controller',
        subtitle: null as String?,
        trailing: arrowRight,
        onTap: () {
          context.push("/settings/controller");
        },
      ),
      (
        title: 'UI Settings',
        subtitle: null as String?,
        trailing: arrowRight,
        onTap: () {
          context.push("/settings/ui");
        },
      ),
      (
        title: 'Daijishō Wallpaper Pack',
        subtitle: null as String?,
        trailing: arrowRight,
        onTap: () {
          context.push("/settings/daijisho");
        },
      ),
    ];

    useGamepad(ref, (location, key) {
      if (location != "/settings") return;
      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.confirm) {
        items[selectedIndex.value].onTap();
      }
      if (key == GamepadButton.back) {
        if (source == "root") {
          GoRouter.of(context).go("/");
        } else {
          GoRouter.of(context).go("/games/$source");
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      bottomNavigationBar: PromptBar(
        text: packageInfo.when(
          data: (data) => "${data.appName} ${data.version}",
          loading: () => "",
          error: (error, stackTrace) => error.toString(),
        ),
        actions: const [
          GamepadPrompt([GamepadButton.confirm], "Select"),
          GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: ControllerListView.builder(
        selectedIndex: selectedIndex.value,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = index == selectedIndex.value;
          return SelectedScrollTile(
            isSelected: isSelected,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Material(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                child: ListTile(
                  selected: isSelected,
                  selectedColor: Colors.black,
                  selectedTileColor: Colors.transparent,
                  dense: true,
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: item.subtitle != null
                      ? Text(
                          item.subtitle!,
                          style: TextStyle(
                            color: isSelected ? Colors.black87 : Colors.grey,
                          ),
                        )
                      : null,
                  trailing: item.trailing,
                  onTap: () {
                    selectedIndex.value = index;
                    item.onTap();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
