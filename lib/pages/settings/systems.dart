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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enabled Systems/Collections'),
      ),
      body: systems.when(
        data: (systems) {
          systems = [...collections, ...systems];
          return settings.when(
            data: (settings) {
              return GroupedListView<System, String>(
                key: const PageStorageKey("settings/systems"),
                elements: systems,
                groupBy: (element) => element.isCollection ? "Collections" : "Systems",
                groupSeparatorBuilder: (String value) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                indexedItemBuilder: (context, system, index) {
                  final showSystem = settings.showSystem(system.id);
                  return ListTile(
                    autofocus: index == 0,
                    onFocusChange: (value) {},
                    onTap: () {
                      ref
                          .read(settingsRepoProvider)
                          .value!
                          .setShowSystem(system.id, showSystem ? false : true)
                          .then((value) => ref.refresh(settingsProvider));
                    },
                    title: Text(system.name),
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
