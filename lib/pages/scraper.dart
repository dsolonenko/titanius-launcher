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
import 'package:titanius/data/files.dart';
import 'package:titanius/data/gamelist_xml.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/models.dart';

import 'package:titanius/data/repo.dart';
import 'package:titanius/data/scraper.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/prompt_bar.dart';
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
          _startScraper(ref).then((value) => GoRouter.of(context).pop());
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
  final romFolders = await ref.watch(romFoldersProvider.future);
  final allGames = await ref.read(allGamesProvider.future);
  final allSystems = await ref.read(allSupportedSystemsProvider.future);
  final settings = await ref.read(settingsProvider.future);
  final systemsToScrape = settings.scrapeTheseSystems.toSet();
  final systems = allSystems.where((s) => systemsToScrape.contains(s.id)).map((e) => e.toJson()).toList();
  final existingRoms =
      allGames.where((g) => systemsToScrape.contains(g.system.id)).map((g) => g.absoluteRomPath).toList();
  dynamic service;
  if (Platform.isAndroid) {
    service = FlutterBackgroundService();
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
  } else {
    debugPrint("Emulating service");
    service = FakeServiceInstance();
    onStart(service);
  }
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

class FakeServiceInstance extends ServiceInstance {
  final scrapeController = StreamController<Map<String, dynamic>?>();
  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    debugPrint("Invoking $method with $args");
    if (method == "scrape") {
      scrapeController.add(args);
    }
  }

  @override
  Stream<Map<String, dynamic>?> on(String method) {
    debugPrint("Listening to $method");
    if (method != "scrape") {
      return const Stream.empty();
    }
    return scrapeController.stream;
  }

  @override
  Future<void> stopSelf() async {
    debugPrint("Stopping service");
    scrapeController.close();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('scrape').listen((event) async {
    debugPrint("Got scrape request: $event");
    final username = event!["username"] as String;
    final password = event["password"] as String;
    final romFolders = event["romFolders"] as List<String>;
    final roms = event["roms"] as List<String>;
    final systems = (event["systems"] as List).map((e) => System.fromJson(e)).toList();
    debugPrint("Scraping ${systems.length} systems with ${roms.length} existing roms...");
    service.invoke(
      'update',
      {
        "success": 0,
        "error": 0,
        "pending": 0,
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
          "msg": "Scraping...",
        },
      );
      var success = 0;
      var error = 0;
      var pending = gamesToScrape.length;
      final scraper = Scraper(userName: username, userPassword: password);
      for (var game in gamesToScrape) {
        try {
          final scrapedGame = await scraper.scrape(game.asRomToScrape(), (msg) {
            service.invoke(
              'update',
              {
                "success": success,
                "error": error,
                "pending": pending,
                "msg": "${game.rom}: $msg",
              },
            );
          });
          service.invoke(
            'update',
            {
              "success": success,
              "error": error,
              "pending": pending,
              "msg": "${game.rom}: Writing gamelist.xml...",
            },
          );
          await updateGameInGamelistXml(scrapedGame);
          success++;
        } catch (e) {
          error++;
        }
        if (success + error > 1) {
          break;
        }
        pending--;
      }
      service.invoke(
        'update',
        {
          "success": success,
          "error": error,
          "pending": pending,
          "msg": "Done",
        },
      );
    } finally {
      service.stopSelf();
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
