import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('SortableOffsets.none', () {
    test('never moves anything', () {
      expect(
        SortableOffsets.none(
          _input(fromIndex: 0, toIndex: 2, rects: _uniformRects()),
        ),
        isEmpty,
      );
    });
  });

  group('SortableOffsets.verticalList', () {
    test('shifts the displaced items up when moving down', () {
      final offsets = SortableOffsets.verticalList(
        _input(fromIndex: 0, toIndex: 2, rects: _uniformRects()),
      );

      // item-1 moves to index 2, so item-2 and item-3 each rise one slot.
      expect(offsets, <DndId, DndPoint>{
        const DndId('item-2'): const DndPoint(0, -40),
        const DndId('item-3'): const DndPoint(0, -40),
      });
    });

    test('shifts the displaced items down when moving up', () {
      final offsets = SortableOffsets.verticalList(
        _input(fromIndex: 2, toIndex: 0, rects: _uniformRects()),
      );

      expect(offsets, <DndId, DndPoint>{
        const DndId('item-1'): const DndPoint(0, 40),
        const DndId('item-2'): const DndPoint(0, 40),
      });
    });

    test('leaves items outside the moved range alone', () {
      final offsets = SortableOffsets.verticalList(
        _input(
          fromIndex: 0,
          toIndex: 1,
          rects: _uniformRects(),
        ),
      );

      expect(offsets.keys, <DndId>[const DndId('item-2')]);
    });

    test('reports nothing when the preview would not move the item', () {
      expect(
        SortableOffsets.verticalList(
          _input(fromIndex: 1, toIndex: 1, rects: _uniformRects()),
        ),
        isEmpty,
      );
    });

    test('includes the list gap so the opened space matches the dragged item', () {
      // 40 tall with a 10 gap: tops at 0, 50, 100.
      final rects = <DndId, DndRect>{
        const DndId('item-1'): const DndRect(left: 0, top: 0, width: 100, height: 40),
        const DndId('item-2'): const DndRect(left: 0, top: 50, width: 100, height: 40),
        const DndId('item-3'): const DndRect(left: 0, top: 100, width: 100, height: 40),
      };

      final offsets = SortableOffsets.verticalList(
        _input(fromIndex: 0, toIndex: 2, rects: rects),
      );

      expect(offsets[const DndId('item-2')], const DndPoint(0, -50));
      expect(offsets[const DndId('item-3')], const DndPoint(0, -50));
    });

    test('moves displaced items by the dragged extent, not their own', () {
      // A tall item dragged past two short ones: both shorts rise by 100.
      final rects = <DndId, DndRect>{
        const DndId('item-1'): const DndRect(left: 0, top: 0, width: 100, height: 100),
        const DndId('item-2'): const DndRect(left: 0, top: 100, width: 100, height: 40),
        const DndId('item-3'): const DndRect(left: 0, top: 140, width: 100, height: 40),
      };

      final offsets = SortableOffsets.verticalList(
        _input(fromIndex: 0, toIndex: 2, rects: rects),
      );

      expect(offsets[const DndId('item-2')], const DndPoint(0, -100));
      expect(offsets[const DndId('item-3')], const DndPoint(0, -100));
    });

    test('offsets a displaced item that has not been measured', () {
      // Lazy list: item-3 is off-screen, but its offset does not depend on its
      // own rect, so it is still correct once it scrolls in.
      final rects = <DndId, DndRect>{
        const DndId('item-1'): const DndRect(left: 0, top: 0, width: 100, height: 40),
        const DndId('item-2'): const DndRect(left: 0, top: 40, width: 100, height: 40),
      };

      final offsets = SortableOffsets.verticalList(
        _input(fromIndex: 0, toIndex: 2, rects: rects),
      );

      expect(offsets[const DndId('item-3')], const DndPoint(0, -40));
    });

    test('reports nothing when the dragged item has no measured rect', () {
      final rects = <DndId, DndRect>{
        const DndId('item-2'): const DndRect(left: 0, top: 40, width: 100, height: 40),
      };

      expect(
        SortableOffsets.verticalList(
          _input(fromIndex: 0, toIndex: 2, rects: rects),
        ),
        isEmpty,
        reason: 'the dragged extent sets every offset, so guessing it would misplace all of them',
      );
    });

    test('reports nothing for out-of-range indices', () {
      expect(
        SortableOffsets.verticalList(
          _input(fromIndex: 0, toIndex: 9, rects: _uniformRects()),
        ),
        isEmpty,
      );
      expect(
        SortableOffsets.verticalList(
          _input(fromIndex: -1, toIndex: 1, rects: _uniformRects()),
        ),
        isEmpty,
      );
    });

    test('returns an unmodifiable map', () {
      final offsets = SortableOffsets.verticalList(
        _input(fromIndex: 0, toIndex: 2, rects: _uniformRects()),
      );

      expect(
        () => offsets[const DndId('item-9')] = DndPoint.zero,
        throwsUnsupportedError,
      );
    });
  });

  group('SortableOffsets fed by a strategy', () {
    test('uses the strategy toIndex in remove-then-insert space', () {
      const itemIds = <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')];
      final rects = _uniformRects();
      final session = DndDragSession.start(
        activeId: const DndId('item-1'),
        initialPointer: DndPoint.zero,
      );

      // Dragged past item-2's center but not item-3's, so the strategy resolves
      // the order [item-2, item-1, item-3].
      final details = SortableStrategies.verticalList(
        SortableStrategyInput(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          itemIds: itemIds,
          itemRects: rects,
          fromIndex: 0,
          fromContainerId: const DndId('list'),
          toContainerId: const DndId('list'),
          context: SortableDragContext.preview(
            session: session,
            overId: const DndId('item-2'),
          ),
          activeRect: rects[const DndId('item-1')],
          activeTranslatedRect: const DndRect(left: 0, top: 70, width: 100, height: 40),
        ),
      );

      expect(details?.toIndex, 1);

      final offsets = SortableOffsets.verticalList(
        SortableOffsetInput(
          activeId: const DndId('item-1'),
          itemIds: itemIds,
          itemRects: rects,
          fromIndex: details!.fromIndex,
          toIndex: details.toIndex,
        ),
      );

      // Only item-2 moves; item-3 keeps its slot, which is what the committed
      // order [item-2, item-1, item-3] produces.
      expect(offsets, <DndId, DndPoint>{const DndId('item-2'): const DndPoint(0, -40)});
    });
  });

  group('SortableOffsets.horizontalList', () {
    test('shifts along the x axis', () {
      final rects = <DndId, DndRect>{
        const DndId('item-1'): const DndRect(left: 0, top: 0, width: 60, height: 40),
        const DndId('item-2'): const DndRect(left: 60, top: 0, width: 60, height: 40),
        const DndId('item-3'): const DndRect(left: 120, top: 0, width: 60, height: 40),
      };

      final forward = SortableOffsets.horizontalList(
        _input(fromIndex: 0, toIndex: 2, rects: rects),
      );
      final backward = SortableOffsets.horizontalList(
        _input(fromIndex: 2, toIndex: 0, rects: rects),
      );

      expect(forward[const DndId('item-2')], const DndPoint(-60, 0));
      expect(backward[const DndId('item-1')], const DndPoint(60, 0));
    });

    test('includes the row gap', () {
      final rects = <DndId, DndRect>{
        const DndId('item-1'): const DndRect(left: 0, top: 0, width: 60, height: 40),
        const DndId('item-2'): const DndRect(left: 70, top: 0, width: 60, height: 40),
        const DndId('item-3'): const DndRect(left: 140, top: 0, width: 60, height: 40),
      };

      final offsets = SortableOffsets.horizontalList(
        _input(fromIndex: 0, toIndex: 1, rects: rects),
      );

      expect(offsets[const DndId('item-2')], const DndPoint(-70, 0));
    });
  });
}

SortableOffsetInput _input({
  required int fromIndex,
  required int toIndex,
  required Map<DndId, DndRect> rects,
  Iterable<DndId> itemIds = const <DndId>[
    DndId('item-1'),
    DndId('item-2'),
    DndId('item-3'),
  ],
}) {
  return SortableOffsetInput(
    activeId: itemIds.elementAt(fromIndex < 0 ? 0 : fromIndex.clamp(0, itemIds.length - 1)),
    itemIds: itemIds,
    itemRects: rects,
    fromIndex: fromIndex,
    toIndex: toIndex,
  );
}

Map<DndId, DndRect> _uniformRects() {
  return <DndId, DndRect>{
    const DndId('item-1'): const DndRect(left: 0, top: 0, width: 100, height: 40),
    const DndId('item-2'): const DndRect(left: 0, top: 40, width: 100, height: 40),
    const DndId('item-3'): const DndRect(left: 0, top: 80, width: 100, height: 40),
  };
}
