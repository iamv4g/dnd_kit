import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  const activeRect = DndRect(left: 10, top: 20, width: 30, height: 40);
  const transform = DndTransform(x: 12, y: -18, scaleX: 2, scaleY: 3);

  DndModifierInput input({
    DndTransform transform = transform,
    DndRect? boundaryRect,
  }) {
    return DndModifierInput(
      transform: transform,
      activeRect: activeRect,
      boundaryRect: boundaryRect,
    );
  }

  group('DndModifierInput', () {
    test('compares by value', () {
      const droppable = DndId('drop');
      final first = DndModifierInput(
        transform: transform,
        activeRect: activeRect,
        boundaryRect: const DndRect(left: 0, top: 0, width: 100, height: 100),
        droppableRects: {
          droppable: const DndRect(left: 40, top: 50, width: 10, height: 20),
        },
        pointer: const DndPoint(1, 2),
      );
      final second = DndModifierInput(
        transform: transform,
        activeRect: activeRect,
        boundaryRect: const DndRect(left: 0, top: 0, width: 100, height: 100),
        droppableRects: {
          droppable: const DndRect(left: 40, top: 50, width: 10, height: 20),
        },
        pointer: const DndPoint(1, 2),
      );

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(first.toString(), contains('DndModifierInput'));
    });
  });

  group('DndModifiers axis restrictions', () {
    test('removes vertical movement', () {
      expect(
        DndModifiers.restrictToHorizontalAxis(input()),
        const DndTransform(x: 12, scaleX: 2, scaleY: 3),
      );
    });

    test('removes horizontal movement', () {
      expect(
        DndModifiers.restrictToVerticalAxis(input()),
        const DndTransform(y: -18, scaleX: 2, scaleY: 3),
      );
    });
  });

  group('DndModifiers boundary restriction', () {
    test('clamps movement inside an explicit boundary', () {
      final modifier = DndModifiers.restrictToBoundary(
        const DndRect(left: 0, top: 0, width: 70, height: 80),
      );

      expect(
        modifier(input(transform: const DndTransform(x: 40, y: -50))),
        const DndTransform(x: 30, y: -20),
      );
    });

    test('uses input boundary when present', () {
      expect(
        DndModifiers.restrictToInputBoundary(
          input(
            transform: const DndTransform(x: -20, y: 50),
            boundaryRect: const DndRect(left: 0, top: 0, width: 70, height: 80),
          ),
        ),
        const DndTransform(x: -10, y: 20),
      );
    });

    test('returns the original transform when no input boundary is present', () {
      expect(DndModifiers.restrictToInputBoundary(input()), transform);
    });
  });

  group('DndModifiers.snapToGrid', () {
    test('rounds translation to the nearest grid step', () {
      final modifier = DndModifiers.snapToGrid(width: 10, height: 8);

      expect(
        modifier(input(transform: const DndTransform(x: 14, y: -13))),
        const DndTransform(x: 10, y: -16),
      );
    });

    test('rejects non-positive grid steps in debug mode', () {
      expect(() => DndModifiers.snapToGrid(width: 0, height: 8), throwsA(isA<AssertionError>()));
      expect(() => DndModifiers.snapToGrid(width: 8, height: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('DndModifiers.compose', () {
    test('applies modifiers in order', () {
      final modifier = DndModifiers.compose([
        DndModifiers.snapToGrid(width: 10, height: 10),
        DndModifiers.restrictToHorizontalAxis,
      ]);

      expect(
        modifier(input(transform: const DndTransform(x: 16, y: 16))),
        const DndTransform(x: 20),
      );
    });

    test('returns the input transform when no modifiers are provided', () {
      final modifier = DndModifiers.compose(const []);

      expect(modifier(input()), transform);
    });
  });
}
