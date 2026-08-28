part of 'package:titanius/pages/settings.dart';

class AppsSettingsPage extends HookConsumerWidget {
  const AppsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedApps = ref.watch(installedAppsProvider);
    final selectedApps = ref.watch(androidAppsProvider);
    final selectedIndex = useState(0);

    useGamepad(ref, (location, key) {
      if (location != "/select_apps") return;
      final appsList = installedApps.value ?? [];
      if (appsList.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(0, appsList.length - 1);
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(0, appsList.length - 1);
      }
      if (key == GamepadButton.a) {
        final app = appsList[selectedIndex.value.clamp(0, appsList.length - 1)];
        final isSelected = selectedApps.value?.isSelected(app.packageName) ?? false;
        ref
            .read(androidAppsRepoProvider)
            .selectApp(app.packageName, !isSelected)
            .then((value) => ref.refresh(androidAppsProvider));
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/games/android");
      }
      if (key == GamepadButton.y) {
        final _ = ref.refresh(installedAppsProvider);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selected Apps'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.y], "Refresh"),
          GamepadPrompt([GamepadButton.a], "Change"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: installedApps.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (installedApps) {
          return selectedApps.when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            data: (selectedApps) {
              return GroupedListView<AppInfo, String>(
                key: const PageStorageKey("settings/apps"),
                elements: installedApps,
                groupBy: (element) => "Apps",
                groupSeparatorBuilder: (String value) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                indexedItemBuilder: (context, app, index) {
                  final isAppSelected = selectedApps.isSelected(app.packageName);
                  final isSelected = index == selectedIndex.value;
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
                            ref
                                .read(androidAppsRepoProvider)
                                .selectApp(app.packageName, !isAppSelected)
                                .then((value) => ref.refresh(androidAppsProvider));
                          },
                          title: Text(
                            app.name,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            app.packageName,
                            style: TextStyle(
                              color: isSelected ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          leading: app.icon != null
                              ? CachedMemoryImage(
                                  uniqueKey: app.packageName,
                                  bytes: app.icon!,
                                  fit: BoxFit.contain,
                                )
                              : Icon(Icons.android, color: isSelected ? Colors.black : Colors.white),
                          trailing: isAppSelected ? toggleOnIcon : toggleOffIcon,
                        ),
                      ),
                    ),
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
