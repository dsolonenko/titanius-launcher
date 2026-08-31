part of 'package:titanius/pages/settings.dart';

class RetroAchievementsSettingsPage extends HookConsumerWidget {
  const RetroAchievementsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final selectedIndex = usePersistentSelection('/settings/retroachievements');
    final inPrompt = useState(false);
    final isTesting = useState(false);
    final isClearingCaches = useState(false);
    final confirmClearCaches = useState(false);
    final s = settings.value;

    Future<void> editUsername() async {
      inPrompt.value = true;
      try {
        final v = await prompt(
          context,
          title: const Text('RetroAchievements Username'),
          initialValue: s?.retroAchievementsUser ?? '',
          isSelectedInitialValue: true,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Username cannot be empty';
            }
            return null;
          },
        );
        if (v != null && context.mounted) {
          await ref
              .read(settingsRepoProvider)
              .setRetroAchievementsUser(v.trim());
          ref.invalidate(settingsProvider);
          ref.invalidate(retroAchievementsUserSummaryProvider);
        }
      } finally {
        inPrompt.value = false;
      }
    }

    Future<void> editApiKey() async {
      inPrompt.value = true;
      try {
        final v = await prompt(
          context,
          title: const Text('RetroAchievements Web API Key'),
          initialValue: s?.retroAchievementsApiKey ?? '',
          isSelectedInitialValue: true,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'API Key cannot be empty';
            }
            return null;
          },
        );
        if (v != null && context.mounted) {
          await ref
              .read(settingsRepoProvider)
              .setRetroAchievementsApiKey(v.trim());
          ref.invalidate(settingsProvider);
          ref.invalidate(retroAchievementsUserSummaryProvider);
        }
      } finally {
        inPrompt.value = false;
      }
    }

    Future<void> testConnection() async {
      if (s == null || !s.hasRetroAchievements) {
        Fluttertoast.showToast(
          msg: 'Please enter both Username and Web API Key first.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orangeAccent,
          textColor: Colors.black,
        );
        return;
      }

      isTesting.value = true;
      try {
        final profile = await testRetroAchievementsCredentials(
          username: s.retroAchievementsUser!,
          webApiKey: s.retroAchievementsApiKey!,
        );
        ref.invalidate(retroAchievementsUserSummaryProvider);
        if (context.mounted) {
          Fluttertoast.showToast(
            msg: 'Connected as ${profile.user}! Points: ${profile.totalPoints}',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        if (context.mounted) {
          Fluttertoast.showToast(
            msg: 'Connection failed: $e',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } finally {
        isTesting.value = false;
      }
    }

    Future<void> clearCredentials() async {
      await ref.read(settingsRepoProvider).clearRetroAchievements();
      ref.invalidate(settingsProvider);
      ref.invalidate(retroAchievementsUserSummaryProvider);
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: 'RetroAchievements credentials cleared',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }

    Future<void> clearCaches() async {
      if (isClearingCaches.value) return;
      if (!confirmClearCaches.value) {
        confirmClearCaches.value = true;
        return;
      }

      confirmClearCaches.value = false;
      isClearingCaches.value = true;
      try {
        await ref.read(retroAchievementsCacheRepoProvider).clearAll();
        ref.invalidate(gameRetroAchievementsProvider);
        ref.invalidate(systemRetroAchievementsProvider);
        ref.invalidate(gameRetroAchievementsDetailsProvider);
        ref.invalidate(retroAchievementsUserSummaryProvider);
        ref.invalidate(retroAchievementsUserAwardsProvider);
        ref.invalidate(retroAchievementsUserCompletionProgressProvider);
        ref.invalidate(retroAchievementsProgressMapProvider);
        ref.read(retroAchievementsCacheRevisionProvider.notifier).bump();
        if (context.mounted) {
          Fluttertoast.showToast(
            msg: 'All Cheevos caches cleared',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } catch (e) {
        if (context.mounted) {
          Fluttertoast.showToast(
            msg: 'Could not clear Cheevos caches: $e',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } finally {
        isClearingCaches.value = false;
      }
    }

    String maskApiKey(String? key) {
      if (key == null || key.isEmpty) return 'Not configured';
      if (key.length <= 6) return '••••••';
      return '••••••••${key.substring(key.length - 4)}';
    }

    final items = s == null
        ? <_RASettingItem>[]
        : [
            _RASettingItem(
              title: 'Username',
              subtitle: s.retroAchievementsUser?.isNotEmpty == true
                  ? s.retroAchievementsUser
                  : 'Not configured',
              trailing: arrowRight,
              onAction: editUsername,
            ),
            _RASettingItem(
              title: 'Web API Key',
              subtitle: maskApiKey(s.retroAchievementsApiKey),
              trailing: arrowRight,
              onAction: editApiKey,
            ),
            _RASettingItem(
              title: 'Test Connection',
              subtitle: isTesting.value
                  ? 'Testing connection...'
                  : (s.hasRetroAchievements
                        ? 'Verify login credentials'
                        : 'Configure credentials first'),
              trailing: isTesting.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : arrowRight,
              onAction: testConnection,
            ),
            _RASettingItem(
              title: 'Clear Cheevos Caches',
              subtitle: isClearingCaches.value
                  ? 'Deleting cached hashes, mappings, and API data...'
                  : confirmClearCaches.value
                  ? 'Press Select again to confirm'
                  : 'Recalculate ROM hashes and mappings for every system',
              trailing: isClearingCaches.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      confirmClearCaches.value
                          ? Icons.warning_amber_rounded
                          : Icons.delete_sweep_outlined,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
              onAction: clearCaches,
            ),
            if (s.hasRetroAchievements)
              _RASettingItem(
                title: 'Clear Credentials',
                subtitle: 'Log out of RetroAchievements',
                trailing: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onAction: clearCredentials,
              ),
          ];

    useGamepad(ref, (location, key) {
      if (inPrompt.value) return;
      if (location != '/settings/retroachievements') return;
      if (items.isEmpty) return;

      if (key == GamepadButton.up) {
        confirmClearCaches.value = false;
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        confirmClearCaches.value = false;
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.confirm) {
        final item = items[selectedIndex.value.clamp(0, items.length - 1)];
        item.onAction();
      }
      if (key == GamepadButton.back) {
        if (confirmClearCaches.value) {
          confirmClearCaches.value = false;
          return;
        }
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('RetroAchievements')),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.confirm], 'Select'),
          GamepadPrompt([GamepadButton.back], 'Back'),
        ],
      ),
      body: settings.when(
        data: (s) {
          return Column(
            children: [
              Expanded(
                child: ControllerListView.builder(
                  key: const PageStorageKey('settings/retroachievements'),
                  selectedIndex: selectedIndex.value,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                              if (selectedIndex.value != index) {
                                confirmClearCaches.value = false;
                              }
                              selectedIndex.value = index;
                              item.onAction();
                            },
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                            subtitle: item.subtitle != null
                                ? Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                  )
                                : null,
                            trailing: item.trailing,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!s.hasRetroAchievements)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: const Text(
                    'Web API key is in Settings → Applications on retroachievements.org',
                    style: TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Error')),
      ),
    );
  }
}

class _RASettingItem {
  final String title;
  final String? subtitle;
  final Widget trailing;
  final Future<void> Function() onAction;

  _RASettingItem({
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.onAction,
  });
}
