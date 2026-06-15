import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:test/test.dart';

void main() {
  group('dndAutoScrollVelocity', () {
    const viewport = DndSize(200, 400);
    const options = DndAutoScrollOptions(edgeThreshold: 56, maxVelocity: 16);

    double velocity(DndPoint localPointer, {double pixels = 100}) {
      return dndAutoScrollVelocity(
        localPointer: localPointer,
        viewportSize: viewport,
        scrollPixels: pixels,
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        options: options,
      );
    }

    test('returns zero in the neutral middle band', () {
      expect(velocity(const DndPoint(100, 200)), 0);
    });

    test('scrolls toward the start near the leading edge', () {
      // 20px from the top: -16 * ((56 - 20) / 56)
      expect(velocity(const DndPoint(100, 20)), closeTo(-16 * (36 / 56), 1e-9));
    });

    test('scrolls toward the end near the trailing edge', () {
      // trailingDistance = 400 - 380 = 20: 16 * ((56 - 20) / 56)
      expect(velocity(const DndPoint(100, 380)), closeTo(16 * (36 / 56), 1e-9));
    });

    test('does not scroll past the leading clamp', () {
      expect(velocity(const DndPoint(100, 20), pixels: 0), 0);
    });

    test('does not scroll past the trailing clamp', () {
      expect(
        dndAutoScrollVelocity(
          localPointer: const DndPoint(100, 380),
          viewportSize: viewport,
          scrollPixels: 1000,
          minScrollExtent: 0,
          maxScrollExtent: 1000,
          options: options,
        ),
        0,
      );
    });

    test('returns zero when the pointer is outside the viewport', () {
      expect(velocity(const DndPoint(-5, 20)), 0);
      expect(velocity(const DndPoint(100, 420)), 0);
    });
  });
}
