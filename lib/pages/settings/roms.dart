part of '../settings.dart';

class RomsSettingsPage extends HookConsumerWidget {
  const RomsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final romFolders = ref.watch(romFoldersProvider);
    final paths = ref.watch(externalRomsPathsProvider);

    useGamepad(ref, (location, key) {
      if (location != "/settings/roms") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ROMs Folders'),
      ),
      body: romFolders.when(
        data: (romFolders) {
          return paths.when(
            data: (paths) {
              return ListView.builder(
                key: const PageStorageKey("settings/roms"),
                itemCount: paths.length,
                itemBuilder: (context, index) {
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
      ),
    );
  }
}
