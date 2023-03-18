import 'package:flutter/material.dart';

import '../gamepad.dart';
import 'gamepad_prompt.dart';

typedef GamepadPrompts = Map<GamepadButton, String>;

class PromptBar extends StatelessWidget {
  final GamepadPrompts navigations;
  final GamepadPrompts actions;

  const PromptBar(
      {super.key, this.navigations = const {}, this.actions = const {}});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ...navigations.entries.map((e) => GamepadPromptWidget(
                button: e.key,
                prompt: e.value,
              )),
          const Spacer(),
          ...actions.entries.map((e) => GamepadPromptWidget(
                button: e.key,
                prompt: e.value,
              )),
        ],
      ),
    );
  }
}
