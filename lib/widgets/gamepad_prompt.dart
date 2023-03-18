import 'package:flutter/material.dart';

import '../gamepad.dart';

const gamepadFontMappings = {
  GamepadButton.up: "\u{219F}",
  GamepadButton.down: "\u{21A1}",
  GamepadButton.upDown: "\u{21A3}",
  GamepadButton.left: "\u{219E}",
  GamepadButton.right: "\u{21A0}",
  GamepadButton.leftRight: "\u{21A2}",
  GamepadButton.a: "\u{21D3}",
  GamepadButton.b: "\u{21D2}",
  GamepadButton.x: "\u{21D0}",
  GamepadButton.y: "\u{21D1}",
  GamepadButton.l1: "\u{21B0}",
  GamepadButton.l2: "\u{21B2}",
  GamepadButton.r1: "\u{21B1}",
  GamepadButton.r2: "\u{21B3}",
  GamepadButton.start: "\u{21F8}",
  GamepadButton.select: "\u{21F7}",
};

class GamepadPromptWidget extends StatelessWidget {
  final GamepadButton button;
  final String prompt;

  const GamepadPromptWidget(
      {super.key, required this.button, required this.prompt});

  @override
  Widget build(BuildContext context) {
    String? buttonText = gamepadFontMappings[button];
    return Row(
      children: [
        Text(buttonText ?? "",
            style: const TextStyle(fontFamily: "Prompt", fontSize: 18)),
        Text(" $prompt "),
      ],
    );
  }
}
