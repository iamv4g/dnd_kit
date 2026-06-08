import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:test/test.dart';

void main() {
  const activeRect = DndRect(left: 0, top: 0, width: 10, height: 10);
  const left = DndId('left');
  const center = DndId('center');
  const right = DndId('right');

  group('DndCollisionInput', () {
    test('compares by value', () {
      final input = DndCollisionInput(
        activeRect: activeRect,
        droppableRects: {
          left: DndRect(left: -20, top: 0, width: 10, height: 10),
        },
        pointer: const DndPoint(1, 2),
      );
      final matchingInput = DndCollisionInput(
        activeRect: activeRect,
        droppableRects: {
          left: DndRect(left: -20, top: 0, width: 10, height: 10),
        },
        pointer: const DndPoint(1, 2),
      );

      expect(input, equals(matchingInput));
      expect(input.hashCode, equals(matchingInput.hashCode));
      expect(input.toString(), contains('DndCollisionInput'));
    });
  });

  group('DndCollisionResult', () {
    test('sorts collisions by score then id', () {
      final result = DndCollisionResult(const [
        DndCollision(id: right, score: 2),
        DndCollision(id: center, score: 1),
        DndCollision(id: left, score: 1),
      ]);

      expect(
        result.collisions,
        const [
          DndCollision(id: center, score: 1),
          DndCollision(id: left, score: 1),
          DndCollision(id: right, score: 2),
        ],
      );
      expect(result.firstOrNull, const DndCollision(id: center, score: 1));
      expect(result.isNotEmpty, isTrue);
      expect(result.isEmpty, isFalse);
    });

    test('compares by value and exposes empty result', () {
      expect(DndCollisionResult.empty, equals(DndCollisionResult(const [])));
      expect(DndCollisionResult.empty.firstOrNull, isNull);
      expect(DndCollisionResult.empty.isEmpty, isTrue);
    });
  });

  group('DndCollisionDetectors.closestCenter', () {
    test('ranks rectangles by center distance', () {
      final result = DndCollisionDetectors.closestCenter(
        DndCollisionInput(
          activeRect: activeRect,
          droppableRects: {
            right: DndRect(left: 40, top: 0, width: 10, height: 10),
            center: DndRect(left: 4, top: 0, width: 10, height: 10),
            left: DndRect(left: -20, top: 0, width: 10, height: 10),
          },
        ),
      );

      expect(result.collisions.map((collision) => collision.id), [center, left, right]);
      expect(result.firstOrNull, const DndCollision(id: center, score: 16));
    });
  });

  group('DndCollisionDetectors.closestCorners', () {
    test('ranks rectangles by summed corner distance', () {
      final result = DndCollisionDetectors.closestCorners(
        DndCollisionInput(
          activeRect: activeRect,
          droppableRects: {
            right: DndRect(left: 40, top: 0, width: 10, height: 10),
            center: DndRect(left: 3, top: 4, width: 10, height: 10),
            left: DndRect(left: -20, top: 0, width: 10, height: 10),
          },
        ),
      );

      expect(result.collisions.map((collision) => collision.id), [center, left, right]);
      expect(result.firstOrNull, const DndCollision(id: center, score: 100));
    });
  });

  group('DndCollisionDetectors.rectIntersection', () {
    test('returns only overlapping rectangles ranked by largest area', () {
      final result = DndCollisionDetectors.rectIntersection(
        DndCollisionInput(
          activeRect: activeRect,
          droppableRects: {
            right: DndRect(left: 20, top: 0, width: 10, height: 10),
            center: DndRect(left: 2, top: 2, width: 10, height: 10),
            left: DndRect(left: -5, top: 0, width: 10, height: 10),
          },
        ),
      );

      expect(result.collisions.map((collision) => collision.id), [center, left]);
      expect(result.firstOrNull, const DndCollision(id: center, score: -64));
    });

    test('ignores edge-touching rectangles', () {
      final result = DndCollisionDetectors.rectIntersection(
        DndCollisionInput(
          activeRect: activeRect,
          droppableRects: {
            right: DndRect(left: 10, top: 0, width: 10, height: 10),
          },
        ),
      );

      expect(result, DndCollisionResult.empty);
    });
  });

  group('DndCollisionDetectors.pointerWithin', () {
    test('returns rectangles containing the pointer ranked by pointer distance', () {
      final result = DndCollisionDetectors.pointerWithin(
        DndCollisionInput(
          activeRect: activeRect,
          pointer: const DndPoint(6, 6),
          droppableRects: {
            right: DndRect(left: 20, top: 0, width: 10, height: 10),
            center: DndRect(left: 2, top: 2, width: 10, height: 10),
            left: DndRect(left: 0, top: 0, width: 10, height: 10),
          },
        ),
      );

      expect(result.collisions.map((collision) => collision.id), [center, left]);
      expect(result.firstOrNull, const DndCollision(id: center, score: 2));
    });

    test('returns empty result when no pointer is available', () {
      final result = DndCollisionDetectors.pointerWithin(
        DndCollisionInput(
          activeRect: activeRect,
          droppableRects: {
            center: DndRect(left: 0, top: 0, width: 10, height: 10),
          },
        ),
      );

      expect(result, DndCollisionResult.empty);
    });
  });

  group('DndCollisionDetectors.compose', () {
    test('returns the first non-empty detector result', () {
      final detector = DndCollisionDetectors.compose([
        DndCollisionDetectors.pointerWithin,
        DndCollisionDetectors.closestCenter,
      ]);

      final result = detector(
        DndCollisionInput(
          activeRect: activeRect,
          droppableRects: {
            center: DndRect(left: 4, top: 0, width: 10, height: 10),
          },
        ),
      );

      expect(result.firstOrNull, const DndCollision(id: center, score: 16));
    });

    test('returns empty result when every detector is empty', () {
      final detector = DndCollisionDetectors.compose([
        DndCollisionDetectors.pointerWithin,
      ]);

      expect(
        detector(const DndCollisionInput(activeRect: activeRect, droppableRects: {})),
        DndCollisionResult.empty,
      );
    });
  });
}
