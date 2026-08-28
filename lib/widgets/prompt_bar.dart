import 'package:flutter/material.dart';

import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/gamepad_prompt.dart';

class GamepadPrompt {
  final List<GamepadButton> buttons;
  final String prompt;

  const GamepadPrompt(this.buttons, this.prompt);
}

typedef GamepadPrompts = List<GamepadPrompt>;

class PromptBar extends StatelessWidget {
  final String text;
  final GamepadPrompts navigations;
  final GamepadPrompts actions;
  final Color? backgroundColor;

  const PromptBar({
    super.key,
    this.text = "",
    this.navigations = const [],
    this.actions = const [],
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ...navigations.map((e) => GamepadPromptWidget(
                buttons: e.buttons,
                prompt: e.prompt,
              )),
          Expanded(
            child: Text(
              text,
              textScaler: const TextScaler.linear(0.8),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...actions.map((e) => GamepadPromptWidget(
                buttons: e.buttons,
                prompt: e.prompt,
              )),
        ],
      ),
    );
  }
}
