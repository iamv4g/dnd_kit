import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

DndRect _slot(double top) => DndRect(left: 0, top: top, width: 100, height: 40);

void main() {
  group('SortableScopeData.displacementsFor', () {
    const a = DndId('a');
    const b = DndId('b');
    const c = DndId('c');

    test('computes live displacement through the scope displacement strategy', () {
      final data = SortableScopeData(itemIds: const <DndId>[a, b, c]);
      final itemRects = <DndId, DndRect>{
        a: _slot(0),
        b: _slot(50),
        c: _slot(100),
      };

      final displacements = data.displacementsFor(
        activeId: a,
        transform: const DndTransform(y: 105),
        itemRects: itemRects,
        activeRect: itemRects[a],
      );

      expect(displacements, <DndId, DndPoint>{
        b: const DndPoint(0, -50),
        c: const DndPoint(0, -50),
      });
    });

    test('returns no displacement for an unknown active id', () {
      final data = SortableScopeData(itemIds: const <DndId>[a, b]);

      final displacements = data.displacementsFor(
        activeId: c,
        transform: const DndTransform(y: 105),
        itemRects: <DndId, DndRect>{a: _slot(0), b: _slot(50)},
        activeRect: _slot(0),
      );

      expect(displacements, isEmpty);
    });
  });
}
