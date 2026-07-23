import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Sortables inside a CustomScrollView / slivers. Without re-measuring on drag
// start, a drag begun after scrolling would aim at stale (pre-scroll) target
// positions, so the drop would resolve to the wrong item. These tests scroll
// first, then drop, and assert the move lands on the target actually under the
// pointer.
void main() {
  group('Sortable inside CustomScrollView', () {
    testWidgets('single-container drop lands on the correct target after scrolling',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final order = <DndId>[for (var i = 0; i < 12; i += 1) DndId('item-$i')];
      SortableMoveDetails? move;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SortableScope(
              itemIds: order,
              strategy: SortableStrategies.dropOnOver,
              onMove: (m) => move = m,
              child: CustomScrollView(
                controller: scrollController,
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => SortableItem(
                        id: order[i],
                        child: SizedBox(
                          key: ValueKey<String>(order[i].value),
                          height: 60,
                          child: Center(child: Text(order[i].value)),
                        ),
                      ),
                      childCount: order.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Scroll four 60px items off the top; item-4..item-8 become visible.
      scrollController.jumpTo(240);
      await tester.pump();

      final from = find.byKey(const ValueKey<String>('item-5'));
      final to = find.byKey(const ValueKey<String>('item-7'));
      final gesture = await tester.startGesture(
        tester.getCenter(from),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(to));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(move?.activeId, const DndId('item-5'));
      expect(
        move?.overId,
        const DndId('item-7'),
        reason: 'the drop must resolve to the post-scroll target under the pointer',
      );
    });

    testWidgets('cross-section drop resolves after scrolling slivers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      // Two sections stacked vertically in one CustomScrollView.
      final sectionA = <DndId>[for (var i = 0; i < 5; i += 1) DndId('a$i')];
      final sectionB = <DndId>[for (var i = 0; i < 5; i += 1) DndId('b$i')];
      final containers = <SortableContainer>[
        SortableContainer(id: const DndId('A'), itemIds: sectionA),
        SortableContainer(id: const DndId('B'), itemIds: sectionB),
      ];
      SortableMoveDetails? move;

      Widget section(DndId id, List<DndId> ids) {
        return SortableMultiContainerArea(
          id: id,
          itemIds: ids,
          strategy: SortableStrategies.dropOnOver,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final itemId in ids)
                SortableMultiItem(
                  id: itemId,
                  child: SizedBox(
                    key: ValueKey<String>(itemId.value),
                    height: 60,
                    width: 400,
                    child: Center(child: Text(itemId.value)),
                  ),
                ),
            ],
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SortableMultiScope(
              containers: containers,
              onMove: (m) => move = m,
              child: CustomScrollView(
                controller: scrollController,
                slivers: <Widget>[
                  SliverToBoxAdapter(child: section(const DndId('A'), sectionA)),
                  SliverToBoxAdapter(child: section(const DndId('B'), sectionB)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Section A is 5*60=300 tall; scroll so a4 and section B's top show.
      scrollController.jumpTo(180);
      await tester.pump();

      final from = find.byKey(const ValueKey<String>('a4'));
      final to = find.byKey(const ValueKey<String>('b1'));
      final gesture = await tester.startGesture(
        tester.getCenter(from),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(to));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(move?.activeId, const DndId('a4'));
      expect(move?.fromContainerId, const DndId('A'));
      expect(
        move?.toContainerId,
        const DndId('B'),
        reason: 'the cross-section drop must resolve to section B after scrolling',
      );
    });
  });
}
