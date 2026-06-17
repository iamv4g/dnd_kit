import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('DndPoint', () {
    test('compares by value', () {
      expect(const DndPoint(1, 2), equals(const DndPoint(1, 2)));
      expect(const DndPoint(1, 2), isNot(equals(const DndPoint(2, 1))));
      expect(const DndPoint(1, 2).hashCode, equals(const DndPoint(1, 2).hashCode));
    });

    test('translates by another point', () {
      expect(const DndPoint(3, 4).translate(const DndPoint(-1, 2)), const DndPoint(2, 6));
    });

    test('calculates point difference', () {
      expect(const DndPoint(6, 4).difference(const DndPoint(2, 1)), const DndPoint(4, 3));
    });
  });

  group('DndSize', () {
    test('compares by value and reports empty sizes', () {
      expect(const DndSize(10, 20), equals(const DndSize(10, 20)));
      expect(const DndSize(0, 20).isEmpty, isTrue);
      expect(const DndSize(10, 0).isEmpty, isTrue);
      expect(const DndSize(10, 20).isEmpty, isFalse);
    });

    test('rejects negative extents in debug mode', () {
      expect(() => DndSize(-1, 10), throwsA(isA<AssertionError>()));
      expect(() => DndSize(10, -1), throwsA(isA<AssertionError>()));
    });
  });

  group('DndRect', () {
    test('creates from point and size', () {
      final rect = DndRect.fromPointAndSize(const DndPoint(2, 3), const DndSize(10, 20));

      expect(rect, const DndRect(left: 2, top: 3, width: 10, height: 20));
      expect(rect.topLeft, const DndPoint(2, 3));
      expect(rect.size, const DndSize(10, 20));
    });

    test('exposes edges and center', () {
      const rect = DndRect(left: 2, top: 4, width: 10, height: 20);

      expect(rect.right, 12);
      expect(rect.bottom, 24);
      expect(rect.center, const DndPoint(7, 14));
    });

    test('contains points on its edges', () {
      const rect = DndRect(left: 10, top: 20, width: 30, height: 40);

      expect(rect.containsPoint(const DndPoint(10, 20)), isTrue);
      expect(rect.containsPoint(const DndPoint(40, 60)), isTrue);
      expect(rect.containsPoint(const DndPoint(41, 60)), isFalse);
      expect(rect.containsPoint(const DndPoint(40, 61)), isFalse);
    });

    test('overlaps only when rectangles share positive area', () {
      const rect = DndRect(left: 0, top: 0, width: 10, height: 10);

      expect(rect.overlaps(const DndRect(left: 5, top: 5, width: 10, height: 10)), isTrue);
      expect(rect.overlaps(const DndRect(left: 10, top: 0, width: 10, height: 10)), isFalse);
      expect(rect.overlaps(const DndRect(left: 0, top: 10, width: 10, height: 10)), isFalse);
    });

    test('translates and inflates', () {
      const rect = DndRect(left: 2, top: 3, width: 10, height: 20);

      expect(
        rect.translate(const DndPoint(5, -1)),
        const DndRect(left: 7, top: 2, width: 10, height: 20),
      );
      expect(
        rect.inflate(2),
        const DndRect(left: 0, top: 1, width: 14, height: 24),
      );
    });

    test('rejects negative extents in debug mode', () {
      expect(
        () => DndRect(left: 0, top: 0, width: -1, height: 10),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DndRect(left: 0, top: 0, width: 10, height: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => const DndRect(left: 0, top: 0, width: 2, height: 2).inflate(-2),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('DndTransform', () {
    test('defaults to identity', () {
      expect(DndTransform.identity.isIdentity, isTrue);
      expect(DndTransform.identity.offset, DndPoint.zero);
    });

    test('compares by value and translates', () {
      const transform = DndTransform(x: 1, y: 2, scaleX: 3, scaleY: 4);

      expect(transform, equals(const DndTransform(x: 1, y: 2, scaleX: 3, scaleY: 4)));
      expect(
        transform.translate(const DndPoint(5, 6)),
        const DndTransform(x: 6, y: 8, scaleX: 3, scaleY: 4),
      );
    });

    test('rejects negative scale in debug mode', () {
      expect(() => DndTransform(scaleX: -1), throwsA(isA<AssertionError>()));
      expect(() => DndTransform(scaleY: -1), throwsA(isA<AssertionError>()));
    });
  });
}
