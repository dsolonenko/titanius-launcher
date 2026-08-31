part of 'package:titanius/pages/scraper.dart';

class ScraperSystemsPage extends HookConsumerWidget {
  const ScraperSystemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systems = ref.watch(loadedSystemsProvider);
    final selectionReady = ref.watch(
      scrapeTheseSystemsProvider.select((selection) => selection.hasValue),
    );
    final selectedIndex = usePersistentSelection('/settings/scraper/systems');

    void toggleSystem(String id) {
      final current = ref.read(scrapeTheseSystemsProvider).value ?? const {};
      ref.read(scrapeTheseSystemsWriterProvider).toggle(current, id);
    }

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
        toggleSystem(system.id);
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).pop();
      }
      if (key == GamepadButton.x) {
        ref.read(scrapeTheseSystemsWriterProvider).replace(const []);
      }
      if (key == GamepadButton.y) {
        final all = sysList.map((e) => e.id).toList();
        ref.read(scrapeTheseSystemsWriterProvider).replace(all);
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
          if (!selectionReady) {
            return const Center(child: CircularProgressIndicator());
          }
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
              child: Text(value, style: const TextStyle(color: Colors.grey)),
            ),
            indexedItemBuilder: (context, system, index) {
              final isSelected = index == selectedIndex.value;
              return Consumer(
                builder: (context, ref, _) {
                  final showSystem = ref.watch(
                    scrapeTheseSystemsProvider.select(
                      (selection) =>
                          selection.value?.contains(system.id) ?? false,
                    ),
                  );
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
                            toggleSystem(system.id);
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Error')),
      ),
    );
  }
}
