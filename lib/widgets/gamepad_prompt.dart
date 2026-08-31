import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/gamepad.dart';

// Prompt glyphs are rendered as text throughout the app, including controller
// prompts and collection logos. Matching const IconData objects make Flutter's
// release font tree-shaker retain every dynamically rendered codepoint.
const _promptFontIcons = <int, IconData>{
  // Collection logos.
  0x23F2: IconData(0x23F2, fontFamily: 'Prompt'),
  0x2605: IconData(0x2605, fontFamily: 'Prompt'),
  0x2753: IconData(0x2753, fontFamily: 'Prompt'),
  0x1F3C6: IconData(0x1F3C6, fontFamily: 'Prompt'),
  0x1F579: IconData(0x1F579, fontFamily: 'Prompt'),

  // Controller prompts.
  0x219A: IconData(0x219A, fontFamily: 'Prompt'),
  0x219B: IconData(0x219B, fontFamily: 'Prompt'),
  0x219C: IconData(0x219C, fontFamily: 'Prompt'),
  0x219D: IconData(0x219D, fontFamily: 'Prompt'),
  0x219E: IconData(0x219E, fontFamily: 'Prompt'),
  0x219F: IconData(0x219F, fontFamily: 'Prompt'),
  0x21A0: IconData(0x21A0, fontFamily: 'Prompt'),
  0x21A1: IconData(0x21A1, fontFamily: 'Prompt'),
  0x21A2: IconData(0x21A2, fontFamily: 'Prompt'),
  0x21A3: IconData(0x21A3, fontFamily: 'Prompt'),
  0x21A4: IconData(0x21A4, fontFamily: 'Prompt'),
  0x21A5: IconData(0x21A5, fontFamily: 'Prompt'),
  0x21A6: IconData(0x21A6, fontFamily: 'Prompt'),
  0x21A7: IconData(0x21A7, fontFamily: 'Prompt'),
  0x21B0: IconData(0x21B0, fontFamily: 'Prompt'),
  0x21B1: IconData(0x21B1, fontFamily: 'Prompt'),
  0x21B2: IconData(0x21B2, fontFamily: 'Prompt'),
  0x21B3: IconData(0x21B3, fontFamily: 'Prompt'),
  0x21BA: IconData(0x21BA, fontFamily: 'Prompt'),
  0x21BB: IconData(0x21BB, fontFamily: 'Prompt'),
  0x21D0: IconData(0x21D0, fontFamily: 'Prompt'),
  0x21D1: IconData(0x21D1, fontFamily: 'Prompt'),
  0x21D2: IconData(0x21D2, fontFamily: 'Prompt'),
  0x21D3: IconData(0x21D3, fontFamily: 'Prompt'),
  0x21F7: IconData(0x21F7, fontFamily: 'Prompt'),
  0x21F8: IconData(0x21F8, fontFamily: 'Prompt'),
  0x21FD: IconData(0x21FD, fontFamily: 'Prompt'),
  0x21FE: IconData(0x21FE, fontFamily: 'Prompt'),
};

String getGamepadButtonGlyph(
  GamepadButton button,
  ControllerLayout layout,
  bool swapConfirm,
) {
  final glyph = _getGamepadButtonGlyph(button, layout, swapConfirm);
  if (glyph.isEmpty) return glyph;
  final icon = _promptFontIcons[glyph.runes.single];
  return icon == null ? glyph : String.fromCharCode(icon.codePoint);
}

String _getGamepadButtonGlyph(
  GamepadButton button,
  ControllerLayout layout,
  bool swapConfirm,
) {
  switch (layout) {
    case ControllerLayout.retro:
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
        case GamepadButton.confirm:
          return swapConfirm ? "\u{21D2}" : "\u{21D3}";
        case GamepadButton.back:
          return swapConfirm ? "\u{21D3}" : "\u{21D2}";
        case GamepadButton.x:
          return "\u{21D0}";
        case GamepadButton.y:
          return "\u{21D1}";
        case GamepadButton.l1:
          return "\u{219C}";
        case GamepadButton.r1:
          return "\u{219D}";
        case GamepadButton.l2:
          return "\u{219A}";
        case GamepadButton.r2:
          return "\u{219B}";
        case GamepadButton.l3:
          return "\u{21BA}";
        case GamepadButton.r3:
          return "\u{21BB}";
        case GamepadButton.start:
          return "\u{21F8}";
        case GamepadButton.select:
          return "\u{21F7}";
        default:
          return "";
      }
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
        case GamepadButton.confirm:
          return swapConfirm ? "\u{21D2}" : "\u{21D3}";
        case GamepadButton.back:
          return swapConfirm ? "\u{21D3}" : "\u{21D2}";
        case GamepadButton.x:
          return "\u{21D0}";
        case GamepadButton.y:
          return "\u{21D1}";
        case GamepadButton.l1:
          return "\u{219C}";
        case GamepadButton.r1:
          return "\u{219D}";
        case GamepadButton.l2:
          return "\u{219A}";
        case GamepadButton.r2:
          return "\u{219B}";
        case GamepadButton.l3:
          return "\u{21BA}";
        case GamepadButton.r3:
          return "\u{21BB}";
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
        case GamepadButton.confirm:
          return swapConfirm ? "\u{21A6}" : "\u{21A7}";
        case GamepadButton.back:
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
        case GamepadButton.l3:
          return "\u{21BA}";
        case GamepadButton.r3:
          return "\u{21BB}";
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
        case GamepadButton.confirm:
          return swapConfirm ? "\u{21D2}" : "\u{21D3}";
        case GamepadButton.back:
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
        case GamepadButton.l3:
          return "\u{21BA}";
        case GamepadButton.r3:
          return "\u{21BB}";
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
  GamepadButton.confirm: "\u{21D3}",
  GamepadButton.back: "\u{21D2}",
  GamepadButton.x: "\u{21D0}",
  GamepadButton.y: "\u{21D1}",
  GamepadButton.l1: "\u{21B0}",
  GamepadButton.l2: "\u{21B2}",
  GamepadButton.l3: "\u{21BA}",
  GamepadButton.r1: "\u{21B1}",
  GamepadButton.r2: "\u{21B3}",
  GamepadButton.r3: "\u{21BB}",
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
    final controllerSettings = ref.watch(
      settingsProvider.select(
        (settings) => (
          layout: settings.value?.controllerLayout ?? ControllerLayout.retro,
          swapConfirm: settings.value?.swapConfirm ?? false,
        ),
      ),
    );
    final layout = controllerSettings.layout;
    final swapConfirm = controllerSettings.swapConfirm;

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
