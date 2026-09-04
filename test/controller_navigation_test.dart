import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/widgets/selected_scroll_tile.dart';

void main() {
  testWidgets('controller lists place their first row at the top', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            height: 240,
            child: ControllerListView.builder(
              selectedIndex: 0,
              itemCount: 3,
              itemBuilder: (context, index) => SizedBox(
                key: ValueKey('top-item-$index'),
                height: 48,
                child: Text('Top item $index'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final listTop = tester.getTopLeft(find.byType(ControllerListView)).dy;
    final firstItemTop = tester
        .getTopLeft(find.byKey(const ValueKey('top-item-0')))
        .dy;
    expect(firstItemTop, listTop);
  });

  testWidgets('sequential navigation reveals the last row without animation', (
    tester,
  ) async {
    final selected = ValueNotifier<int>(0);
    addTearDown(selected.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            height: 192,
            child: ValueListenableBuilder<int>(
              valueListenable: selected,
              builder: (context, index, _) => ControllerListView.builder(
                selectedIndex: index,
                itemCount: 8,
                itemBuilder: (context, itemIndex) => SizedBox(
                  key: ValueKey('edge-item-$itemIndex'),
                  height: 48,
                  child: Text('Edge item $itemIndex'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (var index = 1; index < 8; index++) {
      selected.value = index;
      await tester.pump();
      await tester.pump();
    }

    final listBottom = tester.getBottomLeft(find.byType(ControllerListView)).dy;
    final lastItemBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('edge-item-7')))
        .dy;
    expect(lastItemBottom, lessThanOrEqualTo(listBottom + 0.001));
    expect(tester.hasRunningAnimations, isFalse);
  });

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

  testWidgets(
    'controller grouped lists show the first group header at the top initially and when scrolling up',
    (tester) async {
      final selected = ValueNotifier<int>(0);
      addTearDown(selected.dispose);

      final elements = List.generate(
        10,
        (i) => i < 5 ? 'Built-In $i' : 'Daijisho $i',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 320,
              height: 200,
              child: ValueListenableBuilder<int>(
                valueListenable: selected,
                builder: (context, index, _) =>
                    ControllerGroupedListView<String, String>(
                      selectedIndex: index,
                      elements: elements,
                      groupBy: (element) => element.startsWith('Built-In')
                          ? 'Built-In'
                          : 'Daijishō',
                      groupSeparatorBuilder: (group) => SizedBox(
                        key: ValueKey('header-$group'),
                        height: 30,
                        child: Text(group),
                      ),
                      indexedItemBuilder: (context, item, itemIndex) =>
                          SizedBox(
                            key: ValueKey('item-$itemIndex'),
                            height: 40,
                            child: Text(item),
                          ),
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final listTop = tester.getTopLeft(find.byType(ControllerListView)).dy;
      final headerTop = tester
          .getTopLeft(find.byKey(const ValueKey('header-Built-In')))
          .dy;
      expect(headerTop, listTop);

      // Navigate down into Daijisho
      for (var i = 1; i <= 6; i++) {
        selected.value = i;
        await tester.pump();
        await tester.pump();
      }

      // Now navigate back up to the first item (0)
      for (var i = 5; i >= 0; i--) {
        selected.value = i;
        await tester.pump();
        await tester.pump();
      }

      final headerTopAfterScrollUp = tester
          .getTopLeft(find.byKey(const ValueKey('header-Built-In')))
          .dy;
      expect(headerTopAfterScrollUp, listTop);
    },
  );
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
