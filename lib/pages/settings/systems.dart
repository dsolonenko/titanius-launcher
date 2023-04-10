part of '../settings.dart';

class ShowSystemsSettingsPage extends HookConsumerWidget {
  const ShowSystemsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systems = ref.watch(allSupportedSystemsProvider);
    final settings = ref.watch(settingsProvider);

    useGamepad(ref, (location, key) {
      if (location != "/settings/systems") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    final selected = useState<String?>(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enabled Systems'),
      ),
      body: systems.when(
        data: (systems) {
          return settings.when(
            data: (settings) {
              return ListView.builder(
                key: const PageStorageKey("settings/systems"),
                itemCount: systems.length,
                itemBuilder: (context, index) {
                  final showSystem = settings.showSystem(systems[index].id);
                  return ListTile(
                    autofocus: selected.value == systems[index].id || index == 0,
                    onFocusChange: (value) {
                      if (value) {
                        selected.value = systems[index].id;
                      }
                    },
                    onTap: () {
                      ref
                          .read(settingsRepoProvider)
                          .value!
                          .setShowSystem(systems[index].id, showSystem ? false : true)
                          .then((value) => ref.refresh(settingsProvider));
                    },
                    title: Text(systems[index].name),
                    trailing: showSystem ? toggleOnIcon : toggleOffIcon,
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => const Center(
              child: Text('Error'),
            ),
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
