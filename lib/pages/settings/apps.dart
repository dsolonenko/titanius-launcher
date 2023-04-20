part of '../settings.dart';

class AppsSettingsPage extends HookConsumerWidget {
  const AppsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedApps = ref.watch(installedAppsProvider);
    final selectedApps = ref.watch(androidAppsProvider);

    useGamepad(ref, (location, key) {
      if (location != "/select_apps") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selected Apps'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.a], "Change"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: installedApps.when(
        data: (installedApps) {
          return selectedApps.when(
            data: (selectedApps) {
              return GroupedListView<ApplicationWithIcon, String>(
                key: const PageStorageKey("settings/apps"),
                elements: installedApps,
                groupBy: (element) => element.systemApp ? "System" : "Apps",
                groupSeparatorBuilder: (String value) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                indexedItemBuilder: (context, app, index) {
                  final isSelected = selectedApps.isSelected(app.packageName);
                  return ListTile(
                    autofocus: index == 0,
                    onFocusChange: (value) {},
                    onTap: () {
                      ref
                          .read(androidAppsRepoProvider)
                          .value!
                          .selectApp(app.packageName, !isSelected)
                          .then((value) => ref.refresh(androidAppsProvider));
                    },
                    title: Text(app.appName),
                    subtitle: Text(app.packageName),
                    leading: CachedMemoryImage(
                      uniqueKey: app.packageName,
                      bytes: app.icon,
                      fit: BoxFit.contain,
                    ),
                    trailing: isSelected ? toggleOnIcon : toggleOffIcon,
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
