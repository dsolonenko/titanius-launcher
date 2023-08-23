import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onscreen_keyboard/onscreen_keyboard.dart';
import 'package:screenscraper/screenscraper.dart' show DoneForTheDayException, DoNotRetryException;
import 'package:titanius/data/files.dart';
import 'package:titanius/data/gamelist_xml.dart';
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

part 'package:titanius/pages/settings/scraper_name.dart';
part 'package:titanius/pages/settings/scraper_pwd.dart';
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

    useGamepad(ref, (location, key) {
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
          onTap: () {
            context.push("/settings/scraper/username");
          },
        ),
      ),
      SettingElement(
        group: "Credentials",
        widget: ListTile(
          title: const Text("Password"),
          trailing: arrowRight,
          onTap: () {
            context.push("/settings/scraper/password");
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
                  Text("Start scraping?"),
                  Text("It will take a while..."),
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
  final existingRoms =
      allGames.where((g) => systemsToScrape.contains(g.system.id)).map((g) => g.absoluteRomPath).toList();
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
    debugPrint("Starting service");
    await service.startService();
    debugPrint("Invoking service");
    service.invoke(
      "scrape",
      {
        "username": settings.screenScraperUser,
        "password": settings.screenScraperPwd,
        "romFolders": romFolders,
        "roms": existingRoms,
        "systems": systems,
      },
    );
  } else {
    debugPrint("Emulating service");

    onStart(service);
    debugPrint("Invoking service");
    service.invoke(
      "scrape",
      {
        "username": settings.screenScraperUser,
        "password": settings.screenScraperPwd,
        "romFolders": romFolders,
        "roms": existingRoms,
        "systems": systems,
      },
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('scrape').listen((event) async {
    debugPrint("Got scrape request: $event");
    try {
      final username = event!["username"] as String?;
      final password = event["password"] as String?;
      final romFolders = (event["romFolders"] as List).map((e) => e.toString()).toList();
      final roms = (event["roms"] as List).map((e) => e.toString()).toList();
      final systems = (event["systems"] as List).map((e) => System.fromJson(e)).toList();
      debugPrint("Scraping ${systems.length} systems with ${roms.length} existing roms...");
      service.invoke(
        'update',
        {
          "success": 0,
          "error": 0,
          "pending": 0,
          "system": "",
          "rom": "",
          "msg": "Starting...",
        },
      );

      try {
        final gamesToScrape = <Game>[];
        for (var system in systems) {
          for (var romsFolder in romFolders) {
            for (var folder in system.folders) {
              final games = await listGamesFromFiles(
                romsFolder: romsFolder,
                folder: folder,
                system: system,
              );
              gamesToScrape.addAll(games);
              service.invoke(
                'update',
                {
                  "success": 0,
                  "error": 0,
                  "pending": gamesToScrape.length,
                  "system": "",
                  "rom": "",
                  "msg": "Discovering...",
                },
              );
            }
          }
        }
        service.invoke(
          'update',
          {
            "success": 0,
            "error": 0,
            "pending": gamesToScrape.length,
            "system": "",
            "rom": "",
            "msg": "Scraping...",
          },
        );
        var success = 0;
        var error = 0;
        var pending = gamesToScrape.length;
        final scraper = Scraper(userName: username ?? "", userPassword: password ?? "");
        for (var game in gamesToScrape) {
          try {
            final scrapedGame = await scraper.scrape(game.asRomToScrape(), (msg) {
              service.invoke(
                'update',
                {
                  "success": success,
                  "error": error,
                  "pending": pending,
                  "system": game.system.id,
                  "rom": game.rom,
                  "msg": msg,
                },
              );
            });
            service.invoke(
              'update',
              {
                "success": success,
                "error": error,
                "pending": pending,
                "system": game.system.id,
                "rom": game.rom,
                "msg": "Writing gamelist.xml...",
              },
            );
            await updateGameInGamelistXml(scrapedGame);
            success++;
          } on DoNotRetryException {
            debugPrint("Error scraping ${game.rom}: Fatal error");
            service.invoke(
              'update',
              {
                "success": success,
                "error": error,
                "pending": pending,
                "system": "",
                "rom": "",
                "msg": "Fatal error",
              },
            );
            return;
          } on DoneForTheDayException {
            debugPrint("Error scraping ${game.rom}: Done for the day");
            error++;
            service.invoke(
              'update',
              {
                "success": success,
                "error": error,
                "pending": pending,
                "system": "",
                "rom": "",
                "msg": "Quota exceeded",
              },
            );
            return;
          } catch (e) {
            debugPrint("Error scraping ${game.rom}: $e");
            error++;
            service.invoke(
              'update',
              {
                "success": success,
                "error": error,
                "pending": pending,
                "system": game.system.id,
                "rom": game.rom,
                "msg": "Error",
              },
            );
          }
          pending--;
        }
        service.invoke(
          'update',
          {
            "success": success,
            "error": error,
            "pending": pending,
            "system": "",
            "rom": "",
            "msg": "Done",
          },
        );
      } finally {
        debugPrint("Stopping service...");
        service.stopSelf();
      }
    } catch (e, s) {
      debugPrint("Error scraping: $e, $s");
    }
  });

  service.on('stop').listen((event) {
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
