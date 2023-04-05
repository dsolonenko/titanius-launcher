part of '../settings.dart';

class UISettingsPage extends HookConsumerWidget {
  const UISettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
            children: [
              ListTile(
                autofocus: true,
                onFocusChange: (value) {},
                onTap: () {
                  ref
                      .read(settingsRepoProvider)
                      .value!
                      .setShowGameVideos(!settings.showGameVideos)
                      .then((value) => ref.refresh(settingsProvider));
                },
                title: const Text('Show Game Videos'),
                trailing:
                    settings.showGameVideos ? toggleOnIcon : toggleOffIcon,
              ),
              ListTile(
                onFocusChange: (value) {},
                onTap: () {
                  ref
                      .read(settingsRepoProvider)
                      .value!
                      .setFavoutesOnTop(!settings.favouritesOnTop)
                      .then((value) => ref.refresh(settingsProvider));
                },
                title: const Text('Show Favouries On Top'),
                trailing:
                    settings.favouritesOnTop ? toggleOnIcon : toggleOffIcon,
              ),
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
}
