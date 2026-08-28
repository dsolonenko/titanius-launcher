part of 'package:titanius/pages/settings.dart';

class AlternativeEmulatorsSettingPage extends HookConsumerWidget {
  const AlternativeEmulatorsSettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulators = ref.watch(alternativeEmulatorsProvider);
    final selectedIndex = useState(0);

    useGamepad(ref, (location, key) {
      if (location != "/settings/emulators") return;
      final emuList = emulators.value?.where((element) => element.defaultEmulator != null).toList() ?? [];
      if (emuList.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(0, emuList.length - 1);
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(0, emuList.length - 1);
      }
      if (key == GamepadButton.a) {
        final current = emuList[selectedIndex.value.clamp(0, emuList.length - 1)];
        context.push("/settings/emulators/${current.system.id}");
      }
      if (key == GamepadButton.x) {
        final current = emuList[selectedIndex.value.clamp(0, emuList.length - 1)];
        ref
            .read(perSystemConfigurationRepoProvider)
            .deleteAlternativeEmulator(current.system.id)
            .then((value) => ref.refresh(perSystemConfigurationsProvider));
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternative Emulators'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.a], "Change"),
          GamepadPrompt([GamepadButton.x], "Default"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: emulators.when(
        data: (emulators) {
          final emuList = emulators.where((element) => element.defaultEmulator != null).toList();
          return ListView.builder(
            key: const PageStorageKey("settings/emulators"),
            itemCount: emuList.length,
            itemBuilder: (context, index) {
              final isStandalone = emuList[index].defaultEmulator!.isStandalone;
              final isCustom = emuList[index].defaultEmulator!.isCustom;
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
                      onTap: () {
                        selectedIndex.value = index;
                        context.push("/settings/emulators/${emuList[index].system.id}");
                      },
                      title: Text(
                        emuList[index].system.name,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        "${emuList[index].defaultEmulator!.name}${isCustom ? " (Custom)" : isStandalone ? " (Standalone)" : ""}",
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
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
      ),
    );
  }
}

class SelectAlternativeEmulatorSettingPage extends HookConsumerWidget {
  const SelectAlternativeEmulatorSettingPage(this.system, {super.key});

  final String system;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulators = ref.watch(alternativeEmulatorsProvider);
    final selectedIndex = useState(0);

    useGamepad(ref, (location, key) {
      if (location != "/settings/emulators/$system") return;
      final selected = emulators.value?.firstWhere((e) => e.system.id == system);
      if (selected == null || selected.emulators.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(0, selected.emulators.length - 1);
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(0, selected.emulators.length - 1);
      }
      if (key == GamepadButton.a) {
        final emulator = selected.emulators[selectedIndex.value.clamp(0, selected.emulators.length - 1)];
        ref
            .read(perSystemConfigurationRepoProvider)
            .saveAlternativeEmulator(system, emulator.id)
            .then((value) => ref.refresh(perSystemConfigurationsProvider));
        context.pop();
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Emulators for $system'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.a], "Select"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: emulators.when(
        data: (emulators) {
          final selected = emulators.firstWhere((e) => e.system.id == system);
          return GroupedListView<Emulator, String>(
            key: PageStorageKey("settings/emulators/$system"),
            elements: selected.emulators,
            groupBy: (element) => element.isCustom ? "Custom" : "Built-In",
            groupSeparatorBuilder: (String value) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                value,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            indexedItemBuilder: (context, emulator, index) {
              final isStandalone = emulator.isStandalone;
              final isCurrentDefault = selected.defaultEmulator?.id == emulator.id;
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
                      onTap: () {
                        selectedIndex.value = index;
                        ref
                            .read(perSystemConfigurationRepoProvider)
                            .saveAlternativeEmulator(system, emulator.id)
                            .then((value) => ref.refresh(perSystemConfigurationsProvider));
                        context.pop();
                      },
                      title: Text(
                        emulator.name,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      leading: isCurrentDefault ? Icon(Icons.star, color: isSelected ? Colors.black : Colors.amber) : null,
                      minLeadingWidth: 20,
                      trailing: isStandalone
                          ? Text(
                              "Standalone",
                              style: TextStyle(color: isSelected ? Colors.black87 : Colors.grey),
                            )
                          : null,
                    ),
                  ),
                ),
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
      ),
    );
  }
}
