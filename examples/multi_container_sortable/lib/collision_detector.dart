import 'dart:math' as math;

import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';

DndCollisionResult multiContainerCollisionDetector(DndCollisionInput input) {
  // 1. Pointer inside collisions
  final pointerWithin = DndCollisionDetectors.pointerWithin(input);
  if (pointerWithin.isNotEmpty) {
    // Prioritize task card droppables over column droppables
    final taskResult = DndCollisionResult(
      pointerWithin.collisions.where(
        (collision) => collision.id.value.startsWith('task-'),
      ),
    );
    if (taskResult.isNotEmpty) {
      return taskResult;
    }
    return pointerWithin;
  }

  // 2. Fallback to closest center
  final closest = DndCollisionDetectors.closestCenter(input);
  return DndCollisionResult(
    closest.collisions.take(math.min(closest.collisions.length, 3)),
  );
}
