part of 'package:titanius/pages/settings.dart';

class ShowSystemsSettingsPage extends HookConsumerWidget {
  const ShowSystemsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systems = ref.watch(allSupportedSystemsProvider);
    final selectionReady = ref.watch(
      enabledSystemsChangesProvider.select((selection) => selection.hasValue),
    );
    final hasRetroAchievements = ref.watch(
      settingsProvider.select(
        (settings) => settings.value?.hasRetroAchievements ?? false,
      ),
    );
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
      if (key == GamepadButton.confirm) {
        final sys = sysList[selectedIndex.value.clamp(0, sysList.length - 1)];
        final enabled = ref.read(enabledSystemsChangesProvider).value;
        if (enabled != null) {
          ref
              .read(enabledSystemsRepoProvider)
              .setShowSystem(sys.id, !enabled.showSystem(sys.id));
        }
        ref.read(selectedSystemProvider.notifier).state = 0;
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Enabled Systems/Collections')),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.confirm], "Change"),
          GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: systems.when(
        data: (systems) {
          if (!selectionReady) {
            return const Center(child: CircularProgressIndicator());
          }
          return ControllerGroupedListView<System, String>(
            key: const PageStorageKey("settings/systems"),
            selectedIndex: selectedIndex.value,
            elements: systems,
            groupBy: (element) =>
                element.isCollection ? "Collections" : "Systems",
            groupSeparatorBuilder: (String value) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(value, style: const TextStyle(color: Colors.grey)),
            ),
            indexedItemBuilder: (context, system, index) {
              final isSelected = index == selectedIndex.value;
              return Consumer(
                builder: (context, ref, _) {
                  final showSystem = ref.watch(
                    enabledSystemsChangesProvider.select(
                      (selection) =>
                          selection.value?.showSystem(system.id) ?? true,
                    ),
                  );
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
                                .setShowSystem(system.id, !showSystem);
                            ref.read(selectedSystemProvider.notifier).state = 0;
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
                          subtitle:
                              system.isRetroAchievements &&
                                  !hasRetroAchievements
                              ? Text(
                                  "Requires RetroAchievements login",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.black54
                                        : Colors.orangeAccent,
                                  ),
                                )
                              : null,
                          trailing: showSystem ? toggleOnIcon : toggleOffIcon,
                        ),
                      ),
                    ),
                  );
                },
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
