import 'dart:collection';

import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:flutter/widgets.dart';

/// Adapter-owned measured rectangles for Flutter drag-and-drop widgets.
class DndMeasuringRegistry {
  final Map<DndId, DndRect> _draggableRects = <DndId, DndRect>{};
  final Map<DndId, DndRect> _droppableRects = <DndId, DndRect>{};

  /// Measured draggable rectangles keyed by stable id.
  Map<DndId, DndRect> get draggableRects => UnmodifiableMapView(_draggableRects);

  /// Measured droppable rectangles keyed by stable id.
  Map<DndId, DndRect> get droppableRects => UnmodifiableMapView(_droppableRects);

  /// Returns the measured draggable rect for [id], when known.
  DndRect? draggableRect(DndId id) => _draggableRects[id];

  /// Returns the measured droppable rect for [id], when known.
  DndRect? droppableRect(DndId id) => _droppableRects[id];

  /// Stores [rect] for the draggable [id].
  void updateDraggableRect(DndId id, DndRect rect) {
    _draggableRects[id] = rect;
  }

  /// Stores [rect] for the droppable [id].
  void updateDroppableRect(DndId id, DndRect rect) {
    _droppableRects[id] = rect;
  }

  /// Removes measured draggable data for [id].
  DndRect? removeDraggableRect(DndId id) {
    return _draggableRects.remove(id);
  }

  /// Removes measured droppable data for [id].
  DndRect? removeDroppableRect(DndId id) {
    return _droppableRects.remove(id);
  }

  /// Clears all measured rectangles.
  void clear() {
    _draggableRects.clear();
    _droppableRects.clear();
  }
}

/// Measures [context]'s render box in global coordinates.
DndRect? measureDndRect(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    return null;
  }

  final topLeft = renderObject.localToGlobal(Offset.zero);
  final size = renderObject.size;
  return DndRect(
    left: topLeft.dx,
    top: topLeft.dy,
    width: size.width,
    height: size.height,
  );
}
