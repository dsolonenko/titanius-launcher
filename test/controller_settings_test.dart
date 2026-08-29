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
    test(
      'ControllerLayout.fromString parses correctly with fallback to retro',
      () {
        expect(ControllerLayout.fromString('retro'), ControllerLayout.retro);
        expect(ControllerLayout.fromString('xbox'), ControllerLayout.xbox);
        expect(
          ControllerLayout.fromString('nintendo'),
          ControllerLayout.nintendo,
        );
        expect(
          ControllerLayout.fromString('generic'),
          ControllerLayout.generic,
        );
        expect(ControllerLayout.fromString('unknown'), ControllerLayout.retro);
        expect(ControllerLayout.fromString(null), ControllerLayout.retro);
      },
    );

    test('Retro uses printed face labels and regular Start/Select glyphs', () {
      expect(
        confirmButtonPosition(ControllerLayout.retro, false),
        FaceButtonPosition.east,
      );
      expect(
        getGamepadButtonGlyph(
          GamepadButton.confirm,
          ControllerLayout.retro,
          false,
        ),
        '\u{21D3}',
      ); // A
      expect(
        getGamepadButtonGlyph(
          GamepadButton.back,
          ControllerLayout.retro,
          false,
        ),
        '\u{21D2}',
      ); // B
      expect(
        getGamepadButtonGlyph(GamepadButton.x, ControllerLayout.retro, false),
        '\u{21D0}',
      ); // X
      expect(
        getGamepadButtonGlyph(GamepadButton.y, ControllerLayout.retro, false),
        '\u{21D1}',
      ); // Y
      expect(
        getGamepadButtonGlyph(
          GamepadButton.start,
          ControllerLayout.retro,
          false,
        ),
        '\u{21F8}',
      );
      expect(
        getGamepadButtonGlyph(
          GamepadButton.select,
          ControllerLayout.retro,
          false,
        ),
        '\u{21F7}',
      );
    });

    test('Xbox labeled input actions and glyphs follow its layout', () {
      expect(
        mapLabeledFaceButton(FaceButtonLabel.a, false),
        GamepadButton.confirm,
      );
      expect(
        mapLabeledFaceButton(FaceButtonLabel.b, false),
        GamepadButton.back,
      );
      expect(
        confirmButtonPosition(ControllerLayout.xbox, false),
        FaceButtonPosition.south,
      );
      expect(
        getGamepadButtonGlyph(
          GamepadButton.confirm,
          ControllerLayout.xbox,
          false,
        ),
        '\u{21D3}',
      ); // A
      expect(
        getGamepadButtonGlyph(GamepadButton.back, ControllerLayout.xbox, false),
        '\u{21D2}',
      ); // B
      expect(
        getGamepadButtonGlyph(GamepadButton.x, ControllerLayout.xbox, false),
        '\u{21D0}',
      ); // X
      expect(
        getGamepadButtonGlyph(GamepadButton.y, ControllerLayout.xbox, false),
        '\u{21D1}',
      ); // Y
      expect(
        getGamepadButtonGlyph(GamepadButton.l1, ControllerLayout.xbox, false),
        '\u{21B0}',
      ); // LB
      expect(
        getGamepadButtonGlyph(GamepadButton.r1, ControllerLayout.xbox, false),
        '\u{21B1}',
      ); // RB
      expect(
        getGamepadButtonGlyph(GamepadButton.l2, ControllerLayout.xbox, false),
        '\u{21B2}',
      ); // LT
      expect(
        getGamepadButtonGlyph(GamepadButton.r2, ControllerLayout.xbox, false),
        '\u{21B3}',
      ); // RT

      expect(
        mapLabeledFaceButton(FaceButtonLabel.b, true),
        GamepadButton.confirm,
      );
      expect(
        confirmButtonPosition(ControllerLayout.xbox, true),
        FaceButtonPosition.east,
      );
      expect(
        getGamepadButtonGlyph(
          GamepadButton.confirm,
          ControllerLayout.xbox,
          true,
        ),
        '\u{21D2}',
      ); // B
      expect(
        getGamepadButtonGlyph(GamepadButton.back, ControllerLayout.xbox, true),
        '\u{21D3}',
      ); // A
    });

    test('Nintendo labeled input actions and glyphs follow its layout', () {
      // Nintendo defaults to its labeled A (East) for confirm and B (South) for back.
      expect(
        mapLabeledFaceButton(FaceButtonLabel.a, false),
        GamepadButton.confirm,
      );
      expect(
        mapLabeledFaceButton(FaceButtonLabel.b, false),
        GamepadButton.back,
      );
      expect(
        confirmButtonPosition(ControllerLayout.nintendo, false),
        FaceButtonPosition.east,
      );
      expect(
        getGamepadButtonGlyph(
          GamepadButton.confirm,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{21D3}',
      ); // A
      expect(
        getGamepadButtonGlyph(
          GamepadButton.back,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{21D2}',
      ); // B
      // Android delivers the RG406V face buttons by their printed key labels.
      expect(mapLabeledFaceButton(FaceButtonLabel.x, false), GamepadButton.x);
      expect(mapLabeledFaceButton(FaceButtonLabel.y, false), GamepadButton.y);
      expect(
        getGamepadButtonGlyph(
          GamepadButton.x,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{21D0}',
      ); // X
      expect(
        getGamepadButtonGlyph(
          GamepadButton.y,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{21D1}',
      ); // Y
      expect(
        getGamepadButtonGlyph(
          GamepadButton.l1,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{219C}',
      ); // L
      expect(
        getGamepadButtonGlyph(
          GamepadButton.r1,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{219D}',
      ); // R
      expect(
        getGamepadButtonGlyph(
          GamepadButton.l2,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{219A}',
      ); // ZL
      expect(
        getGamepadButtonGlyph(
          GamepadButton.r2,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{219B}',
      ); // ZR
      expect(
        getGamepadButtonGlyph(
          GamepadButton.start,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{21FE}',
      ); // +
      expect(
        getGamepadButtonGlyph(
          GamepadButton.select,
          ControllerLayout.nintendo,
          false,
        ),
        '\u{21FD}',
      ); // -

      // Swap reverses Nintendo's default, making B (South) confirm.
      expect(
        mapLabeledFaceButton(FaceButtonLabel.b, true),
        GamepadButton.confirm,
      );
      expect(
        confirmButtonPosition(ControllerLayout.nintendo, true),
        FaceButtonPosition.south,
      );
      expect(
        getGamepadButtonGlyph(
          GamepadButton.confirm,
          ControllerLayout.nintendo,
          true,
        ),
        '\u{21D2}',
      ); // B
      expect(
        getGamepadButtonGlyph(
          GamepadButton.back,
          ControllerLayout.nintendo,
          true,
        ),
        '\u{21D3}',
      ); // A
    });

    test('Generic glyphs map correctly with and without swapConfirm', () {
      // Generic without swap: Down confirms, Right backs
      expect(
        getGamepadButtonGlyph(
          GamepadButton.confirm,
          ControllerLayout.generic,
          false,
        ),
        '\u{21A7}',
      ); // Down
      expect(
        getGamepadButtonGlyph(
          GamepadButton.back,
          ControllerLayout.generic,
          false,
        ),
        '\u{21A6}',
      ); // Right
      expect(
        getGamepadButtonGlyph(GamepadButton.x, ControllerLayout.generic, false),
        '\u{21A4}',
      ); // Left
      expect(
        getGamepadButtonGlyph(GamepadButton.y, ControllerLayout.generic, false),
        '\u{21A5}',
      ); // Up

      // Generic with swap: Right confirms, Down backs
      expect(
        getGamepadButtonGlyph(
          GamepadButton.confirm,
          ControllerLayout.generic,
          true,
        ),
        '\u{21A6}',
      ); // Right
      expect(
        getGamepadButtonGlyph(
          GamepadButton.back,
          ControllerLayout.generic,
          true,
        ),
        '\u{21A7}',
      ); // Down
    });
  });

  group('ControllerSettingsPage Widget Tests', () {
    testWidgets(
      'renders controller layout and swap A/B toggle with Retro default',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(home: ControllerSettingsPage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Controller Settings'), findsOneWidget);
        expect(find.text('Controller Layout'), findsOneWidget);
        expect(find.text('Swap A/B for Confirm'), findsOneWidget);
        expect(find.text('Retro'), findsOneWidget);
        expect(find.text('Retro style: B / A / Y / X'), findsOneWidget);
        expect(
          find.text('A (East) confirms, B (South) goes back'),
          findsOneWidget,
        );

        // Verify Diagram buttons and ActionChips are rendered
        expect(find.text('Confirm'), findsOneWidget); // Diagram action chip
        expect(find.text('Back'), findsNWidgets(2)); // Diagram chip + PromptBar

        // Tap to cycle layout to Nintendo.
        await tester.tap(find.text('Controller Layout'));
        await tester.pumpAndSettle();

        expect(find.text('Nintendo'), findsOneWidget);
        expect(find.text('Nintendo style: B / A / Y / X'), findsOneWidget);

        // Rapid selections are queued from the latest requested value rather
        // than both reading the same stale provider state.
        await tester.tap(find.text('Controller Layout'));
        await tester.tap(find.text('Controller Layout'));
        await tester.pumpAndSettle();

        expect(find.text('Generic'), findsOneWidget);

        // Tap to toggle Swap A/B
        await tester.tap(find.text('Swap A/B for Confirm'));
        await tester.pumpAndSettle();

        expect(
          find.text('East button confirms, South button goes back'),
          findsOneWidget,
        );
      },
    );
  });
}
