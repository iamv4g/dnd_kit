import 'dart:math' as math;

import 'geometry.dart';
import 'id.dart';

/// Modifies the active drag transform before it is applied.
typedef DndModifier = DndTransform Function(DndModifierInput input);

/// Input shared by built-in and custom drag modifiers.
final class DndModifierInput {
  /// Creates modifier input.
  const DndModifierInput({
    required this.transform,
    required this.activeRect,
    this.boundaryRect,
    this.droppableRects = const <DndId, DndRect>{},
    this.pointer,
  });

  /// The current transform to modify.
  final DndTransform transform;

  /// The active draggable rectangle before [transform] is applied.
  final DndRect activeRect;

  /// Optional rectangle that constrains transformed movement.
  final DndRect? boundaryRect;

  /// Candidate droppable rectangles keyed by stable droppable id.
  final Map<DndId, DndRect> droppableRects;

  /// The current pointer position, when pointer-based modifiers need it.
  final DndPoint? pointer;

  @override
  bool operator ==(Object other) {
    return other is DndModifierInput &&
        other.transform == transform &&
        other.activeRect == activeRect &&
        other.boundaryRect == boundaryRect &&
        _mapEquals(other.droppableRects, droppableRects) &&
        other.pointer == pointer;
  }

  @override
  int get hashCode {
    return Object.hash(
      transform,
      activeRect,
      boundaryRect,
      _mapHash(droppableRects),
      pointer,
    );
  }

  @override
  String toString() {
    return 'DndModifierInput(transform: $transform, activeRect: $activeRect, '
        'boundaryRect: $boundaryRect, droppableRects: $droppableRects, '
        'pointer: $pointer)';
  }
}

/// Built-in pure Dart transform modifiers.
abstract final class DndModifiers {
  /// Removes vertical movement while preserving scale.
  static DndTransform restrictToHorizontalAxis(DndModifierInput input) {
    final transform = input.transform;
    return DndTransform(x: transform.x, scaleX: transform.scaleX, scaleY: transform.scaleY);
  }

  /// Removes horizontal movement while preserving scale.
  static DndTransform restrictToVerticalAxis(DndModifierInput input) {
    final transform = input.transform;
    return DndTransform(y: transform.y, scaleX: transform.scaleX, scaleY: transform.scaleY);
  }

  /// Returns a modifier that keeps the transformed active rectangle inside [boundary].
  static DndModifier restrictToBoundary(DndRect boundary) {
    return (input) {
      final transform = input.transform;
      final minX = boundary.left - input.activeRect.left;
      final maxX = boundary.right - input.activeRect.right;
      final minY = boundary.top - input.activeRect.top;
      final maxY = boundary.bottom - input.activeRect.bottom;

      return DndTransform(
        x: _clamp(transform.x, minX, maxX),
        y: _clamp(transform.y, minY, maxY),
        scaleX: transform.scaleX,
        scaleY: transform.scaleY,
      );
    };
  }

  /// Keeps the active rectangle inside [DndModifierInput.boundaryRect] when present.
  static DndTransform restrictToInputBoundary(DndModifierInput input) {
    final boundary = input.boundaryRect;
    if (boundary == null) {
      return input.transform;
    }

    return restrictToBoundary(boundary)(input);
  }

  /// Returns a modifier that rounds translation to the nearest grid step.
  static DndModifier snapToGrid({
    required double width,
    required double height,
  }) {
    assert(width > 0, 'Grid width must be positive.');
    assert(height > 0, 'Grid height must be positive.');

    return (input) {
      final transform = input.transform;
      return DndTransform(
        x: _snap(transform.x, width),
        y: _snap(transform.y, height),
        scaleX: transform.scaleX,
        scaleY: transform.scaleY,
      );
    };
  }

  /// Returns a modifier that applies [modifiers] from first to last.
  static DndModifier compose(Iterable<DndModifier> modifiers) {
    final modifierList = List<DndModifier>.unmodifiable(modifiers);
    return (input) {
      var transform = input.transform;
      for (final modifier in modifierList) {
        transform = modifier(_inputWithTransform(input, transform));
      }

      return transform;
    };
  }
}

DndModifierInput _inputWithTransform(DndModifierInput input, DndTransform transform) {
  return DndModifierInput(
    transform: transform,
    activeRect: input.activeRect,
    boundaryRect: input.boundaryRect,
    droppableRects: input.droppableRects,
    pointer: input.pointer,
  );
}

double _clamp(double value, double min, double max) {
  if (min > max) {
    return min;
  }

  return math.min(math.max(value, min), max);
}

double _snap(double value, double step) => (value / step).roundToDouble() * step;

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }

  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

int _mapHash(Map<DndId, DndRect> map) {
  final entries = map.entries.toList()..sort((a, b) => a.key.value.compareTo(b.key.value));
  return Object.hashAll(entries.map((entry) => Object.hash(entry.key, entry.value)));
}
