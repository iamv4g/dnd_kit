import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:dnd_kit_sortable/dnd_kit_sortable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('performance smoke baseline', () {
    test('keeps sortable strategy computation within a smoke threshold', () {
      final itemIds = List<DndId>.generate(
        240,
        (index) => DndId('item-$index'),
      );
      final itemRects = <DndId, DndRect>{
        for (var index = 0; index < itemIds.length; index += 1)
          itemIds[index]: DndRect(
            left: 0,
            top: index * 44,
            width: 320,
            height: 40,
          ),
      };
      final event = DndDragEndEvent(
        session: DndDragSession.start(
          activeId: itemIds.first,
          initialPointer: const DndPoint(20, 20),
        ).moveTo(const DndPoint(20, 12000)),
        overId: itemIds.last,
      );
      final input = SortableStrategyInput(
        activeId: itemIds.first,
        overId: itemIds.last,
        itemIds: itemIds,
        itemRects: itemRects,
        fromIndex: 0,
        fromContainerId: const DndId('list'),
        toContainerId: const DndId('list'),
        event: event,
        activeRect: itemRects[itemIds.first],
        activeTranslatedRect: itemRects[itemIds.first]?.translate(
          event.session.transform.offset,
        ),
      );

      SortableMoveDetails? latestDetails;
      final stopwatch = Stopwatch()..start();
      for (var iteration = 0; iteration < 2000; iteration += 1) {
        latestDetails = SortableStrategies.verticalList(input);
      }
      stopwatch.stop();

      debugPrint(
        'US-034 sortable strategy baseline: '
        '${stopwatch.elapsedMilliseconds}ms for 2000 runs over '
        '${itemIds.length} items',
      );
      expect(latestDetails?.toIndex, itemIds.length - 1);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    testWidgets('keeps repeated sortable drag gestures within a smoke threshold', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = DndController();
      addTearDown(controller.dispose);
      final itemIds = List<DndId>.generate(
        24,
        (index) => DndId('item-$index'),
      );
      final moves = <SortableMoveDetails>[];

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          containerId: const DndId('list'),
          itemIds: itemIds,
          strategy: SortableStrategies.horizontalList,
          onMove: moves.add,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              for (var index = 0; index < itemIds.length; index += 1)
                Positioned(
                  left: 12 + index * 54,
                  top: 40,
                  child: SortableItem(
                    id: itemIds[index],
                    child: SizedBox(
                      width: 48,
                      height: 40,
                      child: Text(
                        itemIds[index].value,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      await tester.pump();

      final stopwatch = Stopwatch()..start();
      for (var index = 0; index < 12; index += 1) {
        await tester.dragFrom(
          Offset(36 + index * 54, 60),
          const Offset(108, 0),
        );
        await tester.pump();
      }
      stopwatch.stop();

      debugPrint(
        'US-034 sortable widget drag baseline: '
        '${stopwatch.elapsedMilliseconds}ms for 12 drag gestures over '
        '${itemIds.length} items',
      );
      expect(moves, hasLength(12));
      expect(moves.last.toIndex, 12);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });
}
