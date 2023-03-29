part of '../settings.dart';

class RomsSettingsPage extends HookConsumerWidget {
  const RomsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
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
      body: settings.when(
        data: (settings) {
          return paths.when(
            data: (paths) {
              return ListView.builder(
                itemCount: paths.length,
                itemBuilder: (context, index) {
                  final included = settings.romsFolders.contains(paths[index]);
                  return ListTile(
                    autofocus: index == 0,
                    onTap: () {
                      final newPaths = settings.romsFolders;
                      if (included) {
                        newPaths.remove(paths[index]);
                      } else {
                        newPaths.add(paths[index]);
                      }
                      ref
                          .read(settingsRepoProvider)
                          .value!
                          .saveRomsFolders(newPaths)
                          .then((value) => ref.refresh(settingsProvider));
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
