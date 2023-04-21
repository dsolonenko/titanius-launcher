part of '../settings.dart';

class ShowSystemsSettingsPage extends HookConsumerWidget {
  const ShowSystemsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systems = ref.watch(allSupportedSystemsProvider);
    final enabledSystems = ref.watch(enabledSystemsProvider);

    final selected = useState("");

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
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.a], "Change"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: systems.when(
        data: (systems) {
          return enabledSystems.when(
            data: (enabledSystems) {
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
                  final showSystem = enabledSystems.showSystem(system.id);
                  return ListTile(
                    autofocus: selected.value == system.id || (selected.value.isEmpty && index == 0),
                    onFocusChange: (value) {
                      if (value) {
                        selected.value = system.id;
                      }
                    },
                    onTap: () {
                      ref
                          .read(enabledSystemsRepoProvider)
                          .value!
                          .setShowSystem(system.id, showSystem ? false : true)
                          .then((value) => ref.refresh(enabledSystemsProvider));
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
