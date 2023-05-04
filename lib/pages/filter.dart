import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titanius/data/genres.dart';

import '../data/state.dart';
import '../gamepad.dart';
import '../widgets/prompt_bar.dart';

part 'filters/genres.dart';

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

    useGamepad(ref, (location, key) {
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
            onTap: () {
              context.push("/games/$system/filter/genres");
            },
            title: const Text('Genres'),
            subtitle:
                Text(filter.genres.isEmpty ? "All" : filter.genres.map((genre) => Genres.getName(genre)).join(", ")),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }
}