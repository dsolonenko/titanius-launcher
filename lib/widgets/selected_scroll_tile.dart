import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

final Map<String, int> _rememberedSelections = <String, int>{};

/// Remembers controller selection independently of a route widget's lifetime.
/// PageStorage alone only remembers scroll offset, which lets the viewport and
/// the selected row disagree after returning from a child route.
ValueNotifier<int> usePersistentSelection(String key, {int initialIndex = 0}) {
  final selection = useState(_rememberedSelections[key] ?? initialIndex);
  useEffect(() {
    void remember() => _rememberedSelections[key] = selection.value;

    selection.addListener(remember);
    return () => selection.removeListener(remember);
  }, [selection, key]);
  return selection;
}

/// A virtualized list whose controller-selected row is always visible.
///
/// Scrolling intentionally jumps. Auto-repeat can change selection faster than
/// an animation completes, so animating each row makes the viewport fall behind.
class ControllerListView extends HookWidget {
  const ControllerListView.builder({
    super.key,
    required this.selectedIndex,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.initialAlignment = 0.15,
  });

  final int selectedIndex;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets? padding;
  final double initialAlignment;

  @override
  Widget build(BuildContext context) {
    final scrollController = useMemoized(ItemScrollController.new);
    final positionsListener = useMemoized(ItemPositionsListener.create);
    final safeIndex = itemCount == 0
        ? 0
        : selectedIndex.clamp(0, itemCount - 1);

    useEffect(() {
      if (itemCount == 0) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || !scrollController.isAttached) return;
        final positions = positionsListener.itemPositions.value;
        ItemPosition? selectedPosition;
        for (final position in positions) {
          if (position.index == safeIndex) {
            selectedPosition = position;
            break;
          }
        }
        final fullyVisible =
            selectedPosition != null &&
            selectedPosition.itemLeadingEdge >= 0 &&
            selectedPosition.itemTrailingEdge <= 1;
        if (!fullyVisible) {
          scrollController.jumpTo(
            index: safeIndex,
            alignment: initialAlignment,
          );
        }
      });
      return null;
    }, [safeIndex, itemCount]);

    return ScrollablePositionedList.builder(
      itemScrollController: scrollController,
      itemPositionsListener: positionsListener,
      initialScrollIndex: safeIndex,
      initialAlignment: initialAlignment,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Grouped controller list with stable element indexes. Element order is never
/// changed, so up/down selection and visual order cannot diverge.
class ControllerGroupedListView<T, G> extends StatelessWidget {
  const ControllerGroupedListView({
    super.key,
    required this.selectedIndex,
    required this.elements,
    required this.groupBy,
    required this.groupSeparatorBuilder,
    required this.indexedItemBuilder,
  });

  final int selectedIndex;
  final List<T> elements;
  final G Function(T element) groupBy;
  final Widget Function(G group) groupSeparatorBuilder;
  final Widget Function(BuildContext context, T element, int index)
  indexedItemBuilder;

  @override
  Widget build(BuildContext context) {
    final rows = <Object>[];
    var selectedRow = 0;
    G? previousGroup;
    var isFirst = true;
    for (var index = 0; index < elements.length; index++) {
      final element = elements[index];
      final group = groupBy(element);
      if (isFirst || group != previousGroup) {
        rows.add(_GroupHeader<G>(group));
        previousGroup = group;
        isFirst = false;
      }
      if (index == selectedIndex) selectedRow = rows.length;
      rows.add(_GroupItem<T>(element, index));
    }

    return ControllerListView.builder(
      selectedIndex: selectedRow,
      itemCount: rows.length,
      itemBuilder: (context, rowIndex) {
        final row = rows[rowIndex];
        if (row is _GroupHeader<G>) return groupSeparatorBuilder(row.group);
        final item = row as _GroupItem<T>;
        return indexedItemBuilder(context, item.element, item.index);
      },
    );
  }
}

/// A controller-first grid implemented as a positioned list of rows, so an
/// item outside GridView's build cache can still be revealed directly.
class ControllerGridView extends StatelessWidget {
  const ControllerGridView.builder({
    super.key,
    required this.selectedIndex,
    required this.itemCount,
    required this.itemBuilder,
    required this.maxCrossAxisExtent,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding = const EdgeInsets.all(12),
  });

  final int selectedIndex;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double maxCrossAxisExtent;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = padding.horizontal;
        final availableWidth = (constraints.maxWidth - horizontalPadding).clamp(0.0, double.infinity);
        final columnCount = (availableWidth / maxCrossAxisExtent).ceil().clamp(1, 20);
        final totalSpacing = crossAxisSpacing * (columnCount - 1);
        final cellWidth = (availableWidth - totalSpacing) / columnCount;
        final cellHeight = cellWidth / childAspectRatio;
        final rowCount = (itemCount / columnCount).ceil();
        final selectedRow = itemCount == 0
            ? 0
            : selectedIndex.clamp(0, itemCount - 1) ~/ columnCount;

        return ControllerListView.builder(
          padding: padding,
          selectedIndex: selectedRow,
          itemCount: rowCount,
          itemBuilder: (context, rowIndex) {
            return Container(
              margin: EdgeInsets.only(
                bottom: rowIndex < rowCount - 1 ? mainAxisSpacing : 0,
              ),
              height: cellHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(columnCount, (columnIndex) {
                  final itemIndex = rowIndex * columnCount + columnIndex;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: columnIndex < columnCount - 1 ? crossAxisSpacing : 0,
                      ),
                      child: itemIndex < itemCount
                          ? itemBuilder(context, itemIndex)
                          : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}

class _GroupHeader<G> {
  const _GroupHeader(this.group);
  final G group;
}

class _GroupItem<T> {
  const _GroupItem(this.element, this.index);
  final T element;
  final int index;
}

class SelectedScrollTile extends StatelessWidget {
  final bool isSelected;
  final Widget child;
  final double alignment;

  const SelectedScrollTile({
    super.key,
    required this.isSelected,
    required this.child,
    this.alignment = 0.5,
  });

  @override
  Widget build(BuildContext context) => child;
}
