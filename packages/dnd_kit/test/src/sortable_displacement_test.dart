import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

DndRect _verticalSlot(double top) => DndRect(left: 0, top: top, width: 100, height: 40);

DndRect _horizontalSlot(double left) => DndRect(left: left, top: 0, width: 40, height: 100);

void main() {
  const a = DndId('a');
  const b = DndId('b');
  const c = DndId('c');
  const itemIds = <DndId>[a, b, c];

  group('SortableDisplacements.verticalList', () {
    // Uniform slots: tops 0 / 50 / 100, height 40, gap 10.
    final itemRects = <DndId, DndRect>{
      a: _verticalSlot(0),
      b: _verticalSlot(50),
      c: _verticalSlot(100),
    };

    test('dragging down past two items shifts them up by one slot', () {
      final displacements = SortableDisplacements.verticalList(
        SortableDisplacementInput(
          activeId: a,
          itemIds: itemIds,
          itemRects: itemRects,
          fromIndex: 0,
          activeRect: itemRects[a],
          activeTranslatedRect: _verticalSlot(105),
        ),
      );

      expect(displacements, <DndId, DndPoint>{
        b: const DndPoint(0, -50),
        c: const DndPoint(0, -50),
      });
    });

    test('dragging up past two items shifts them down by one slot', () {
      final displacements = SortableDisplacements.verticalList(
        SortableDisplacementInput(
          activeId: c,
          itemIds: itemIds,
          itemRects: itemRects,
          fromIndex: 2,
          activeRect: itemRects[c],
          activeTranslatedRect: _verticalSlot(-5),
        ),
      );

      expect(displacements, <DndId, DndPoint>{
        a: const DndPoint(0, 50),
        b: const DndPoint(0, 50),
      });
    });

    test('resting near the original slot displaces nothing', () {
      final displacements = SortableDisplacements.verticalList(
        SortableDisplacementInput(
          activeId: b,
          itemIds: itemIds,
          itemRects: itemRects,
          fromIndex: 1,
          activeRect: itemRects[b],
          activeTranslatedRect: _verticalSlot(55),
        ),
      );

      expect(displacements, isEmpty);
    });

    test('missing measurements displace nothing', () {
      final displacements = SortableDisplacements.verticalList(
        SortableDisplacementInput(
          activeId: a,
          itemIds: itemIds,
          itemRects: const <DndId, DndRect>{},
          fromIndex: 0,
          activeRect: itemRects[a],
          activeTranslatedRect: _verticalSlot(105),
        ),
      );

      expect(displacements, isEmpty);
    });

    test('missing active rects displace nothing', () {
      final displacements = SortableDisplacements.verticalList(
        SortableDisplacementInput(
          activeId: a,
          itemIds: itemIds,
          itemRects: itemRects,
          fromIndex: 0,
        ),
      );

      expect(displacements, isEmpty);
    });

    test('skips items whose neighbour slot is unmeasured', () {
      final partialRects = <DndId, DndRect>{
        a: _verticalSlot(0),
        c: _verticalSlot(100),
      };
      final displacements = SortableDisplacements.verticalList(
        SortableDisplacementInput(
          activeId: a,
          itemIds: itemIds,
          itemRects: partialRects,
          fromIndex: 0,
          activeRect: partialRects[a],
          activeTranslatedRect: _verticalSlot(105),
        ),
      );

      // `b` is unmeasured, so it rests in place — and `c`'s shift target is
      // `b`'s slot, which is equally unmeasured, so `c` rests too instead of
      // guessing a position.
      expect(displacements, isEmpty);
    });
  });

  group('SortableDisplacements.horizontalList', () {
    // Uniform slots: lefts 0 / 50 / 100, width 40, gap 10.
    final itemRects = <DndId, DndRect>{
      a: _horizontalSlot(0),
      b: _horizontalSlot(50),
      c: _horizontalSlot(100),
    };

    test('dragging right past two items shifts them left by one slot', () {
      final displacements = SortableDisplacements.horizontalList(
        SortableDisplacementInput(
          activeId: a,
          itemIds: itemIds,
          itemRects: itemRects,
          fromIndex: 0,
          activeRect: itemRects[a],
          activeTranslatedRect: _horizontalSlot(105),
        ),
      );

      expect(displacements, <DndId, DndPoint>{
        b: const DndPoint(-50, 0),
        c: const DndPoint(-50, 0),
      });
    });

    test('dragging left past one item shifts it right by one slot', () {
      final displacements = SortableDisplacements.horizontalList(
        SortableDisplacementInput(
          activeId: c,
          itemIds: itemIds,
          itemRects: itemRects,
          fromIndex: 2,
          activeRect: itemRects[c],
          activeTranslatedRect: _horizontalSlot(45),
        ),
      );

      expect(displacements, <DndId, DndPoint>{
        b: const DndPoint(50, 0),
      });
    });
  });
}
