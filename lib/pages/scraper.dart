import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onscreen_keyboard/onscreen_keyboard.dart';
import 'package:titanius/data/models.dart';

import 'package:titanius/data/repo.dart';
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
          GoRouter.of(context).pop();
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

  void _showError(BuildContext context, err) {
    debugPrint(err.toString());
    Fluttertoast.showToast(
        msg: "Unable to change game settings: ${err.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}

class SettingElement {
  final String group;
  final Widget widget;

  const SettingElement({
    required this.group,
    required this.widget,
  });
}
