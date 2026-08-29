import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:screenscraper/screenscraper.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'package:titanius/data/state.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/selected_scroll_tile.dart';

part 'package:titanius/pages/filters/genres.dart';

const checkBoxSize = 40.0;
const checkBoxOnIcon = Icon(Icons.check_box_outlined, size: checkBoxSize);
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
    final selectedIndex = usePersistentSelection('/games/$system/filter');
    final inPrompt = useState(false);

    Future<void> editNameFilter() async {
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
          ref
              .read(temporaryGameFilterProvider(system).notifier)
              .setSearch(value);
        }
      } finally {
        inPrompt.value = false;
      }
    }

    void cycleFavourite() {
      switch (filter.favourite) {
        case null:
          ref
              .read(temporaryGameFilterProvider(system).notifier)
              .setFavourite(true);
          break;
        case true:
          ref
              .read(temporaryGameFilterProvider(system).notifier)
              .setFavourite(false);
          break;
        case false:
          ref
              .read(temporaryGameFilterProvider(system).notifier)
              .setFavourite(null);
          break;
      }
    }

    final items = [
      (
        title: 'Reset Filters',
        subtitle: null as String?,
        trailing: null as Widget?,
        onTap: () {
          ref.read(temporaryGameFilterProvider(system).notifier).reset();
        },
      ),
      (
        title: 'Name',
        subtitle: filter.search.isEmpty ? "All" : "Contains: ${filter.search}",
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: editNameFilter,
      ),
      (
        title: 'Genres',
        subtitle: filter.genres.isEmpty
            ? "All"
            : filter.genres.map((genre) => genre.longName).join(", "),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: () {
          context.push("/games/$system/filter/genres");
        },
      ),
      (
        title: 'Is Favourite',
        subtitle: null as String?,
        trailing:
            ToggleSwitch(
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
                )
                as Widget?,
        onTap: cycleFavourite,
      ),
    ];

    useGamepad(ref, (location, key) {
      if (inPrompt.value) {
        return;
      }
      if (location != "/games/$system/filter") return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.confirm) {
        items[selectedIndex.value].onTap();
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).go("/games/$system");
      }
      if (key == GamepadButton.x) {
        ref.read(currentGameFilterProvider(system).notifier).set(filter);
        GoRouter.of(context).go("/games/$system");
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Filters')),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.confirm], "Change"),
          GamepadPrompt([GamepadButton.x], "Apply"),
          GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: ControllerListView.builder(
        selectedIndex: selectedIndex.value,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
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
                    item.title,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: item.subtitle != null
                      ? Text(
                          item.subtitle!,
                          style: TextStyle(
                            color: isSelected ? Colors.black87 : Colors.grey,
                          ),
                        )
                      : null,
                  trailing: item.trailing,
                  onTap: () {
                    selectedIndex.value = index;
                    item.onTap();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

int boolToIndex(bool? favourite) {
  if (favourite == null) return 1;
  if (favourite) return 2;
  return 0;
}
