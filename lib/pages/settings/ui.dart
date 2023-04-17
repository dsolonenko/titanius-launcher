part of '../settings.dart';

class UISettingsPage extends HookConsumerWidget {
  const UISettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final selectedSetting = useState('Show Favouries On Top');

    useGamepad(ref, (location, key) {
      if (location != "/settings/ui") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Settings'),
      ),
      body: settings.when(
        data: (settings) {
          return ListView(
            key: const PageStorageKey('settings/ui'),
            children: [
              _setting(ref, selectedSetting, 'Show Favouries On Top', settings.favouritesOnTop, true,
                  (p0, p1) => p0.setFavoutesOnTop(p1)),
              // _setting(ref, selectedSetting, 'Compact Game List', settings.compactGameList, true,
              //     (p0, p1) => p0.setCompactGameList(p1)),
              _setting(ref, selectedSetting, 'Show Game Videos', settings.showGameVideos, true,
                  (p0, p1) => p0.setShowGameVideos(p1)),
              _setting(ref, selectedSetting, 'Fade Screenshot To Video', settings.fadeToVideo, settings.showGameVideos,
                  (p0, p1) => p0.setFadeToVideo(p1)),
              _setting(ref, selectedSetting, 'Mute Video', settings.muteVideo, settings.showGameVideos,
                  (p0, p1) => p0.setMuteVideo(p1)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => const Center(
          child: Text('Error'),
        ),
      ),
    );
  }

  Widget _setting(WidgetRef ref, ValueNotifier<String> selectedSetting, String title, bool value, bool enabled,
      Future<void> Function(SettingsRepo, bool) onChanged) {
    return ListTile(
      enabled: enabled,
      autofocus: title == selectedSetting.value,
      onFocusChange: (value) {
        if (value) {
          selectedSetting.value = title;
        }
      },
      onTap: () {
        final repo = ref.read(settingsRepoProvider).value!;
        onChanged(repo, !value).then((value) => ref.refresh(settingsProvider));
      },
      title: Text(title),
      trailing: value ? toggleOnIcon : toggleOffIcon,
    );
  }
}
