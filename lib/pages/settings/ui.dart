part of 'package:titanius/pages/settings.dart';

class UISettingsPage extends HookConsumerWidget {
  const UISettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final selectedIndex = usePersistentSelection('/settings/ui');

    final s = settings.value;

    void adjustFontScale(double delta) {
      final current = ref.read(settingsProvider).value;
      if (current == null) return;
      final currentScale = current.fontScale;
      final newScale = double.parse(
        (currentScale + delta).clamp(0.10, 3.00).toStringAsFixed(1),
      );
      final repo = ref.read(settingsRepoProvider);
      repo
          .setFontScale(newScale)
          .then((value) => ref.invalidate(settingsProvider));
    }

    void resetFontScale() {
      final repo = ref.read(settingsRepoProvider);
      repo.setFontScale(1.0).then((value) => ref.invalidate(settingsProvider));
    }

    final currentScaleStr = s == null
        ? "1.0x"
        : "${s.fontScale.toStringAsFixed(1)}x";

    final items = s == null
        ? <_UiSettingItem>[]
        : [
            _UiSettingItem(
              title: 'Font Scale',
              trailing: SelectorWidget(text: currentScaleStr),
              enabled: true,
              onAction: (repo) async => resetFontScale(),
              onLeft: (repo) async => adjustFontScale(-0.1),
              onRight: (repo) async => adjustFontScale(0.1),
            ),
            _UiSettingItem(
              title: 'Show Favouries On Top',
              trailing: s.favouritesOnTop ? toggleOnIcon : toggleOffIcon,
              enabled: true,
              onAction: (repo) => repo.setFavoutesOnTop(!s.favouritesOnTop),
            ),
            _UiSettingItem(
              title: 'Show Only Unique Games In Collections',
              trailing: s.uniqueGamesInCollections
                  ? toggleOnIcon
                  : toggleOffIcon,
              enabled: true,
              onAction: (repo) =>
                  repo.setUniqueGamesInCollections(!s.uniqueGamesInCollections),
            ),
            _UiSettingItem(
              title: 'Show Hidden Games',
              trailing: s.showHiddenGames ? toggleOnIcon : toggleOffIcon,
              enabled: true,
              onAction: (repo) => repo.setShowHiddenGames(!s.showHiddenGames),
            ),
            _UiSettingItem(
              title: 'Only Show Roms From gamelist.xml Files',
              trailing: s.showOnlyGamelistRoms ? toggleOnIcon : toggleOffIcon,
              enabled: true,
              subtitle: 'Please refresh gamelists',
              onAction: (repo) =>
                  repo.setShowOnlyGamelistRoms(!s.showOnlyGamelistRoms),
            ),
            _UiSettingItem(
              title: 'Show Game Videos',
              trailing: s.showGameVideos ? toggleOnIcon : toggleOffIcon,
              enabled: true,
              onAction: (repo) => repo.setShowGameVideos(!s.showGameVideos),
            ),
            _UiSettingItem(
              title: 'Fade Screenshot To Video',
              trailing: s.fadeToVideo ? toggleOnIcon : toggleOffIcon,
              enabled: s.showGameVideos,
              onAction: (repo) => repo.setFadeToVideo(!s.fadeToVideo),
            ),
            _UiSettingItem(
              title: 'Mute Video',
              trailing: s.muteVideo ? toggleOnIcon : toggleOffIcon,
              enabled: s.showGameVideos,
              onAction: (repo) => repo.setMuteVideo(!s.muteVideo),
            ),
          ];

    useGamepad(ref, (location, key) {
      if (location != "/settings/ui") return;
      if (items.isEmpty) return;

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
      if (key == GamepadButton.left) {
        final item = items[selectedIndex.value.clamp(0, items.length - 1)];
        if (item.enabled && item.onLeft != null) {
          final repo = ref.read(settingsRepoProvider);
          item.onLeft!(repo).then((value) => ref.invalidate(settingsProvider));
        }
      }
      if (key == GamepadButton.right) {
        final item = items[selectedIndex.value.clamp(0, items.length - 1)];
        if (item.enabled && item.onRight != null) {
          final repo = ref.read(settingsRepoProvider);
          item.onRight!(repo).then((value) => ref.invalidate(settingsProvider));
        }
      }
      if (key == GamepadButton.a) {
        final item = items[selectedIndex.value.clamp(0, items.length - 1)];
        if (item.enabled && item.onAction != null) {
          final repo = ref.read(settingsRepoProvider);
          item.onAction!(repo).then(
            (value) => ref.invalidate(settingsProvider),
          );
        }
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('UI Settings')),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.leftRight], "Select"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.a], "Change"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: settings.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (_) {
          return ControllerListView.builder(
            key: const PageStorageKey('settings/ui'),
            selectedIndex: selectedIndex.value,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = index == selectedIndex.value;
              return SelectedScrollTile(
                isSelected: isSelected,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Material(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    child: ListTile(
                      enabled: item.enabled,
                      selected: isSelected,
                      selectedColor: Colors.black,
                      selectedTileColor: Colors.transparent,
                      dense: true,
                      onTap: () {
                        selectedIndex.value = index;
                        if (item.enabled && item.onAction != null) {
                          final repo = ref.read(settingsRepoProvider);
                          item.onAction!(repo).then(
                            (value) => ref.invalidate(settingsProvider),
                          );
                        }
                      },
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: !item.enabled
                              ? Colors.grey
                              : isSelected
                              ? Colors.black
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: item.subtitle != null
                          ? Text(
                              item.subtitle!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            )
                          : null,
                      trailing: item.trailing,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Error')),
      ),
    );
  }
}

class _UiSettingItem {
  final String title;
  final String? subtitle;
  final Widget trailing;
  final bool enabled;
  final Future<void> Function(SettingsRepo repo)? onAction;
  final Future<void> Function(SettingsRepo repo)? onLeft;
  final Future<void> Function(SettingsRepo repo)? onRight;

  _UiSettingItem({
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.enabled,
    this.onAction,
    this.onLeft,
    this.onRight,
  });
}
