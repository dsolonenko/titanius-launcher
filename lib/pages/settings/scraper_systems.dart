part of 'package:titanius/pages/scraper.dart';

class ScraperSystemsPage extends HookConsumerWidget {
  const ScraperSystemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systems = ref.watch(loadedSystemsProvider);
    final settings = ref.watch(settingsProvider);

    final selected = useState("");

    useGamepad(ref, (location, key) {
      if (location != "/settings/scraper/systems") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
      if (key == GamepadButton.x) {
        ref.read(settingsRepoProvider).value!.setScrapeTheseSystems([]).then((value) {
          final _ = ref.refresh(settingsProvider);
        });
      }
      if (key == GamepadButton.y) {
        final all = systems.value!.where((element) => !element.isCollection).map((e) => e.id).toList();
        ref.read(settingsRepoProvider).value!.setScrapeTheseSystems(all).then((value) {
          final _ = ref.refresh(settingsProvider);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrape Systems'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.x], "Select None"),
          GamepadPrompt([GamepadButton.y], "Select All"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.a], "Change"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: systems.when(
        data: (systems) {
          return settings.when(
            data: (settings) {
              return GroupedListView<System, String>(
                key: const PageStorageKey("settings/scraper/systems"),
                elements: systems.where((e) => !e.isCollection && !e.isAndroid).toList(),
                groupBy: (system) {
                  return "Systems";
                },
                groupSeparatorBuilder: (String value) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                indexedItemBuilder: (context, system, index) {
                  final showSystem = settings.scrapeTheseSystems.contains(system.id);
                  return ListTile(
                    autofocus: selected.value == system.id || (selected.value.isEmpty && index == 0),
                    onFocusChange: (value) {
                      if (value) {
                        selected.value = system.id;
                      }
                    },
                    onTap: () {
                      ref
                          .read(settingsRepoProvider)
                          .value!
                          .setScrapeTheseSystem(system.id, showSystem ? false : true)
                          .then((value) {
                        final _ = ref.refresh(settingsProvider);
                      });
                    },
                    title: Text(system.name),
                    subtitle: Text("Folders: ${system.folders.join(", ")}"),
                    trailing: showSystem ? toggleOnIcon : toggleOffIcon,
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
