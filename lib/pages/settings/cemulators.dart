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
                subtitle: Text("${emulator.package}/${emulator.activity}"),
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
      if (key == GamepadButton.x) {
        switch (selected.value) {
          case "name":
            emulator.name = CustomEmulator.empty().name;
            break;
          case "package":
            emulator.package = CustomEmulator.empty().package;
            break;
          case "activity":
            emulator.activity = CustomEmulator.empty().activity;
            break;
          case "action":
            emulator.action = CustomEmulator.empty().action;
            break;
          case "data":
            emulator.data = CustomEmulator.empty().data;
            break;
          case "args":
            emulator.args = CustomEmulator.empty().args;
            break;
          case "flags":
            emulator.flags = CustomEmulator.empty().flags;
            break;
          default:
        }
        ref.read(temporaryEmulatorProvider.notifier).set(emulator);
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
          GamepadPrompt([GamepadButton.x], "Default"),
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
            autofocus: selected.value == "package",
            title: const Text("Package"),
            subtitle: Text(emulator.package),
            onFocusChange: (value) {
              if (value) {
                selected.value = "package";
              }
            },
            onTap: () async {
              inPrompt.value = true;
              try {
                final v = await prompt(
                  context,
                  title: const Text("Package"),
                  initialValue: emulator.package,
                  isSelectedInitialValue: true,
                  decoration: const InputDecoration(
                    helperText: "com.ppsspp.ppsspp",
                    border: OutlineInputBorder(),
                  ),
                  validator: (s) {
                    if (s == null || s.isEmpty) {
                      return "Package cannot be empty";
                    }
                    return null;
                  },
                );
                if (v != null) {
                  emulator.package = v;
                  ref.read(temporaryEmulatorProvider.notifier).set(emulator);
                }
              } finally {
                inPrompt.value = false;
              }
            },
          ),
          ListTile(
            autofocus: selected.value == "activity",
            title: const Text("Activity"),
            subtitle: Text(emulator.activity),
            onFocusChange: (value) {
              if (value) {
                selected.value = "activity";
              }
            },
            onTap: () async {
              inPrompt.value = true;
              try {
                final v = await prompt(
                  context,
                  title: const Text("Activity"),
                  initialValue: emulator.activity,
                  isSelectedInitialValue: true,
                  decoration: const InputDecoration(
                    helperText: ".PpssppActivity",
                    border: OutlineInputBorder(),
                  ),
                  validator: (s) {
                    if (s == null || s.isEmpty) {
                      return "Activity cannot be empty";
                    }
                    return null;
                  },
                );
                if (v != null) {
                  emulator.activity = v;
                  ref.read(temporaryEmulatorProvider.notifier).set(emulator);
                }
              } finally {
                inPrompt.value = false;
              }
            },
          ),
          ListTile(
            autofocus: selected.value == "action",
            title: const Text("Action"),
            subtitle: Text(emulator.action),
            onFocusChange: (value) {
              if (value) {
                selected.value = "action";
              }
            },
            onTap: () async {
              inPrompt.value = true;
              try {
                final v = await prompt(
                  context,
                  title: const Text("Action"),
                  initialValue: emulator.action,
                  isSelectedInitialValue: true,
                  decoration: const InputDecoration(
                    helperText: "android.intent.action.VIEW",
                    border: OutlineInputBorder(),
                  ),
                  validator: (s) {
                    if (s == null || s.isEmpty) {
                      return "Action cannot be empty";
                    }
                    return null;
                  },
                );
                if (v != null) {
                  emulator.action = v;
                  ref.read(temporaryEmulatorProvider.notifier).set(emulator);
                }
              } finally {
                inPrompt.value = false;
              }
            },
          ),
          ListTile(
            autofocus: selected.value == "data",
            title: const Text("Data"),
            subtitle: Text(emulator.data),
            onFocusChange: (value) {
              if (value) {
                selected.value = "data";
              }
            },
            onTap: () async {
              inPrompt.value = true;
              try {
                final v = await prompt(
                  context,
                  title: const Text("Data"),
                  initialValue: emulator.data,
                  isSelectedInitialValue: true,
                  decoration: const InputDecoration(
                    helperText: "{file.documenturi} or {file.path}",
                    border: OutlineInputBorder(),
                  ),
                );
                if (v != null) {
                  emulator.data = v;
                  ref.read(temporaryEmulatorProvider.notifier).set(emulator);
                }
              } finally {
                inPrompt.value = false;
              }
            },
          ),
          ListTile(
            autofocus: selected.value == "args",
            title: const Text("Args"),
            subtitle: Text(emulator.args.join(" ")),
            onFocusChange: (value) {
              if (value) {
                selected.value = "args";
              }
            },
            onTap: () async {
              inPrompt.value = true;
              try {
                final v = await prompt(
                  context,
                  title: const Text("Args"),
                  initialValue: emulator.args.join(" "),
                  isSelectedInitialValue: true,
                  decoration: const InputDecoration(
                    helperText: "ROM={file.path} CONFIGFILE=/config.cfg",
                    border: OutlineInputBorder(),
                  ),
                );
                if (v != null) {
                  emulator.args = v.isEmpty ? [] : v.split(" ");
                  ref.read(temporaryEmulatorProvider.notifier).set(emulator);
                }
              } finally {
                inPrompt.value = false;
              }
            },
          ),
          ListTile(
            autofocus: selected.value == "flags",
            title: const Text("Flags"),
            subtitle: Text(emulator.flags.join(" ")),
            onFocusChange: (value) {
              if (value) {
                selected.value = "flags";
              }
            },
            onTap: () async {
              inPrompt.value = true;
              try {
                final v = await prompt(
                  context,
                  title: const Text("Flags"),
                  initialValue: emulator.flags.join(" "),
                  isSelectedInitialValue: true,
                  decoration: const InputDecoration(
                    helperText: "--activity-clear-task --activity-clear-top",
                    border: OutlineInputBorder(),
                  ),
                );
                if (v != null) {
                  emulator.flags = v.isEmpty ? [] : v.split(" ");
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
