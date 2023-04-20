part of '../settings.dart';

class RomsSettingsPage extends HookConsumerWidget {
  const RomsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grantedUris = ref.watch(grantedUrisProvider);

    final removing = useState(false);
    final selected = useState<GrantedUri?>(null);

    useGamepad(ref, (location, key) {
      if (location != "/settings/roms") return;
      if (key == GamepadButton.b) {
        if (removing.value) {
          removing.value = false;
        } else {
          GoRouter.of(context).pop();
        }
      }
      if (key == GamepadButton.x) {
        saf.openDocumentTree().then((value) => ref.refresh(grantedUrisProvider));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.x], "Add Folder"),
          GamepadPrompt([GamepadButton.a], "Remove"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: grantedUris.when(
        data: (grantedUris) {
          if (grantedUris == null || grantedUris.isEmpty) {
            return const Center(
              child: Text("No folders added"),
            );
          }
          return ListView.builder(
            key: const PageStorageKey("settings/systems"),
            itemCount: grantedUris.length,
            itemBuilder: (context, index) {
              return ListTile(
                autofocus: index == 0,
                onFocusChange: (value) {
                  removing.value = false;
                  if (value) {
                    selected.value = grantedUris[index];
                  }
                },
                onTap: () {
                  if (!removing.value) {
                    removing.value = true;
                  } else {
                    removing.value = false;
                    saf
                        .releasePersistableUriPermission(selected.value!.uri)
                        .then((value) => ref.refresh(grantedUrisProvider));
                  }
                },
                title: Text(grantedUris[index].grantedFullPath),
                subtitle: Text(Uri.decodeComponent(grantedUris[index].uri.path)),
                trailing: removing.value
                    ? selected.value == grantedUris[index]
                        ? const GamepadPromptWidget(
                            buttons: [GamepadButton.a],
                            prompt: "Confirm to remove",
                          )
                        : null
                    : const Icon(Icons.delete_rounded),
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
