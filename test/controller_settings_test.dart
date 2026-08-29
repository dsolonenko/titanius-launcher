import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/storage.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/pages/settings.dart';
import 'package:titanius/widgets/gamepad_prompt.dart';

void main() {
  group('ControllerLayout & Glyphs', () {
    test('ControllerLayout.fromString parses correctly with fallback to nintendo', () {
      expect(ControllerLayout.fromString('xbox'), ControllerLayout.xbox);
      expect(ControllerLayout.fromString('nintendo'), ControllerLayout.nintendo);
      expect(ControllerLayout.fromString('generic'), ControllerLayout.generic);
      expect(ControllerLayout.fromString('unknown'), ControllerLayout.nintendo);
      expect(ControllerLayout.fromString(null), ControllerLayout.nintendo);
    });

    test('Xbox glyphs map correctly with and without swapConfirm', () {
      // Normal Xbox: A is Confirm (Down), B is Back (Right), X is Left, Y is Up
      expect(getGamepadButtonGlyph(GamepadButton.a, ControllerLayout.xbox, false), '\u{21D3}'); // A
      expect(getGamepadButtonGlyph(GamepadButton.b, ControllerLayout.xbox, false), '\u{21D2}'); // B
      expect(getGamepadButtonGlyph(GamepadButton.x, ControllerLayout.xbox, false), '\u{21D0}'); // X
      expect(getGamepadButtonGlyph(GamepadButton.y, ControllerLayout.xbox, false), '\u{21D1}'); // Y
      expect(getGamepadButtonGlyph(GamepadButton.l1, ControllerLayout.xbox, false), '\u{21B0}'); // LB
      expect(getGamepadButtonGlyph(GamepadButton.r1, ControllerLayout.xbox, false), '\u{21B1}'); // RB
      expect(getGamepadButtonGlyph(GamepadButton.l2, ControllerLayout.xbox, false), '\u{21B2}'); // LT
      expect(getGamepadButtonGlyph(GamepadButton.r2, ControllerLayout.xbox, false), '\u{21B3}'); // RT

      // Swapped Xbox: Button A (Confirm) prompt shows B glyph, Button B (Back) prompt shows A glyph
      expect(getGamepadButtonGlyph(GamepadButton.a, ControllerLayout.xbox, true), '\u{21D2}'); // B
      expect(getGamepadButtonGlyph(GamepadButton.b, ControllerLayout.xbox, true), '\u{21D3}'); // A
    });

    test('Nintendo glyphs map correctly with and without swapConfirm', () {
      // Nintendo without swap: South button confirms (labeled B), East button backs (labeled A)
      expect(getGamepadButtonGlyph(GamepadButton.a, ControllerLayout.nintendo, false), '\u{21D2}'); // B
      expect(getGamepadButtonGlyph(GamepadButton.b, ControllerLayout.nintendo, false), '\u{21D3}'); // A
      expect(getGamepadButtonGlyph(GamepadButton.x, ControllerLayout.nintendo, false), '\u{21D1}'); // Y
      expect(getGamepadButtonGlyph(GamepadButton.y, ControllerLayout.nintendo, false), '\u{21D0}'); // X
      expect(getGamepadButtonGlyph(GamepadButton.l1, ControllerLayout.nintendo, false), '\u{219C}'); // L
      expect(getGamepadButtonGlyph(GamepadButton.r1, ControllerLayout.nintendo, false), '\u{219D}'); // R
      expect(getGamepadButtonGlyph(GamepadButton.l2, ControllerLayout.nintendo, false), '\u{219A}'); // ZL
      expect(getGamepadButtonGlyph(GamepadButton.r2, ControllerLayout.nintendo, false), '\u{219B}'); // ZR
      expect(getGamepadButtonGlyph(GamepadButton.start, ControllerLayout.nintendo, false), '\u{21FE}'); // +
      expect(getGamepadButtonGlyph(GamepadButton.select, ControllerLayout.nintendo, false), '\u{21FD}'); // -

      // Nintendo with swap (Nintendo standard: A confirms, B cancels)
      expect(getGamepadButtonGlyph(GamepadButton.a, ControllerLayout.nintendo, true), '\u{21D3}'); // A
      expect(getGamepadButtonGlyph(GamepadButton.b, ControllerLayout.nintendo, true), '\u{21D2}'); // B
    });

    test('Generic glyphs map correctly with and without swapConfirm', () {
      // Generic without swap: Down confirms, Right backs
      expect(getGamepadButtonGlyph(GamepadButton.a, ControllerLayout.generic, false), '\u{21A7}'); // Down
      expect(getGamepadButtonGlyph(GamepadButton.b, ControllerLayout.generic, false), '\u{21A6}'); // Right
      expect(getGamepadButtonGlyph(GamepadButton.x, ControllerLayout.generic, false), '\u{21A4}'); // Left
      expect(getGamepadButtonGlyph(GamepadButton.y, ControllerLayout.generic, false), '\u{21A5}'); // Up

      // Generic with swap: Right confirms, Down backs
      expect(getGamepadButtonGlyph(GamepadButton.a, ControllerLayout.generic, true), '\u{21A6}'); // Right
      expect(getGamepadButtonGlyph(GamepadButton.b, ControllerLayout.generic, true), '\u{21A7}'); // Down
    });
  });

  group('ControllerSettingsPage Widget Tests', () {
    testWidgets('renders controller layout and swap A/B toggle with Nintendo default', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: ControllerSettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Controller Settings'), findsOneWidget);
      expect(find.text('Controller Layout'), findsOneWidget);
      expect(find.text('Swap A/B for Confirm'), findsOneWidget);
      expect(find.text('Nintendo'), findsOneWidget);
      expect(find.text('Nintendo style: B / A / Y / X'), findsOneWidget);
      expect(find.text('B (South) confirms, A (East) cancels'), findsOneWidget);

      // Verify Diagram buttons and ActionChips are rendered
      expect(find.text('Confirm'), findsOneWidget); // Diagram action chip
      expect(find.text('Back'), findsNWidgets(2)); // Diagram chip + PromptBar

      // Tap to cycle layout to Xbox
      await tester.tap(find.text('Controller Layout'));
      await tester.pumpAndSettle();

      expect(find.text('Xbox'), findsOneWidget);
      expect(find.text('Xbox style: A / B / X / Y'), findsOneWidget);

      // Tap to cycle layout to Generic
      await tester.tap(find.text('Controller Layout'));
      await tester.pumpAndSettle();

      expect(find.text('Generic'), findsOneWidget);
      expect(find.text('Positional / directional button indicators'), findsOneWidget);

      // Tap to toggle Swap A/B
      await tester.tap(find.text('Swap A/B for Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('East button confirms, South button cancels'), findsOneWidget);
    });
  });
}
