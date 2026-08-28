import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/widgets/selected_scroll_tile.dart';

void main() {
  testWidgets('a selection jump reveals an item outside the build cache', (
    tester,
  ) async {
    final selected = ValueNotifier<int>(0);
    addTearDown(selected.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 240,
          child: ValueListenableBuilder<int>(
            valueListenable: selected,
            builder: (context, index, _) {
              return ControllerListView.builder(
                selectedIndex: index,
                itemCount: 200,
                itemBuilder: (context, itemIndex) => SizedBox(
                  key: ValueKey('item-$itemIndex'),
                  height: 48,
                  child: Text('Item $itemIndex'),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('item-150')), findsNothing);
    selected.value = 150;
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('item-150')), findsOneWidget);
  });

  testWidgets('selection survives disposal and recreation of a route widget', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _PersistenceHarness()));

    expect(find.text('Selected 0'), findsOneWidget);
    await tester.tap(find.text('Select 37'));
    await tester.pump();
    expect(find.text('Selected 37'), findsOneWidget);

    await tester.tap(find.text('Hide'));
    await tester.pump();
    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(find.text('Selected 37'), findsOneWidget);
  });
}

class _PersistenceHarness extends StatefulWidget {
  const _PersistenceHarness();

  @override
  State<_PersistenceHarness> createState() => _PersistenceHarnessState();
}

class _PersistenceHarnessState extends State<_PersistenceHarness> {
  bool visible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => setState(() => visible = !visible),
          child: Text(visible ? 'Hide' : 'Show'),
        ),
        if (visible) const _PersistentSelection(),
      ],
    );
  }
}

class _PersistentSelection extends HookWidget {
  const _PersistentSelection();

  @override
  Widget build(BuildContext context) {
    final selected = usePersistentSelection('controller-navigation-test');
    return Column(
      children: [
        Text('Selected ${selected.value}'),
        TextButton(
          onPressed: () => selected.value = 37,
          child: const Text('Select 37'),
        ),
      ],
    );
  }
}
