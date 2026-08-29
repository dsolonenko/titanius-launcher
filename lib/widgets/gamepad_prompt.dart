import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/gamepad.dart';

String getGamepadButtonGlyph(
  GamepadButton button,
  ControllerLayout layout,
  bool swapConfirm,
) {
  switch (layout) {
    case ControllerLayout.nintendo:
      switch (button) {
        case GamepadButton.up:
          return "\u{219F}";
        case GamepadButton.down:
          return "\u{21A1}";
        case GamepadButton.upDown:
          return "\u{21A3}";
        case GamepadButton.left:
          return "\u{219E}";
        case GamepadButton.right:
          return "\u{21A0}";
        case GamepadButton.leftRight:
          return "\u{21A2}";
        case GamepadButton.a:
          return swapConfirm ? "\u{21D3}" : "\u{21D2}";
        case GamepadButton.b:
          return swapConfirm ? "\u{21D2}" : "\u{21D3}";
        case GamepadButton.x:
          return "\u{21D1}";
        case GamepadButton.y:
          return "\u{21D0}";
        case GamepadButton.l1:
          return "\u{219C}";
        case GamepadButton.r1:
          return "\u{219D}";
        case GamepadButton.l2:
          return "\u{219A}";
        case GamepadButton.r2:
          return "\u{219B}";
        case GamepadButton.start:
          return "\u{21FE}";
        case GamepadButton.select:
          return "\u{21FD}";
        default:
          return "";
      }
    case ControllerLayout.generic:
      switch (button) {
        case GamepadButton.up:
          return "\u{219F}";
        case GamepadButton.down:
          return "\u{21A1}";
        case GamepadButton.upDown:
          return "\u{21A3}";
        case GamepadButton.left:
          return "\u{219E}";
        case GamepadButton.right:
          return "\u{21A0}";
        case GamepadButton.leftRight:
          return "\u{21A2}";
        case GamepadButton.a:
          return swapConfirm ? "\u{21A6}" : "\u{21A7}";
        case GamepadButton.b:
          return swapConfirm ? "\u{21A7}" : "\u{21A6}";
        case GamepadButton.x:
          return "\u{21A4}";
        case GamepadButton.y:
          return "\u{21A5}";
        case GamepadButton.l1:
          return "\u{21B0}";
        case GamepadButton.l2:
          return "\u{21B2}";
        case GamepadButton.r1:
          return "\u{21B1}";
        case GamepadButton.r2:
          return "\u{21B3}";
        case GamepadButton.start:
          return "\u{21F8}";
        case GamepadButton.select:
          return "\u{21F7}";
        default:
          return "";
      }
    case ControllerLayout.xbox:
      switch (button) {
        case GamepadButton.up:
          return "\u{219F}";
        case GamepadButton.down:
          return "\u{21A1}";
        case GamepadButton.upDown:
          return "\u{21A3}";
        case GamepadButton.left:
          return "\u{219E}";
        case GamepadButton.right:
          return "\u{21A0}";
        case GamepadButton.leftRight:
          return "\u{21A2}";
        case GamepadButton.a:
          return swapConfirm ? "\u{21D2}" : "\u{21D3}";
        case GamepadButton.b:
          return swapConfirm ? "\u{21D3}" : "\u{21D2}";
        case GamepadButton.x:
          return "\u{21D0}";
        case GamepadButton.y:
          return "\u{21D1}";
        case GamepadButton.l1:
          return "\u{21B0}";
        case GamepadButton.l2:
          return "\u{21B2}";
        case GamepadButton.r1:
          return "\u{21B1}";
        case GamepadButton.r2:
          return "\u{21B3}";
        case GamepadButton.start:
          return "\u{21F8}";
        case GamepadButton.select:
          return "\u{21F7}";
        default:
          return "";
      }
  }
}

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

class GamepadPromptWidget extends ConsumerWidget {
  final List<GamepadButton> buttons;
  final String prompt;

  const GamepadPromptWidget({
    super.key,
    required this.buttons,
    required this.prompt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final layout = settings?.controllerLayout ?? ControllerLayout.nintendo;
    final swapConfirm = settings?.swapConfirm ?? false;

    String buttonText = buttons
        .map((button) => getGamepadButtonGlyph(button, layout, swapConfirm))
        .join("");
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          buttonText,
          style: const TextStyle(
            fontFamily: "Prompt",
            fontSize: 16,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          prompt.trim(),
          style: const TextStyle(
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ],
    );
  }
}
