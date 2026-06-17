import 'geometry.dart';

/// Edge-threshold and velocity settings for drag-driven auto-scroll.
final class DndAutoScrollOptions {
  /// Creates auto-scroll options.
  const DndAutoScrollOptions({
    this.edgeThreshold = 56,
    this.maxVelocity = 16,
  })  : assert(edgeThreshold > 0, 'Edge threshold must be positive.'),
        assert(maxVelocity > 0, 'Max velocity must be positive.');

  /// Distance from the viewport edge where auto-scroll can activate.
  final double edgeThreshold;

  /// Maximum logical pixels to scroll per frame.
  final double maxVelocity;
}

/// Computes the per-frame auto-scroll velocity for a vertical scroll viewport.
///
/// This is the framework-neutral edge-threshold and speed math: adapters pass a
/// viewport-local pointer, the viewport size, and the current scroll extents,
/// and receive logical pixels to scroll this frame. A negative result scrolls
/// toward the start (leading edge), a positive result toward the end (trailing
/// edge), and `0` means the pointer is outside both edge bands or scrolling is
/// already clamped.
///
/// Only the act of measuring the viewport and pointer is adapter-specific; the
/// thresholds and velocity curve are shared (SPEC_JASPR §6.4).
double dndAutoScrollVelocity({
  required DndPoint localPointer,
  required DndSize viewportSize,
  required double scrollPixels,
  required double minScrollExtent,
  required double maxScrollExtent,
  DndAutoScrollOptions options = const DndAutoScrollOptions(),
}) {
  if (localPointer.x < 0 ||
      localPointer.x > viewportSize.width ||
      localPointer.y < 0 ||
      localPointer.y > viewportSize.height) {
    return 0;
  }

  final threshold = options.edgeThreshold;
  final maxVelocity = options.maxVelocity;
  if (localPointer.y < threshold && scrollPixels > minScrollExtent) {
    return -maxVelocity * ((threshold - localPointer.y) / threshold);
  }

  final trailingDistance = viewportSize.height - localPointer.y;
  if (trailingDistance < threshold && scrollPixels < maxScrollExtent) {
    return maxVelocity * ((threshold - trailingDistance) / threshold);
  }

  return 0;
}
