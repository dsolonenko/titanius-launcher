import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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

    final selected = useState("");
    final confirm = useState(false);
    final inPrompt = useState(false);

    useGamepad(ref, (location, key) {
      if (inPrompt.value) {
        return;
      }
      if (location != "/settings/scraper") return;
      if (key == GamepadButton.b) {
        if (confirm.value) {
          confirm.value = false;
        } else {
          GoRouter.of(context).pop();
        }
      }
      if (key == GamepadButton.y) {
        if (confirm.value) {
          _startScraper(ref).then((value) => GoRouter.of(context).go("/"));
        } else {
          confirm.value = true;
        }
      }
      if (key == GamepadButton.x) {
        debugPrint("Try stopping service");
        final service = ref.read(scraperServiceProvider);
        service.invoke("stop", {});
      }
      if (key == GamepadButton.right || key == GamepadButton.left) {
        if (selected.value == "scrape_these_games") {
          int index =
              scrapeTheseGamesOptions.indexWhere((id) => id == (settings.value!.scrapeTheseGames ?? "missing_details"));
          if (key == GamepadButton.right) {
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
          ref
              .read(settingsRepoProvider)
              .value!
              .setScrapeTheseGames(selected)
              .then((value) => ref.refresh(settingsProvider));
        }
      }
    });

    final elements = [
      SettingElement(
        group: "Credentials",
        widget: ListTile(
          autofocus: true,
          title: const Text("Username"),
          trailing: arrowRight,
          onFocusChange: (value) {
            if (value) {
              selected.value = "username";
            }
          },
          onTap: () async {
            inPrompt.value = true;
            try {
              final v = await prompt(
                context,
                title: const Text("Name"),
                initialValue: settings.value!.screenScraperUser ?? "",
                isSelectedInitialValue: true,
                decoration: const InputDecoration(
                  helperText: "Screenscraper username",
                  border: OutlineInputBorder(),
                ),
                validator: (s) {
                  if (s == null || s.isEmpty) {
                    return "Name cannot be empty";
                  }
                  return null;
                },
              );
              if (v != null) {
                ref
                    .read(settingsRepoProvider)
                    .value!
                    .setScreenScraperUser(v)
                    .then((value) => ref.refresh(settingsProvider));
              }
            } finally {
              inPrompt.value = false;
            }
          },
        ),
      ),
      SettingElement(
        group: "Credentials",
        widget: ListTile(
          title: const Text("Password"),
          trailing: arrowRight,
          onTap: () async {
            inPrompt.value = true;
            try {
              final v = await prompt(
                context,
                title: const Text("Password"),
                initialValue: settings.value!.screenScraperPwd ?? "",
                isSelectedInitialValue: true,
                decoration: const InputDecoration(
                  helperText: "Screenscraper password",
                  border: OutlineInputBorder(),
                ),
                validator: (s) {
                  if (s == null || s.isEmpty) {
                    return "Password cannot be empty";
                  }
                  return null;
                },
              );
              if (v != null) {
                ref
                    .read(settingsRepoProvider)
                    .value!
                    .setScreenScraperPwd(v)
                    .then((value) => ref.refresh(settingsProvider));
              }
            } finally {
              inPrompt.value = false;
            }
          },
          onFocusChange: (value) {
            if (value) {
              selected.value = "password";
            }
          },
        ),
      ),
      SettingElement(
        group: "Settings",
        widget: ListTile(
          title: const Text("Scrape These Games"),
          trailing: settings.when(
            data: (data) {
              int index = scrapeTheseGamesOptions
                  .indexWhere((id) => id == (settings.value!.scrapeTheseGames ?? "missing_details"));
              return SelectorWidget(text: scrapeTheseGamesOptionsNames[index]);
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => const Text("Error"),
          ),
          onTap: () {},
          onFocusChange: (value) {
            if (value) {
              selected.value = "scrape_these_games";
            }
          },
        ),
      ),
      SettingElement(
        group: "Settings",
        widget: ListTile(
          title: const Text("Scrape These Systems"),
          trailing: settings.when(
            data: (data) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${data.scrapeTheseSystems.length} selected"),
                  arrowRight,
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => const Text("Error"),
          ),
          onTap: () {
            context.push("/settings/scraper/systems");
          },
          onFocusChange: (value) {
            if (value) {
              selected.value = "scrape_these_systems";
            }
          },
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scraper'),
      ),
      bottomNavigationBar: PromptBar(
        navigations: const [],
        actions: [
          GamepadPrompt([GamepadButton.b], confirm.value ? "Cancel" : "Back"),
          GamepadPrompt([GamepadButton.y], confirm.value ? "Confirm" : "Start"),
        ],
      ),
      body: confirm.value
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 48),
                  SizedBox(height: 8),
                  Text("Start scraping?"),
                  SizedBox(height: 8),
                  Text("It may take a while... Please refresh gamelists after scraping is done."),
                ],
              ),
            )
          : GroupedListView<SettingElement, String>(
              key: const PageStorageKey("/settings/scraper"),
              elements: elements,
              groupBy: (element) => element.group,
              groupSeparatorBuilder: (String value) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              itemBuilder: (context, element) {
                return element.widget;
              },
              sort: false,
            ),
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
  final systems = allSystems.where((s) => systemsToScrape.contains(s.id)).map((e) => e.toJson()).toList();
  final existingRoms = allGames.where((g) => systemsToScrape.contains(g.system.id)).map((e) => e.toJson()).toList();
  final service = ref.read(scraperServiceProvider);
  if (Platform.isAndroid) {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
      ),
    );
    final isRunning = await service.isRunning();
    if (isRunning) {
      debugPrint("Already running");
      return;
    }
    debugPrint("Starting service");
    await service.startService();
  } else {
    debugPrint("Emulating service");
    onStart(service);
  }
  debugPrint("Invoking service");
  service.invoke(
    "scrape",
    {
      "username": settings.screenScraperUser,
      "password": settings.screenScraperPwd,
      "romFolders": romFolders,
      "roms": existingRoms,
      "scrapeTheseGames": settings.scrapeTheseGames ?? "all_games",
      "systems": systems,
    },
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final CancellationToken cancellationToken = CancellationToken();

  service.on('scrape').listen((event) async {
    debugPrint("Got scrape request: $event");
    CancellableCompleter completer = CancellableCompleter(cancellationToken, onCancel: () {
      debugPrint("Cancelling scrape request");
      service.stopSelf();
    });
    completer.complete(scrapeGames(service, event));
    debugPrint("Scraper is running...");
  });

  service.on('stop').listen((event) {
    debugPrint("Force stopping the service");
    service.invoke(
      'update',
      {
        "total": 0,
        "success": 0,
        "error": 0,
        "pending": 0,
        "system": "",
        "rom": "",
        "msg": "Cancelled",
      },
    );
    cancellationToken.cancel();
    service.stopSelf();
  });
}

class SettingElement {
  final String group;
  final Widget widget;

  const SettingElement({
    required this.group,
    required this.widget,
  });
}
