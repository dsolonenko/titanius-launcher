part of 'package:titanius/pages/settings.dart';

Future<void> _refreshDaijishoEmulators(
  BuildContext context,
  WidgetRef ref,
) async {
  final pd = ProgressDialog(context: context);
  pd.show(
    max: 100,
    msg: "Fetching Daijishō platforms...",
    backgroundColor: Colors.black,
    msgStyle: const TextStyle(color: Colors.white),
    valueStyle: const TextStyle(color: Colors.white70),
  );
  try {
    final systems = await ref.read(allSupportedSystemsProvider.future);
    final systemIds = systems.map((s) => s.id).toList();
    final count = await ref
        .read(daijishoPlatformsServiceProvider)
        .refreshAll(
          systemIds,
          onProgress: (current, total, status) {
            if (pd.isOpen()) {
              final pct = total > 0 ? (current * 100 ~/ total) : 0;
              pd.update(value: pct, msg: status);
            }
          },
        );
    ref.invalidate(alternativeEmulatorsProvider);
    pd.close();
    Fluttertoast.showToast(msg: "Updated $count Daijishō platforms");
  } catch (e) {
    debugPrint("Failed to refresh Daijishō emulators: $e");
    pd.close();
    Fluttertoast.showToast(msg: "Failed to refresh Daijishō emulators");
  }
}

Future<void> _refreshDaijishoPlatformForSystem(
  BuildContext context,
  WidgetRef ref,
  String systemId,
) async {
  final pd = ProgressDialog(context: context);
  pd.show(
    msg: "Downloading $systemId from Daijishō...",
    backgroundColor: Colors.black,
    msgStyle: const TextStyle(color: Colors.white),
  );
  try {
    await ref
        .read(daijishoPlatformsServiceProvider)
        .refreshPlatformForSystem(systemId);
    ref.invalidate(alternativeEmulatorsProvider);
    pd.close();
    Fluttertoast.showToast(msg: "Updated $systemId from Daijishō");
  } catch (e) {
    debugPrint("Failed to refresh $systemId from Daijishō: $e");
    pd.close();
    Fluttertoast.showToast(msg: "Failed to refresh $systemId");
  }
}

class AlternativeEmulatorsSettingPage extends HookConsumerWidget {
  const AlternativeEmulatorsSettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulators = ref.watch(alternativeEmulatorsProvider);
    final selectedIndex = usePersistentSelection('/settings/emulators');

    useGamepad(ref, (location, key) {
      if (location != "/settings/emulators") return;
      final emuList =
          emulators.value
              ?.where((element) => element.defaultEmulator != null)
              .toList() ??
          [];
      if (emuList.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          emuList.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          emuList.length - 1,
        );
      }
      if (key == GamepadButton.confirm) {
        final current =
            emuList[selectedIndex.value.clamp(0, emuList.length - 1)];
        context.push("/settings/emulators/${current.system.id}");
      }
      if (key == GamepadButton.x) {
        final current =
            emuList[selectedIndex.value.clamp(0, emuList.length - 1)];
        ref
            .read(perSystemConfigurationRepoProvider)
            .deleteAlternativeEmulator(current.system.id)
            .then((value) => ref.refresh(perSystemConfigurationsProvider));
      }
      if (key == GamepadButton.y) {
        _refreshDaijishoEmulators(context, ref);
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternative Emulators'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Daijishō",
            onPressed: () => _refreshDaijishoEmulators(context, ref),
          ),
        ],
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.confirm], "Change"),
          GamepadPrompt([GamepadButton.x], "Default"),
          GamepadPrompt([GamepadButton.y], "Refresh Daijishō"),
          GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: emulators.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (emulators) {
          final emuList = emulators
              .where((element) => element.defaultEmulator != null)
              .toList();
          return ControllerListView.builder(
            key: const PageStorageKey("settings/emulators"),
            selectedIndex: selectedIndex.value,
            itemCount: emuList.length,
            itemBuilder: (context, index) {
              final isDaijisho = emuList[index].defaultEmulator!.isDaijisho;
              final isStandalone = emuList[index].defaultEmulator!.isStandalone;
              final isCustom = emuList[index].defaultEmulator!.isCustom;
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
                        context.push(
                          "/settings/emulators/${emuList[index].system.id}",
                        );
                      },
                      title: Text(
                        emuList[index].system.name,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        "${emuList[index].defaultEmulator!.name}${isDaijisho
                            ? " (Daijishō)"
                            : isCustom
                            ? " (Custom)"
                            : isStandalone
                            ? " (Standalone)"
                            : ""}",
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
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

class SelectAlternativeEmulatorSettingPage extends HookConsumerWidget {
  const SelectAlternativeEmulatorSettingPage(this.system, {super.key});

  final String system;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulators = ref.watch(alternativeEmulatorsProvider);
    final selectedIndex = usePersistentSelection('/settings/emulators/$system');

    useGamepad(ref, (location, key) {
      if (location != "/settings/emulators/$system") return;
      final selected = emulators.value?.firstWhere(
        (e) => e.system.id == system,
      );
      if (selected == null || selected.emulators.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          selected.emulators.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          selected.emulators.length - 1,
        );
      }
      if (key == GamepadButton.confirm) {
        final emulator =
            selected.emulators[selectedIndex.value.clamp(
              0,
              selected.emulators.length - 1,
            )];
        ref
            .read(perSystemConfigurationRepoProvider)
            .saveAlternativeEmulator(system, emulator.id)
            .then((value) => ref.refresh(perSystemConfigurationsProvider));
        context.pop();
      }
      if (key == GamepadButton.y) {
        _refreshDaijishoPlatformForSystem(context, ref, system);
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Emulators for $system'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Daijishō",
            onPressed: () =>
                _refreshDaijishoPlatformForSystem(context, ref, system),
          ),
        ],
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.confirm], "Select"),
          GamepadPrompt([GamepadButton.y], "Refresh"),
          GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: emulators.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (emulators) {
          final selected = emulators.firstWhere((e) => e.system.id == system);
          return ControllerGroupedListView<Emulator, String>(
            key: PageStorageKey("settings/emulators/$system"),
            selectedIndex: selectedIndex.value,
            elements: selected.emulators,
            groupBy: (element) => element.isDaijisho
                ? "Daijishō"
                : element.isCustom
                ? "Custom"
                : "Built-In",
            groupSeparatorBuilder: (String value) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(value, style: const TextStyle(color: Colors.grey)),
            ),
            indexedItemBuilder: (context, emulator, index) {
              final isStandalone = emulator.isStandalone;
              final isCurrentDefault =
                  selected.defaultEmulator?.id == emulator.id;
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
                            .read(perSystemConfigurationRepoProvider)
                            .saveAlternativeEmulator(system, emulator.id)
                            .then(
                              (value) =>
                                  ref.refresh(perSystemConfigurationsProvider),
                            );
                        context.pop();
                      },
                      title: Text(
                        emulator.name,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      leading: isCurrentDefault
                          ? Icon(
                              Icons.star,
                              color: isSelected ? Colors.black : Colors.amber,
                            )
                          : null,
                      minLeadingWidth: 20,
                      trailing: isStandalone
                          ? Text(
                              "Standalone",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
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
