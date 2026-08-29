part of 'package:titanius/pages/scraper.dart';

class ScraperSystemsPage extends HookConsumerWidget {
  const ScraperSystemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systems = ref.watch(loadedSystemsProvider);
    final settings = ref.watch(settingsProvider);
    final selectedIndex = usePersistentSelection('/settings/scraper/systems');

    useGamepad(ref, (location, key) {
      if (location != "/settings/scraper/systems") return;
      final sysList =
          systems.value
              ?.where((e) => !e.isCollection && !e.isAndroid)
              .toList() ??
          [];
      if (sysList.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          sysList.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          sysList.length - 1,
        );
      }
      if (key == GamepadButton.confirm) {
        final system =
            sysList[selectedIndex.value.clamp(0, sysList.length - 1)];
        final showSystem =
            settings.value?.scrapeTheseSystems.contains(system.id) ?? false;
        ref
            .read(settingsRepoProvider)
            .setScrapeTheseSystem(system.id, !showSystem)
            .then((value) {
              final _ = ref.refresh(settingsProvider);
            });
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).pop();
      }
      if (key == GamepadButton.x) {
        ref.read(settingsRepoProvider).setScrapeTheseSystems([]).then((value) {
          final _ = ref.refresh(settingsProvider);
        });
      }
      if (key == GamepadButton.y) {
        final all = sysList.map((e) => e.id).toList();
        ref.read(settingsRepoProvider).setScrapeTheseSystems(all).then((value) {
          final _ = ref.refresh(settingsProvider);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Scrape Systems')),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.x], "Select None"),
          GamepadPrompt([GamepadButton.y], "Select All"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.confirm], "Change"),
          GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: systems.when(
        data: (systems) {
          return settings.when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            data: (settings) {
              final sysList = systems
                  .where((e) => !e.isCollection && !e.isAndroid)
                  .toList();
              return ControllerGroupedListView<System, String>(
                key: const PageStorageKey("settings/scraper/systems"),
                selectedIndex: selectedIndex.value,
                elements: sysList,
                groupBy: (system) => "Systems",
                groupSeparatorBuilder: (String value) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                indexedItemBuilder: (context, system, index) {
                  final showSystem = settings.scrapeTheseSystems.contains(
                    system.id,
                  );
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
                                .read(settingsRepoProvider)
                                .setScrapeTheseSystem(
                                  system.id,
                                  showSystem ? false : true,
                                )
                                .then((value) {
                                  final _ = ref.refresh(settingsProvider);
                                });
                          },
                          title: Text(
                            system.name,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            "Folders: ${system.folders.join(", ")}",
                            style: TextStyle(
                              color: isSelected ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          trailing: showSystem ? toggleOnIcon : toggleOffIcon,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(child: Text('Error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Error')),
      ),
    );
  }
}
