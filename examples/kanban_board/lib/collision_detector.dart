import 'dart:math' as math;

import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';

DndCollisionResult kanbanBoardCollisionDetector(DndCollisionInput input) {
  final pointerWithin = DndCollisionDetectors.pointerWithin(input);
  if (pointerWithin.isNotEmpty) {
    final taskResult = DndCollisionResult(
      pointerWithin.collisions.where(
        (collision) => collision.id.value.startsWith('task:'),
      ),
    );
    if (taskResult.isNotEmpty) {
      return taskResult;
    }
    return pointerWithin;
  }

  final closest = DndCollisionDetectors.closestCenter(input);
  return DndCollisionResult(
    closest.collisions.take(math.min(closest.collisions.length, 3)),
  );
}
