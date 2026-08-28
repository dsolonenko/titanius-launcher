import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/models.dart';

import 'package:titanius/data/repo.dart';
import 'package:titanius/data/scraper.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/scraper_progress.dart';
import 'package:titanius/widgets/selected_scroll_tile.dart';
import 'package:titanius/widgets/selector.dart';
import 'package:titanius/widgets/icons.dart';

part 'package:titanius/pages/settings/scraper_systems.dart';

const scrapeTheseGamesOptions = ["all_games", "favourites", "missing_details"];
const scrapeTheseGamesOptionsNames = ["All Games", "Favourites", "Missing Details"];

class ScraperPage extends HookConsumerWidget {
  const ScraperPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final scraperProgress = ref.watch(scraperProgressStateProvider);
    final isRunning = scraperProgress.isRunning;
    final selectedIndex = useState(0);
    final confirm = useState(false);
    final inPrompt = useState(false);

    Future<void> editUsername() async {
      inPrompt.value = true;
      try {
        final v = await prompt(
          context,
          title: const Text("Screenscraper username"),
          initialValue: settings.value?.screenScraperUser ?? "",
          isSelectedInitialValue: true,
          validator: (s) {
            if (s == null || s.isEmpty) {
              return "Name cannot be empty";
            }
            return null;
          },
        );
        if (v != null) {
          ref.read(settingsRepoProvider)
              .setScreenScraperUser(v)
              .then((value) => ref.refresh(settingsProvider));
        }
      } finally {
        inPrompt.value = false;
      }
    }

    Future<void> editPassword() async {
      inPrompt.value = true;
      try {
        final v = await prompt(
          context,
          title: const Text("Screenscraper password"),
          initialValue: settings.value?.screenScraperPwd ?? "",
          isSelectedInitialValue: true,
          validator: (s) {
            if (s == null || s.isEmpty) {
              return "Password cannot be empty";
            }
            return null;
          },
        );
        if (v != null) {
          ref.read(settingsRepoProvider)
              .setScreenScraperPwd(v)
              .then((value) => ref.refresh(settingsProvider));
        }
      } finally {
        inPrompt.value = false;
      }
    }

    void cycleScrapeTheseGames(bool next) {
      final currentSettings = ref.read(settingsProvider).value;
      if (currentSettings == null) return;
      int index = scrapeTheseGamesOptions
          .indexWhere((id) => id == (currentSettings.scrapeTheseGames ?? "missing_details"));
      if (next) {
        index++;
      } else {
        index--;
      }
      if (index < 0) {
        index = scrapeTheseGamesOptions.length - 1;
      }
      if (index >= scrapeTheseGamesOptions.length) {
        index = 0;
      }
      final selected = scrapeTheseGamesOptions[index];
      ref.read(settingsRepoProvider)
          .setScrapeTheseGames(selected)
          .then((value) => ref.invalidate(settingsProvider));
    }

    void stopScraper() {
      debugPrint("Stopping scraper service");
      final service = ref.read(scraperServiceProvider);
      service.stopScrape();
    }

    useGamepad(ref, (location, key) {
      if (inPrompt.value) {
        return;
      }
      if (location != "/settings/scraper") return;

      if (isRunning) {
        if (key == GamepadButton.x || key == GamepadButton.a) {
          stopScraper();
        }
        if (key == GamepadButton.b) {
          GoRouter.of(context).pop();
        }
        return;
      }

      if (confirm.value) {
        if (key == GamepadButton.b) {
          confirm.value = false;
        }
        if (key == GamepadButton.y) {
          confirm.value = false;
          _startScraper(ref);
        }
        return;
      }

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(0, 3);
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(0, 3);
      }
      if (key == GamepadButton.left) {
        if (selectedIndex.value == 2) {
          cycleScrapeTheseGames(false);
        }
      }
      if (key == GamepadButton.right) {
        if (selectedIndex.value == 2) {
          cycleScrapeTheseGames(true);
        }
      }
      if (key == GamepadButton.a) {
        if (selectedIndex.value == 0) {
          editUsername();
        } else if (selectedIndex.value == 1) {
          editPassword();
        } else if (selectedIndex.value == 2) {
          cycleScrapeTheseGames(true);
        } else if (selectedIndex.value == 3) {
          context.push("/settings/scraper/systems");
        }
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
      if (key == GamepadButton.y) {
        confirm.value = true;
      }
    });

    final s = settings.value;
    int currentScrapeOptionIdx = s == null
        ? 0
        : scrapeTheseGamesOptions.indexWhere((id) => id == (s.scrapeTheseGames ?? "missing_details"));
    if (currentScrapeOptionIdx == -1) currentScrapeOptionIdx = 0;

    final elements = [
      (
        group: "Credentials",
        title: "Username",
        subtitle: s?.screenScraperUser?.isNotEmpty == true ? s!.screenScraperUser : "Not set",
        trailing: arrowRight,
        onTap: editUsername,
      ),
      (
        group: "Credentials",
        title: "Password",
        subtitle: s?.screenScraperPwd?.isNotEmpty == true ? "••••••••" : "Not set",
        trailing: arrowRight,
        onTap: editPassword,
      ),
      (
        group: "Settings",
        title: "Scrape These Games",
        subtitle: null as String?,
        trailing: SelectorWidget(text: scrapeTheseGamesOptionsNames[currentScrapeOptionIdx]),
        onTap: () => cycleScrapeTheseGames(true),
      ),
      (
        group: "Settings",
        title: "Scrape These Systems",
        subtitle: null as String?,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${s?.scrapeTheseSystems.length ?? 0} selected"),
            arrowRight,
          ],
        ),
        onTap: () => context.push("/settings/scraper/systems"),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scraper'),
      ),
      bottomNavigationBar: isRunning
          ? PromptBar(
              navigations: const [],
              actions: const [
                GamepadPrompt([GamepadButton.x, GamepadButton.a], "Stop"),
                GamepadPrompt([GamepadButton.b], "Back"),
              ],
              text: "Scraping in background",
            )
          : PromptBar(
              navigations: const [],
              actions: [
                GamepadPrompt([GamepadButton.a], "Select"),
                GamepadPrompt([GamepadButton.b], confirm.value ? "Cancel" : "Back"),
                GamepadPrompt([GamepadButton.y], confirm.value ? "Confirm" : "Start"),
              ],
            ),
      body: isRunning
          ? _buildActiveScrapingView(context, ref, scraperProgress, stopScraper)
          : confirm.value
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 48),
                      SizedBox(height: 8),
                      Text("Start scraping?"),
                      SizedBox(height: 8),
                      Text("It may take a while... Scraping will run in background."),
                    ],
                  ),
                )
              : ListView.builder(
                  key: const PageStorageKey("/settings/scraper"),
                  itemCount: elements.length,
                  itemBuilder: (context, index) {
                    final elem = elements[index];
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
                            title: Text(
                              elem.title,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: elem.subtitle != null
                                ? Text(
                                    elem.subtitle!,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black87 : Colors.grey,
                                    ),
                                  )
                                : null,
                            trailing: elem.trailing,
                            onTap: () {
                              selectedIndex.value = index;
                              elem.onTap();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildActiveScrapingView(
    BuildContext context,
    WidgetRef ref,
    ScraperProgress progress,
    VoidCallback onStop,
  ) {
    final double? percent = progress.total > 0
        ? ((progress.total - progress.pending) / progress.total).clamp(0.0, 1.0)
        : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      progress.message.isNotEmpty ? progress.message : "Scraping...",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (progress.system.isNotEmpty || progress.rom.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (progress.system.isNotEmpty)
                        Text(
                          "System: ${progress.system.toUpperCase()}",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      if (progress.rom.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          progress.rom,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.white24,
                color: Colors.green,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    progress.total > 0
                        ? "${progress.total - progress.pending} / ${progress.total}"
                        : "Discovering ROMs...",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (percent != null)
                    Text(
                      "${(percent * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("Success", progress.success, Colors.green),
                  _statItem("Errors", progress.error, Colors.redAccent),
                  _statItem("Pending", progress.pending, Colors.white70),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.red.shade900.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onStop,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Stop Scraping",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String title, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          "$count",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

Future<void> _startScraper(WidgetRef ref) async {
  debugPrint("Starting scraping...");
  final romFolders = await ref.read(romFoldersProvider.future);
  final allGames = await ref.read(allGamesProvider.future);
  final allSystems = await ref.read(allSupportedSystemsProvider.future);
  final settings = await ref.read(settingsProvider.future);
  final systemsToScrape = settings.scrapeTheseSystems.toSet();
  final systems = allSystems.where((s) => systemsToScrape.contains(s.id)).toList();
  final existingRoms = allGames.where((g) => systemsToScrape.contains(g.system.id)).toList();
  final service = ref.read(scraperServiceProvider);
  if (await service.isRunning()) {
    debugPrint("Already running");
    return;
  }
  debugPrint("Starting service");
  await service.startScrape(
    username: settings.screenScraperUser,
    password: settings.screenScraperPwd,
    romFolders: romFolders,
    roms: existingRoms,
    scrapeTheseGames: settings.scrapeTheseGames ?? "all_games",
    systems: systems,
  );
}

class SettingElement {
  final String group;
  final Widget widget;

  const SettingElement({
    required this.group,
    required this.widget,
  });
}
