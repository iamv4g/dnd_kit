import 'package:flutter/gestures.dart';

/// Configures pointer drag activation through a long press.
final class DndLongPressActivation {
  /// Creates long-press activation settings.
  const DndLongPressActivation({
    this.delay = kLongPressTimeout,
    this.tolerance = kTouchSlop,
    this.hapticFeedback = false,
  }) : assert(tolerance >= 0, 'Long-press tolerance must be non-negative.');

  /// How long the pointer must remain down before the drag starts.
  final Duration delay;

  /// Maximum movement allowed before [delay] elapses.
  final double tolerance;

  /// Whether to emit platform haptic feedback when the drag starts.
  final bool hapticFeedback;
}
