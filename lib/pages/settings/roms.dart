part of '../settings.dart';

class RomsSettingsPage extends HookConsumerWidget {
  const RomsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final romFolders = ref.watch(romFoldersProvider);
    final paths = ref.watch(externalRomsPathsProvider);
    final grantedUris = ref.watch(grantedUrisProvider);

    final removing = useState(false);
    final selected = useState<Object?>(null);

    useGamepad(ref, (location, key) {
      if (location != "/settings/roms") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
      if (key == GamepadButton.y) {
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
          GamepadPrompt([GamepadButton.y], "Add Shared Folder"),
          GamepadPrompt([GamepadButton.a], "Change"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: romFolders.when(
        data: (romFolders) {
          return paths.when(
            data: (paths) {
              return grantedUris.when(
                data: (grantedUris) {
                  final allPaths = [...paths, ...grantedUris];
                  return GroupedListView<Object, String>(
                    key: const PageStorageKey("settings/systems"),
                    elements: allPaths,
                    groupBy: (element) => element is GrantedUri ? "Shared Folders" : "ROM Folders",
                    groupSeparatorBuilder: (String value) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    indexedItemBuilder: (context, e, index) {
                      if (e is GrantedUri) {
                        return ListTile(
                          autofocus: (index == 0 && selected.value == null) || selected.value == e,
                          onFocusChange: (value) {
                            if (value) {
                              selected.value = e;
                            }
                          },
                          onTap: () {
                            if (removing.value) {
                              removing.value = false;
                              saf
                                  .releasePersistableUriPermission(e.uri)
                                  .then((value) => ref.refresh(grantedUrisProvider));
                            } else {
                              removing.value = true;
                            }
                          },
                          title: Text(e.grantedFullPath),
                          subtitle: Text(Uri.decodeComponent(e.uri.path)),
                          trailing: removing.value
                              ? const GamepadPromptWidget(buttons: [GamepadButton.a], prompt: "Confirm?")
                              : const Icon(Icons.delete_rounded),
                        );
                      } else {
                        final included = romFolders.contains(paths[index]);
                        return ListTile(
                          autofocus: (index == 0 && selected.value == null) || selected.value == e,
                          onFocusChange: (value) {
                            if (value) {
                              selected.value = e;
                            }
                          },
                          onTap: () {
                            final newPaths = romFolders;
                            if (included) {
                              newPaths.remove(allPaths[index]);
                            } else {
                              newPaths.add(allPaths[index] as String);
                            }
                            ref
                                .read(romFoldersRepoProvider)
                                .value!
                                .saveRomsFolders(newPaths)
                                .then((value) => ref.refresh(romFoldersProvider));
                          },
                          title: Text(allPaths[index] as String),
                          trailing: included ? toggleOnIcon : toggleOffIcon,
                        );
                      }
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => const Center(
                  child: Text('Error'),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => const Center(
              child: Text('Error'),
            ),
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
