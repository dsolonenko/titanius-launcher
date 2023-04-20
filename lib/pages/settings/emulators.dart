part of '../settings.dart';

class AlternativeEmulatorsSettingPage extends HookConsumerWidget {
  const AlternativeEmulatorsSettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulators = ref.watch(alternativeEmulatorsProvider);

    final selected = useState("");

    useGamepad(ref, (location, key) {
      if (location != "/settings/emulators") return;
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
                trailing: Text("${emulators[index].defaultEmulator!.name}${isStandalone ? " (Standalone)" : ""}"),
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
          return ListView.builder(
            itemCount: selected.system.emulators.length,
            itemBuilder: (context, index) {
              final isStandalone = selected.system.emulators[index].isStandalone;
              return ListTile(
                autofocus: index == 0,
                selected: selected.defaultEmulator?.id == selected.system.emulators[index].id,
                onTap: () {
                  ref
                      .read(perSystemConfigurationRepoProvider)
                      .value!
                      .saveAlternativeEmulator(
                          AlternativeEmulator(system: system, emulator: selected.system.emulators[index].id))
                      .then((value) => ref.refresh(perSystemConfigurationsProvider));
                  context.pop();
                },
                title: Text(selected.system.emulators[index].name),
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
