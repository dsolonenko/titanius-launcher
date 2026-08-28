part of 'package:titanius/pages/settings.dart';

class CustomEmulatorsPage extends HookConsumerWidget {
  const CustomEmulatorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulators = ref.watch(customEmulatorsProvider);
    final selectedIndex = usePersistentSelection('/settings/cemulators');
    final confirm = useState(false);

    useGamepad(ref, (location, key) {
      if (location != "/settings/cemulators") return;
      final emuList = emulators.value ?? [];

      if (confirm.value) {
        if (key == GamepadButton.b) {
          confirm.value = false;
        }
        if (key == GamepadButton.x) {
          if (emuList.isNotEmpty) {
            final emulator =
                emuList[selectedIndex.value.clamp(0, emuList.length - 1)];
            ref
                .read(customEmulatorsRepoProvider)
                .deleteCustomEmulator(emulator.name)
                .then((value) {
                  final _ = ref.refresh(customEmulatorsProvider);
                });
          }
          confirm.value = false;
        }
      } else {
        if (key == GamepadButton.up) {
          if (emuList.isNotEmpty) {
            selectedIndex.value = (selectedIndex.value - 1).clamp(
              0,
              emuList.length - 1,
            );
          }
        }
        if (key == GamepadButton.down) {
          if (emuList.isNotEmpty) {
            selectedIndex.value = (selectedIndex.value + 1).clamp(
              0,
              emuList.length - 1,
            );
          }
        }
        if (key == GamepadButton.a) {
          if (emuList.isNotEmpty) {
            final emulator =
                emuList[selectedIndex.value.clamp(0, emuList.length - 1)];
            ref.read(temporaryEmulatorProvider.notifier).set(emulator);
            context.push("/settings/cemulators/edit");
          }
        }
        if (key == GamepadButton.b) {
          GoRouter.of(context).pop();
        }
        if (key == GamepadButton.y) {
          ref.read(temporaryEmulatorProvider.notifier).reset();
          context.push("/settings/cemulators/edit");
        }
        if (key == GamepadButton.x) {
          if (emuList.isNotEmpty) {
            confirm.value = true;
          }
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Emulators')),
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
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (emulators) {
          return ControllerListView.builder(
            key: const PageStorageKey("settings/cemulators"),
            selectedIndex: selectedIndex.value,
            itemCount: emulators.length,
            itemBuilder: (context, index) {
              final emulator = emulators[index];
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
                            .read(temporaryEmulatorProvider.notifier)
                            .set(emulator);
                        context.push("/settings/cemulators/edit");
                      },
                      title: Text(
                        emulator.name,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        emulator.amStartCommand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      trailing: isSelected && confirm.value
                          ? const Text(
                              "Delete?",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
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

class EditCustomEmulatorPage extends HookConsumerWidget {
  const EditCustomEmulatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulator = ref.watch(temporaryEmulatorProvider);
    final selectedIndex = usePersistentSelection('/settings/cemulators/edit');
    final inPrompt = useState(false);

    Future<void> editName() async {
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
          final updated = emulator.copyWith(name: v);
          ref.read(temporaryEmulatorProvider.notifier).set(updated);
        }
      } finally {
        inPrompt.value = false;
      }
    }

    Future<void> editCommand() async {
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
          final updated = emulator.copyWith(
            amStartCommand: v.replaceAll("\n", ' '),
          );
          ref.read(temporaryEmulatorProvider.notifier).set(updated);
        }
      } finally {
        inPrompt.value = false;
      }
    }

    useGamepad(ref, (location, key) {
      if (inPrompt.value) {
        return;
      }
      if (location != "/settings/cemulators/edit") return;
      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(0, 1);
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(0, 1);
      }
      if (key == GamepadButton.a) {
        if (selectedIndex.value == 0) {
          editName();
        } else {
          editCommand();
        }
      }
      if (key == GamepadButton.y) {
        ref.read(customEmulatorsRepoProvider).saveCustomEmulator(emulator).then(
          (value) {
            final _ = ref.refresh(customEmulatorsProvider);
            if (context.mounted) {
              GoRouter.of(context).pop();
            }
          },
        );
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    final fields = [
      (title: "Name", subtitle: emulator.name, onEdit: editName),
      (
        title: "Command",
        subtitle: emulator.amStartCommand,
        onEdit: editCommand,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Emulator')),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.a], "Edit"),
          GamepadPrompt([GamepadButton.y], "Save"),
          GamepadPrompt([GamepadButton.b], "Cancel"),
        ],
      ),
      body: ControllerListView.builder(
        selectedIndex: selectedIndex.value,
        itemCount: fields.length,
        itemBuilder: (context, index) {
          final field = fields[index];
          final isSelected = index == selectedIndex.value;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Material(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              child: ListTile(
                selected: isSelected,
                selectedColor: Colors.black,
                selectedTileColor: Colors.transparent,
                dense: true,
                title: Text(
                  field.title,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  field.subtitle,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.grey,
                  ),
                ),
                onTap: () {
                  selectedIndex.value = index;
                  field.onEdit();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
