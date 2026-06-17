import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('SortableStrategies.verticalList', () {
    test('computes new index from the active translated center', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-3'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 126),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
            const DndId('item-3'): _rect(top: 120),
          },
        ),
      );

      expect(details?.activeId, const DndId('item-1'));
      expect(details?.overId, const DndId('item-3'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 2);
    });

    test('supports moving upward before earlier measured items', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-3'),
          overId: const DndId('item-1'),
          fromIndex: 2,
          activeTranslatedRect: _rect(top: -20),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
            const DndId('item-3'): _rect(top: 120),
          },
        ),
      );

      expect(details?.fromIndex, 2);
      expect(details?.toIndex, 0);
    });

    test('uses measured centers for a two item vertical list', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          activeTranslatedRect: _rect(top: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('falls back to drop-over index when measurements are incomplete', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-3'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 126),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
          },
        ),
      );

      expect(details?.toIndex, 2);
    });

    test('falls back to drop-over index for non-vertical layouts', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 0, left: 100),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 100),
            const DndId('item-3'): _rect(top: 0, left: 200),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('does not report same-item moves or mutate item order', () {
      final itemIds = <DndId>[
        const DndId('item-1'),
        const DndId('item-2'),
        const DndId('item-3'),
      ];

      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-1'),
          fromIndex: 0,
          itemIds: itemIds,
          activeTranslatedRect: _rect(top: 60),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
            const DndId('item-3'): _rect(top: 120),
          },
        ),
      );

      expect(details, isNull);
      expect(
        itemIds,
        const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
      );
    });
  });

  group('SortableStrategies.horizontalList', () {
    test('computes new index from the active translated center', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-3'),
          fromIndex: 0,
          activeTranslatedRect: _rect(left: 126),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
            const DndId('item-3'): _rect(left: 120),
          },
        ),
      );

      expect(details?.activeId, const DndId('item-1'));
      expect(details?.overId, const DndId('item-3'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 2);
    });

    test('supports moving left before earlier measured items', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-3'),
          overId: const DndId('item-1'),
          fromIndex: 2,
          activeTranslatedRect: _rect(left: -20),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
            const DndId('item-3'): _rect(left: 120),
          },
        ),
      );

      expect(details?.fromIndex, 2);
      expect(details?.toIndex, 0);
    });

    test('uses measured centers for a two item horizontal list', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          activeTranslatedRect: _rect(left: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('falls back to drop-over index when measurements are incomplete', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-3'),
          fromIndex: 0,
          activeTranslatedRect: _rect(left: 126),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
          },
        ),
      );

      expect(details?.toIndex, 2);
    });

    test('falls back to drop-over index for non-horizontal layouts', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 100),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 100),
            const DndId('item-3'): _rect(top: 200),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('does not report same-item moves or mutate item order', () {
      final itemIds = <DndId>[
        const DndId('item-1'),
        const DndId('item-2'),
        const DndId('item-3'),
      ];

      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-1'),
          fromIndex: 0,
          itemIds: itemIds,
          activeTranslatedRect: _rect(left: 60),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
            const DndId('item-3'): _rect(left: 120),
          },
        ),
      );

      expect(details, isNull);
      expect(
        itemIds,
        const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
      );
    });
  });

  group('SortableStrategies.grid', () {
    test('computes new index from the active translated center in row-major order', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-4'),
          fromIndex: 0,
          itemIds: const <DndId>[
            DndId('item-1'),
            DndId('item-2'),
            DndId('item-3'),
            DndId('item-4'),
          ],
          activeTranslatedRect: _rect(top: 81, left: 81),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
            const DndId('item-4'): _rect(top: 80, left: 80),
          },
        ),
      );

      expect(details?.activeId, const DndId('item-1'));
      expect(details?.overId, const DndId('item-4'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 3);
    });

    test('supports moving upward before earlier measured rows', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-4'),
          overId: const DndId('item-1'),
          fromIndex: 3,
          itemIds: const <DndId>[
            DndId('item-1'),
            DndId('item-2'),
            DndId('item-3'),
            DndId('item-4'),
          ],
          activeTranslatedRect: _rect(top: -80, left: -80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
            const DndId('item-4'): _rect(top: 80, left: 80),
          },
        ),
      );

      expect(details?.fromIndex, 3);
      expect(details?.toIndex, 0);
    });

    test('uses measured centers within the same row', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          itemIds: const <DndId>[
            DndId('item-1'),
            DndId('item-2'),
            DndId('item-3'),
            DndId('item-4'),
          ],
          activeTranslatedRect: _rect(left: 81),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
            const DndId('item-4'): _rect(top: 80, left: 80),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('falls back to drop-over index when measurements are incomplete', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-4'),
          fromIndex: 0,
          itemIds: const <DndId>[
            DndId('item-1'),
            DndId('item-2'),
            DndId('item-3'),
            DndId('item-4'),
          ],
          activeTranslatedRect: _rect(top: 80, left: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
          },
        ),
      );

      expect(details?.toIndex, 3);
    });

    test('falls back to drop-over index for non-grid layouts', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 0, left: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 0, left: 160),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('does not report same-item moves or mutate item order', () {
      final itemIds = <DndId>[
        const DndId('item-1'),
        const DndId('item-2'),
        const DndId('item-3'),
        const DndId('item-4'),
      ];

      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-1'),
          fromIndex: 0,
          itemIds: itemIds,
          activeTranslatedRect: _rect(top: 80, left: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
            const DndId('item-4'): _rect(top: 80, left: 80),
          },
        ),
      );

      expect(details, isNull);
      expect(
        itemIds,
        const <DndId>[
          DndId('item-1'),
          DndId('item-2'),
          DndId('item-3'),
          DndId('item-4'),
        ],
      );
    });
  });
}

SortableStrategyInput _input({
  required DndId activeId,
  required DndId? overId,
  required int fromIndex,
  required Map<DndId, DndRect> itemRects,
  required DndRect activeTranslatedRect,
  Iterable<DndId> itemIds = const <DndId>[
    DndId('item-1'),
    DndId('item-2'),
    DndId('item-3'),
  ],
}) {
  return SortableStrategyInput(
    activeId: activeId,
    overId: overId,
    itemIds: itemIds,
    itemRects: itemRects,
    fromIndex: fromIndex,
    fromContainerId: const DndId('list-1'),
    toContainerId: const DndId('list-1'),
    event: DndDragEndEvent(
      session: DndDragSession.start(
        activeId: activeId,
        initialPointer: DndPoint.zero,
      ),
      overId: overId,
    ),
    activeRect: itemRects[activeId],
    activeTranslatedRect: activeTranslatedRect,
  );
}

DndRect _rect({
  double top = 0,
  double left = 0,
}) {
  return DndRect(left: left, top: top, width: 50, height: 50);
}
