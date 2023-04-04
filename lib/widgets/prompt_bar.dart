import 'package:flutter/material.dart';

import '../gamepad.dart';
import 'gamepad_prompt.dart';

class GamepadPrompt {
  final List<GamepadButton> buttons;
  final String prompt;

  const GamepadPrompt(this.buttons, this.prompt);
}

typedef GamepadPrompts = List<GamepadPrompt>;

class PromptBar extends StatelessWidget {
  final GamepadPrompts navigations;
  final GamepadPrompts actions;

  const PromptBar(
      {super.key, this.navigations = const [], this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ...navigations.map((e) => GamepadPromptWidget(
                buttons: e.buttons,
                prompt: e.prompt,
              )),
          const Spacer(),
          ...actions.map((e) => GamepadPromptWidget(
                buttons: e.buttons,
                prompt: e.prompt,
              )),
        ],
      ),
    );
  }
}
