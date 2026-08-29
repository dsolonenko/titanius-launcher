import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/widgets/prompt_dialog.dart';

void main() {
  testWidgets('prompt displays fullscreen dialog with title and initial value', (tester) async {
    String? result;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await prompt(
                    context,
                    title: const Text('RetroAchievements Username'),
                    initialValue: 'Scott',
                    isSelectedInitialValue: true,
                  );
                },
                child: const Text('Open Prompt'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Prompt'));
    await tester.pumpAndSettle();

    // Verify fullscreen Dialog is open
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('RetroAchievements Username'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Save'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Enter new text and submit
    await tester.enterText(find.byType(TextFormField), 'NewUser');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    // Verify dialog closed and returned result
    expect(find.byType(Dialog), findsNothing);
    expect(result, 'NewUser');
  });

  testWidgets('prompt cancels and returns null on close button tap', (tester) async {
    String? result = 'initial';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await prompt(
                    context,
                    title: const Text('Enter Key'),
                    initialValue: 'old_key',
                  );
                },
                child: const Text('Open Prompt'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Prompt'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(result, isNull);
  });
}
