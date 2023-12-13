part of 'package:titanius/pages/settings.dart';

class CustomEmulatorsPage extends HookConsumerWidget {
  const CustomEmulatorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulators = ref.watch(customEmulatorsProvider);

    final selected = useState("");
    final confirm = useState(false);

    useGamepad(ref, (location, key) {
      if (location != "/settings/cemulators") return;
      if (confirm.value) {
        if (key == GamepadButton.b) {
          confirm.value = false;
        }
        if (key == GamepadButton.x) {
          ref.read(customEmulatorsRepoProvider).value!.deleteCustomEmulator(selected.value).then((value) {
            final _ = ref.refresh(customEmulatorsProvider);
          });
          confirm.value = false;
        }
      } else {
        if (key == GamepadButton.b) {
          GoRouter.of(context).pop();
        }
        if (key == GamepadButton.y) {
          ref.read(temporaryEmulatorProvider.notifier).reset();
          context.push("/settings/cemulators/edit");
        }
        if (key == GamepadButton.x) {
          confirm.value = true;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternative Emulators'),
      ),
      bottomNavigationBar: confirm.value
          ? const PromptBar(
              navigations: [],
              actions: [
                GamepadPrompt([GamepadButton.x], "Confirm Delete"),
                GamepadPrompt([GamepadButton.b], "Cancel"),
              ],
            )
          : const PromptBar(
              navigations: [],
              actions: [
                GamepadPrompt([GamepadButton.y], "Create"),
                GamepadPrompt([GamepadButton.x], "Delete"),
                GamepadPrompt([GamepadButton.a], "Edit"),
                GamepadPrompt([GamepadButton.b], "Back"),
              ],
            ),
      body: emulators.when(
        data: (emulators) {
          return ListView.builder(
            key: const PageStorageKey("settings/cemulators"),
            itemCount: emulators.length,
            itemBuilder: (context, index) {
              final emulator = emulators[index];
              final isSelected = selected.value == emulator.name || (selected.value.isEmpty && index == 0);
              return ListTile(
                autofocus: isSelected,
                onFocusChange: (value) {
                  if (value) {
                    selected.value = emulator.name;
                  }
                },
                onTap: () {
                  ref.read(temporaryEmulatorProvider.notifier).set(emulator);
                  context.push("/settings/cemulators/edit");
                },
                title: Text(emulator.name),
                subtitle: Text(emulator.amStartCommand, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: isSelected && confirm.value ? const Text("Delete?") : null,
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

class EditCustomEmulatorPage extends HookConsumerWidget {
  const EditCustomEmulatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulator = ref.watch(temporaryEmulatorProvider);

    final selected = useState("name");
    final inPrompt = useState(false);

    useGamepad(ref, (location, key) {
      if (inPrompt.value) {
        return;
      }
      if (location != "/settings/cemulators/edit") return;
      if (key == GamepadButton.y) {
        ref.read(customEmulatorsRepoProvider).value!.saveCustomEmulator(emulator).then((value) {
          final _ = ref.refresh(customEmulatorsProvider);
          GoRouter.of(context).pop();
        });
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Emulator'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.y], "Save"),
          GamepadPrompt([GamepadButton.b], "Cancel"),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            autofocus: selected.value == "" || selected.value == "name",
            title: const Text("Name"),
            subtitle: Text(emulator.name),
            onFocusChange: (value) {
              if (value) {
                selected.value = "name";
              }
            },
            onTap: () async {
              inPrompt.value = true;
              try {
                final v = await prompt(
                  context,
                  title: const Text("Name"),
                  initialValue: emulator.name,
                  isSelectedInitialValue: true,
                  decoration: const InputDecoration(
                    helperText: "Unique name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (s) {
                    if (s == null || s.isEmpty) {
                      return "Name cannot be empty";
                    }
                    return null;
                  },
                );
                if (v != null) {
                  emulator.name = v;
                  ref.read(temporaryEmulatorProvider.notifier).set(emulator);
                }
              } finally {
                inPrompt.value = false;
              }
            },
          ),
          ListTile(
            autofocus: selected.value == "command",
            title: const Text("Command"),
            subtitle: Text(emulator.amStartCommand),
            onFocusChange: (value) {
              if (value) {
                selected.value = "command";
              }
            },
            onTap: () async {
              inPrompt.value = true;
              try {
                final v = await prompt(
                  context,
                  title: const Text("Command"),
                  initialValue: emulator.amStartCommand,
                  isSelectedInitialValue: true,
                  decoration: const InputDecoration(
                    helperText: "am start command line",
                    border: OutlineInputBorder(),
                  ),
                  validator: (s) {
                    if (s == null || s.isEmpty) {
                      return "Cannot be empty";
                    }
                    return null;
                  },
                );
                if (v != null) {
                  emulator.amStartCommand = v.replaceAll("\n", ' ');
                  ref.read(temporaryEmulatorProvider.notifier).set(emulator);
                }
              } finally {
                inPrompt.value = false;
              }
            },
          ),
        ],
      ),
    );
  }
}
