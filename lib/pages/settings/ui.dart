part of '../settings.dart';

class UISettingsPage extends HookConsumerWidget {
  const UISettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    useGamepad(ref, (location, key) {
      if (location != "/settings/ui") return;
      if (key == GamepadButton.b) {
        print("UI settings pop at ${GoRouter.of(context).location}");
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Settings'),
      ),
      body: settings.when(
        data: (settings) {
          final favouritesOnTop = settings.favouritesOnTop;
          return ListView(
            children: [
              ListTile(
                autofocus: true,
                onFocusChange: (value) {},
                onTap: () {
                  ref
                      .read(settingsRepoProvider)
                      .value!
                      .setFavoutesOnTop(!favouritesOnTop)
                      .then((value) => ref.refresh(settingsProvider));
                },
                title: const Text('Show Favouries On Top'),
                trailing: favouritesOnTop ? toggleOnIcon : toggleOffIcon,
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
