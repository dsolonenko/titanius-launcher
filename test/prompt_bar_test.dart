import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/repo.dart' hide isNull;
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/prompt_bar.dart';

void main() {
  testWidgets('game hints wrap without overflowing at maximum font scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWithValue(AsyncData(Settings({}))),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(960, 720),
              textScaler: TextScaler.linear(3),
            ),
            child: Scaffold(
              bottomNavigationBar: PromptBar(
                text: 'Filter: All games in the current folder',
                navigations: [
                  GamepadPrompt([GamepadButton.l1, GamepadButton.r1], 'Scroll'),
                  GamepadPrompt([GamepadButton.l2, GamepadButton.r2], 'System'),
                  GamepadPrompt([GamepadButton.select], 'Filter'),
                  GamepadPrompt([GamepadButton.start], 'Menu'),
                ],
                actions: [
                  GamepadPrompt([GamepadButton.x], 'Details'),
                  GamepadPrompt([GamepadButton.y], 'Settings'),
                  GamepadPrompt([GamepadButton.back], 'Back'),
                  GamepadPrompt([GamepadButton.confirm], 'Launch'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Scroll'), findsWidgets);
    expect(find.text('Launch'), findsWidgets);
  });

  testWidgets('a long settings hint remains attached to its button', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWithValue(AsyncData(Settings({}))),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(960, 720),
              textScaler: TextScaler.linear(3),
            ),
            child: Scaffold(
              bottomNavigationBar: PromptBar(
                actions: [
                  GamepadPrompt([GamepadButton.confirm], 'Apply'),
                  GamepadPrompt([GamepadButton.x], 'Do not use wallpapers'),
                  GamepadPrompt([GamepadButton.back], 'Back'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Do not use wallpapers'), findsWidgets);
  });
}
