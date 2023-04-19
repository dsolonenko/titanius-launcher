part of '../settings.dart';

class RomsSettingsPage extends HookConsumerWidget {
  const RomsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final romFolders = ref.watch(romFoldersProvider);
    final paths = ref.watch(externalRomsPathsProvider);
    final grantedUris = ref.watch(grantedUrisProvider);

    useGamepad(ref, (location, key) {
      if (location != "/settings/roms") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
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
          GamepadPrompt([GamepadButton.x], "Allow Access"),
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
                  final allPaths = grantedUris != null ? [...paths, ...grantedUris] : paths;
                  return GroupedListView<Object, String>(
                    key: const PageStorageKey("settings/systems"),
                    elements: allPaths,
                    groupBy: (element) => element is GrantedUri ? "Granted Paths" : "ROM Folders",
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
                          enabled: false,
                          title: Text(e.uri.path),
                          subtitle: Text(e.grantedFullPath),
                        );
                      } else {
                        final included = romFolders.contains(paths[index]);
                        return ListTile(
                          autofocus: index == 0,
                          onTap: () {
                            final newPaths = romFolders;
                            if (included) {
                              newPaths.remove(paths[index]);
                            } else {
                              newPaths.add(paths[index]);
                            }
                            ref
                                .read(romFoldersRepoProvider)
                                .value!
                                .saveRomsFolders(newPaths)
                                .then((value) => ref.refresh(romFoldersProvider));
                          },
                          title: Text(paths[index]),
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
