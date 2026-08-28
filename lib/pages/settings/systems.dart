part of 'package:titanius/pages/settings.dart';

class ShowSystemsSettingsPage extends HookConsumerWidget {
  const ShowSystemsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systems = ref.watch(allSupportedSystemsProvider);
    final enabledSystems = ref.watch(enabledSystemsProvider);
    final selectedIndex = usePersistentSelection('/settings/systems');

    useGamepad(ref, (location, key) {
      if (location != "/settings/systems") return;
      final sysList = systems.value ?? [];
      if (sysList.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          sysList.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          sysList.length - 1,
        );
      }
      if (key == GamepadButton.a) {
        final sys = sysList[selectedIndex.value.clamp(0, sysList.length - 1)];
        final show = enabledSystems.value?.showSystem(sys.id) ?? true;
        ref.read(enabledSystemsRepoProvider).setShowSystem(sys.id, !show).then((
          value,
        ) {
          ref.read(selectedSystemProvider.notifier).state = 0;
          final _ = ref.refresh(enabledSystemsProvider);
        });
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Enabled Systems/Collections')),
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
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            data: (enabledSystems) {
              return ControllerGroupedListView<System, String>(
                key: const PageStorageKey("settings/systems"),
                selectedIndex: selectedIndex.value,
                elements: systems,
                groupBy: (element) =>
                    element.isCollection ? "Collections" : "Systems",
                groupSeparatorBuilder: (String value) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                indexedItemBuilder: (context, system, index) {
                  final showSystem = enabledSystems.showSystem(system.id);
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
                          selected: isSelected,
                          selectedColor: Colors.black,
                          selectedTileColor: Colors.transparent,
                          dense: true,
                          onTap: () {
                            selectedIndex.value = index;
                            ref
                                .read(enabledSystemsRepoProvider)
                                .setShowSystem(
                                  system.id,
                                  showSystem ? false : true,
                                )
                                .then((value) {
                                  ref
                                          .read(selectedSystemProvider.notifier)
                                          .state =
                                      0;
                                  final _ = ref.refresh(enabledSystemsProvider);
                                });
                          },
                          title: Text(
                            system.name,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: showSystem ? toggleOnIcon : toggleOffIcon,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(child: Text('Error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Error')),
      ),
    );
  }
}
