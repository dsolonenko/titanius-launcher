part of 'package:titanius/pages/settings.dart';

class RomsSettingsPage extends HookConsumerWidget {
  const RomsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final romFolders = ref.watch(romFoldersProvider);
    final paths = ref.watch(externalRomsPathsProvider);
    final grantedUris = ref.watch(grantedUrisProvider);

    final removing = useState(false);
    final selectedIndex = useState(0);

    useGamepad(ref, (location, key) {
      if (location != "/settings/roms") return;
      final allPaths = [...(paths.value ?? []), ...(grantedUris.value ?? [])];
      if (allPaths.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(0, allPaths.length - 1);
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(0, allPaths.length - 1);
      }
      if (key == GamepadButton.a) {
        final e = allPaths[selectedIndex.value.clamp(0, allPaths.length - 1)];
        if (e is GrantedUri) {
          if (removing.value) {
            removing.value = false;
            SafUtil()
                .releasePersistedPermission(e.uri.toString())
                .then((value) => ref.refresh(grantedUrisProvider));
          } else {
            removing.value = true;
          }
        } else {
          final pList = romFolders.value ?? [];
          final included = pList.contains(e as String);
          final newPaths = List<String>.from(pList);
          if (included) {
            newPaths.remove(e);
          } else {
            newPaths.add(e);
          }
          ref
              .read(romFoldersRepoProvider)
              .saveRomsFolders(newPaths)
              .then((value) => ref.refresh(romFoldersProvider));
        }
      }
      if (key == GamepadButton.b) {
        if (removing.value) {
          removing.value = false;
        } else {
          GoRouter.of(context).pop();
        }
      }
      if (key == GamepadButton.y) {
        SafUtil().pickDirectory().then((docFile) {
          if (docFile != null) {
            final _ = ref.refresh(grantedUrisProvider);
          }
        });
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
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (romFolders) {
          return paths.when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            data: (paths) {
              return grantedUris.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
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
                      final isSelected = index == selectedIndex.value;
                      if (e is GrantedUri) {
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
                                  if (removing.value) {
                                    removing.value = false;
                                    SafUtil()
                                        .releasePersistedPermission(e.uri.toString())
                                        .then((value) => ref.refresh(grantedUrisProvider));
                                  } else {
                                    removing.value = true;
                                  }
                                },
                                title: Text(
                                  e.grantedFullPath,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  Uri.decodeComponent(e.uri.path),
                                  style: TextStyle(
                                    color: isSelected ? Colors.black87 : Colors.grey,
                                  ),
                                ),
                                trailing: isSelected && removing.value
                                    ? const GamepadPromptWidget(buttons: [GamepadButton.a], prompt: "Confirm?")
                                    : Icon(Icons.delete_rounded, color: isSelected ? Colors.black : Colors.white),
                              ),
                            ),
                          ),
                        );
                      } else {
                        final included = romFolders.contains(e as String);
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
                                  final newPaths = List<String>.from(romFolders);
                                  if (included) {
                                    newPaths.remove(e);
                                  } else {
                                    newPaths.add(e);
                                  }
                                  ref
                                      .read(romFoldersRepoProvider)
                                      .saveRomsFolders(newPaths)
                                      .then((value) => ref.refresh(romFoldersProvider));
                                },
                                title: Text(
                                e,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: included ? toggleOnIcon : toggleOffIcon,
                            ),
                          ),
                        ),
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
