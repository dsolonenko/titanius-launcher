part of 'package:titanius/pages/settings.dart';

class AlternativeEmulatorsSettingPage extends HookConsumerWidget {
  const AlternativeEmulatorsSettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulators = ref.watch(alternativeEmulatorsProvider);

    final selected = useState("");

    useGamepad(ref, (location, key) {
      if (location != "/settings/emulators") return;
      if (key == GamepadButton.x) {
        ref
            .read(perSystemConfigurationRepoProvider)
            .value!
            .deleteAlternativeEmulator(selected.value)
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
          emulators = emulators.where((element) => element.defaultEmulator != null).toList();
          return ListView.builder(
            key: const PageStorageKey("settings/emulators"),
            itemCount: emulators.length,
            itemBuilder: (context, index) {
              final isStandalone = emulators[index].defaultEmulator!.isStandalone;
              final isCustom = emulators[index].defaultEmulator!.isCustom;
              return ListTile(
                autofocus: selected.value == emulators[index].system.id || (selected.value.isEmpty && index == 0),
                onFocusChange: (value) {
                  if (value) {
                    selected.value = emulators[index].system.id;
                  }
                },
                onTap: () {
                  context.push("/settings/emulators/${emulators[index].system.id}");
                },
                title: Text(emulators[index].system.name),
                trailing: Text(
                    "${emulators[index].defaultEmulator!.name}${isCustom ? " (Custom)" : isStandalone ? " (Standalone)" : ""}"),
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

    useGamepad(ref, (location, key) {
      if (location != "/settings/emulators/$system") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Emulators for $system'),
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
              return ListTile(
                autofocus: index == 0,
                selected: selected.defaultEmulator?.id == emulator.id,
                onTap: () {
                  ref
                      .read(perSystemConfigurationRepoProvider)
                      .value!
                      .saveAlternativeEmulator(system, emulator.id)
                      .then((value) => ref.refresh(perSystemConfigurationsProvider));
                  context.pop();
                },
                title: Text(emulator.name),
                leading: index == 0 ? const Icon(Icons.star) : null,
                minLeadingWidth: 20,
                trailing: isStandalone ? const Text("Standalone") : null,
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
