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
    final prompts = [...navigations, ...actions];
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (text.isNotEmpty) ...[
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final prompt in prompts)
                GamepadPromptWidget(
                  buttons: prompt.buttons,
                  prompt: prompt.prompt,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
