part of '../settings.dart';

class AlternativeEmulatorsSettingPage extends HookConsumerWidget {
  const AlternativeEmulatorsSettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulators = ref.watch(alternativeEmulatorsProvider);

    useGamepad(ref, (location, key) {
      if (location != "/settings/emulators") return;
      if (key == GamepadButton.b) {
        print("Alternative emulators pop at ${GoRouter.of(context).location}");
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternative Emulators'),
      ),
      body: emulators.when(
        data: (emulators) {
          return ListView.builder(
            itemCount: emulators.length,
            itemBuilder: (context, index) {
              return ListTile(
                autofocus: index == 0,
                onTap: () {
                  context.push(
                      "/settings/emulators/${emulators[index].system.id}");
                },
                title: Text(emulators[index].system.name),
                trailing: Text(emulators[index].defaultEmulator.name),
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
        print(
            "Alternative emulators for $system pop at ${GoRouter.of(context).location}");
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
              return ListTile(
                autofocus: index == 0,
                onTap: () {
                  ref
                      .read(settingsRepoProvider)
                      .value!
                      .saveAlternativeEmulator(AlternativeEmulator(
                          system: system,
                          emulator: selected.system.emulators[index].id))
                      .then((value) => ref.refresh(settingsProvider));
                  context.pop();
                },
                title: Text(selected.system.emulators[index].name),
                trailing: index == 0 ? const Icon(Icons.star) : null,
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
