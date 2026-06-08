import 'dart:math' as math;

import 'geometry.dart';
import 'id.dart';

/// Detects which droppable rectangles collide with the active draggable.
typedef DndCollisionDetector = DndCollisionResult Function(DndCollisionInput input);

/// Input shared by built-in and custom collision detectors.
final class DndCollisionInput {
  /// Creates collision detector input.
  const DndCollisionInput({
    required this.activeRect,
    required this.droppableRects,
    this.pointer,
  });

  /// The current active draggable rectangle.
  final DndRect activeRect;

  /// Candidate droppable rectangles keyed by stable droppable id.
  final Map<DndId, DndRect> droppableRects;

  /// The current pointer position, when pointer-based detection is available.
  final DndPoint? pointer;

  @override
  bool operator ==(Object other) {
    return other is DndCollisionInput &&
        other.activeRect == activeRect &&
        _mapEquals(other.droppableRects, droppableRects) &&
        other.pointer == pointer;
  }

  @override
  int get hashCode => Object.hash(activeRect, _mapHash(droppableRects), pointer);

  @override
  String toString() {
    return 'DndCollisionInput(activeRect: $activeRect, '
        'droppableRects: $droppableRects, pointer: $pointer)';
  }
}

/// A single collision candidate with a comparable score.
final class DndCollision {
  /// Creates a collision candidate.
  const DndCollision({
    required this.id,
    required this.score,
  });

  /// The droppable id.
  final DndId id;

  /// Detector-specific score used to sort candidates.
  ///
  /// Lower scores rank first for distance-based detectors. Higher overlap is
  /// represented as a negative score by intersection detectors so all built-in
  /// detectors can sort ascending.
  final double score;

  @override
  bool operator ==(Object other) {
    return other is DndCollision && other.id == id && other.score == score;
  }

  @override
  int get hashCode => Object.hash(id, score);

  @override
  String toString() => 'DndCollision(id: $id, score: $score)';
}

/// Sorted collision detector output.
final class DndCollisionResult {
  /// Creates a collision result sorted by score.
  factory DndCollisionResult(Iterable<DndCollision> collisions) {
    final sorted = List<DndCollision>.unmodifiable(collisions.toList()..sort(_compareCollision));
    return DndCollisionResult._(sorted);
  }

  const DndCollisionResult._(this.collisions);

  /// An empty collision result.
  static const empty = DndCollisionResult._(<DndCollision>[]);

  /// Collision candidates sorted by ascending score.
  final List<DndCollision> collisions;

  /// Whether there are no collision candidates.
  bool get isEmpty => collisions.isEmpty;

  /// Whether there is at least one collision candidate.
  bool get isNotEmpty => collisions.isNotEmpty;

  /// The highest ranked collision, when present.
  DndCollision? get firstOrNull => collisions.isEmpty ? null : collisions.first;

  @override
  bool operator ==(Object other) {
    return other is DndCollisionResult && _listEquals(other.collisions, collisions);
  }

  @override
  int get hashCode => Object.hashAll(collisions);

  @override
  String toString() => 'DndCollisionResult($collisions)';
}

/// Built-in pure Dart collision detectors.
abstract final class DndCollisionDetectors {
  /// Ranks droppables by distance from the active rectangle center.
  static DndCollisionResult closestCenter(DndCollisionInput input) {
    return DndCollisionResult(
      input.droppableRects.entries.map((entry) {
        return DndCollision(
          id: entry.key,
          score: _distanceSquared(input.activeRect.center, entry.value.center),
        );
      }),
    );
  }

  /// Ranks droppables by summed corner distance from the active rectangle.
  static DndCollisionResult closestCorners(DndCollisionInput input) {
    return DndCollisionResult(
      input.droppableRects.entries.map((entry) {
        return DndCollision(
          id: entry.key,
          score: _cornerDistance(input.activeRect, entry.value),
        );
      }),
    );
  }

  /// Ranks overlapping droppables by descending intersection area.
  static DndCollisionResult rectIntersection(DndCollisionInput input) {
    return DndCollisionResult(
      input.droppableRects.entries.expand((entry) {
        final area = _intersectionArea(input.activeRect, entry.value);
        if (area <= 0) {
          return const <DndCollision>[];
        }

        return <DndCollision>[DndCollision(id: entry.key, score: -area)];
      }),
    );
  }

  /// Returns droppables containing the current pointer.
  static DndCollisionResult pointerWithin(DndCollisionInput input) {
    final pointer = input.pointer;
    if (pointer == null) {
      return DndCollisionResult.empty;
    }

    return DndCollisionResult(
      input.droppableRects.entries.expand((entry) {
        if (!entry.value.containsPoint(pointer)) {
          return const <DndCollision>[];
        }

        return <DndCollision>[
          DndCollision(id: entry.key, score: _distanceSquared(pointer, entry.value.center)),
        ];
      }),
    );
  }

  /// Returns a detector that uses the first non-empty result in [detectors].
  static DndCollisionDetector compose(Iterable<DndCollisionDetector> detectors) {
    final detectorList = List<DndCollisionDetector>.unmodifiable(detectors);
    return (input) {
      for (final detector in detectorList) {
        final result = detector(input);
        if (result.isNotEmpty) {
          return result;
        }
      }

      return DndCollisionResult.empty;
    };
  }
}

int _compareCollision(DndCollision a, DndCollision b) {
  final scoreComparison = a.score.compareTo(b.score);
  if (scoreComparison != 0) {
    return scoreComparison;
  }

  return a.id.value.compareTo(b.id.value);
}

double _distanceSquared(DndPoint a, DndPoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return dx * dx + dy * dy;
}

double _cornerDistance(DndRect a, DndRect b) {
  return _distanceSquared(a.topLeft, b.topLeft) +
      _distanceSquared(DndPoint(a.right, a.top), DndPoint(b.right, b.top)) +
      _distanceSquared(DndPoint(a.left, a.bottom), DndPoint(b.left, b.bottom)) +
      _distanceSquared(DndPoint(a.right, a.bottom), DndPoint(b.right, b.bottom));
}

double _intersectionArea(DndRect a, DndRect b) {
  final left = math.max(a.left, b.left);
  final top = math.max(a.top, b.top);
  final right = math.min(a.right, b.right);
  final bottom = math.min(a.bottom, b.bottom);
  final width = right - left;
  final height = bottom - top;

  if (width <= 0 || height <= 0) {
    return 0;
  }

  return width * height;
}

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

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}
