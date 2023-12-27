import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:screenscraper/screenscraper.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'package:titanius/data/state.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/prompt_bar.dart';

part 'package:titanius/pages/filters/genres.dart';

const checkBoxSize = 40.0;
const checkBoxOnIcon = Icon(
  Icons.check_box_outlined,
  size: checkBoxSize,
);
const checkBoxOffIcon = Icon(
  Icons.check_box_outline_blank_outlined,
  size: checkBoxSize,
  color: Colors.grey,
);

class FiltersPage extends HookConsumerWidget {
  final String system;
  const FiltersPage({super.key, required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(temporaryGameFilterProvider(system));
    final inPrompt = useState(false);

    useGamepad(ref, (location, key) {
      if (inPrompt.value) {
        return;
      }
      if (location != "/games/$system/filter") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/games/$system");
      }
      if (key == GamepadButton.x) {
        ref.read(currentGameFilterProvider(system).notifier).set(filter);
        GoRouter.of(context).go("/games/$system");
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.x], "Apply"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            autofocus: true,
            onFocusChange: (value) {},
            onTap: () {
              ref.read(temporaryGameFilterProvider(system).notifier).reset();
            },
            title: const Text('Reset Filters'),
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () async {
              inPrompt.value = true;
              try {
                final value = await prompt(
                  context,
                  title: const Text("Name Filter"),
                  initialValue: filter.search,
                  isSelectedInitialValue: true,
                  controller: TextEditingController(text: filter.search),
                );
                if (value != null) {
                  ref.read(temporaryGameFilterProvider(system).notifier).setSearch(value);
                }
              } finally {
                inPrompt.value = false;
              }
            },
            title: const Text('Name'),
            subtitle: Text(filter.search.isEmpty ? "All" : "Contains: ${filter.search}"),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              context.push("/games/$system/filter/genres");
            },
            title: const Text('Genres'),
            subtitle: Text(filter.genres.isEmpty ? "All" : filter.genres.map((genre) => genre.longName).join(", ")),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
          ListTile(
            onFocusChange: (value) {},
            onTap: () {
              switch (filter.favourite) {
                case null:
                  ref.read(temporaryGameFilterProvider(system).notifier).setFavourite(true);
                  break;
                case true:
                  ref.read(temporaryGameFilterProvider(system).notifier).setFavourite(false);
                  break;
                case false:
                  ref.read(temporaryGameFilterProvider(system).notifier).setFavourite(null);
                  break;
              }
            },
            title: const Text('Is Favourite'),
            trailing: ToggleSwitch(
              changeOnTap: false,
              cancelToggle: (index) async => true,
              minWidth: 40.0,
              minHeight: 24.0,
              cornerRadius: 20.0,
              inactiveBgColor: Colors.black,
              inactiveFgColor: Colors.grey,
              initialLabelIndex: boolToIndex(filter.favourite),
              totalSwitches: 3,
              labels: const ['No', 'All', 'Yes'],
            ),
          ),
        ],
      ),
    );
  }
}

int boolToIndex(bool? favourite) {
  if (favourite == null) return 1;
  if (favourite) return 2;
  return 0;
}
