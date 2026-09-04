part of 'package:titanius/pages/settings.dart';

class AppsSettingsPage extends HookConsumerWidget {
  const AppsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedApps = ref.watch(installedAppsProvider);
    final selectionReady = ref.watch(
      androidAppsChangesProvider.select((selection) => selection.hasValue),
    );
    final selectedIndex = usePersistentSelection('/settings/apps');

    useGamepad(ref, (location, key) {
      if (location != "/select_apps") return;
      final appsList = installedApps.value ?? [];
      if (appsList.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          appsList.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          appsList.length - 1,
        );
      }
      if (key == GamepadButton.left) {
        final app = appsList[selectedIndex.value.clamp(0, appsList.length - 1)];
        ref
            .read(androidAppsRepoProvider)
            .cycleAppType(app.packageName, forward: false);
      }
      if (key == GamepadButton.right) {
        final app = appsList[selectedIndex.value.clamp(0, appsList.length - 1)];
        ref
            .read(androidAppsRepoProvider)
            .cycleAppType(app.packageName, forward: true);
      }
      if (key == GamepadButton.confirm) {
        final app = appsList[selectedIndex.value.clamp(0, appsList.length - 1)];
        ref
            .read(androidAppsRepoProvider)
            .cycleAppType(app.packageName, forward: true);
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).go("/games/android");
      }
      if (key == GamepadButton.y) {
        final _ = ref.refresh(installedAppsProvider);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Selected Apps')),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.leftRight], "Select"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.y], "Refresh"),
          GamepadPrompt([GamepadButton.confirm], "Change"),
          GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: installedApps.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (installedApps) {
          if (!selectionReady) {
            return const Center(child: CircularProgressIndicator());
          }
          return ControllerGroupedListView<AppInfo, String>(
            key: const PageStorageKey("settings/apps"),
            selectedIndex: selectedIndex.value,
            elements: installedApps,
            groupBy: (element) => "Apps",
            groupSeparatorBuilder: (String value) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(value, style: const TextStyle(color: Colors.grey)),
            ),
            indexedItemBuilder: (context, app, index) {
              final isSelected = index == selectedIndex.value;
              return Consumer(
                builder: (context, ref, _) {
                  final appType = ref.watch(
                    androidAppsChangesProvider.select(
                      (selection) =>
                          selection.value?.typeOf(app.packageName) ??
                          AndroidAppType.hidden,
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
                            ref
                                .read(androidAppsRepoProvider)
                                .cycleAppType(app.packageName);
                          },
                          title: Text(
                            app.name,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            app.packageName,
                            style: TextStyle(
                              color: isSelected ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          leading: app.icon != null
                              ? Image.memory(
                                  app.icon!,
                                  gaplessPlayback: true,
                                  fit: BoxFit.contain,
                                  width: 36,
                                  height: 36,
                                  filterQuality: FilterQuality.medium,
                                )
                              : Icon(
                                  Icons.android,
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                ),
                          trailing: SelectorWidget(text: appType.label),
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
