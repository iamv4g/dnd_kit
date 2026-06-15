import 'dart:collection';

import 'geometry.dart';
import 'id.dart';

/// Current cache state for an adapter-owned measurement.
enum DndMeasurementStatus {
  /// No measurement or removal record exists for the id.
  missing,

  /// A measured rectangle exists and is current.
  clean,

  /// A measured rectangle may exist, but it must be refreshed before runtime use.
  dirty,

  /// A previously measured id was removed from the cache.
  removed,
}

typedef _DndRectMeasurer = DndRect? Function();

final class _DndMeasurementEntry {
  _DndMeasurementEntry({
    this.rect,
    this.dirty = true,
    this.measurer,
  });

  DndRect? rect;
  bool dirty;
  _DndRectMeasurer? measurer;
}

/// Adapter-owned measured rectangles for drag-and-drop sources and targets.
///
/// The cache semantics and invalidation behavior are framework-neutral; only
/// the act of measuring (turning a Flutter render box or a DOM element into a
/// [DndRect]) is adapter-specific. Adapters register a measurer via
/// [markDraggableDirty] / [markDroppableDirty] and call [refreshDirty] before
/// runtime collision logic reads the cache.
class DndMeasuringRegistry {
  final Map<DndId, _DndMeasurementEntry> _draggableEntries = <DndId, _DndMeasurementEntry>{};
  final Map<DndId, _DndMeasurementEntry> _droppableEntries = <DndId, _DndMeasurementEntry>{};
  final Set<DndId> _removedDraggableIds = <DndId>{};
  final Set<DndId> _removedDroppableIds = <DndId>{};

  /// Measured draggable rectangles keyed by stable id.
  Map<DndId, DndRect> get draggableRects => UnmodifiableMapView(_rectsFor(_draggableEntries));

  /// Measured droppable rectangles keyed by stable id.
  Map<DndId, DndRect> get droppableRects => UnmodifiableMapView(_rectsFor(_droppableEntries));

  /// Returns the measured draggable rect for [id], when known.
  DndRect? draggableRect(DndId id) => _draggableEntries[id]?.rect;

  /// Returns the measured droppable rect for [id], when known.
  DndRect? droppableRect(DndId id) => _droppableEntries[id]?.rect;

  /// Returns the cache status for the draggable [id].
  DndMeasurementStatus draggableStatus(DndId id) {
    return _statusFor(id, _draggableEntries, _removedDraggableIds);
  }

  /// Returns the cache status for the droppable [id].
  DndMeasurementStatus droppableStatus(DndId id) {
    return _statusFor(id, _droppableEntries, _removedDroppableIds);
  }

  /// Stores [rect] for the draggable [id].
  void updateDraggableRect(DndId id, DndRect rect) {
    _updateRect(id, rect, _draggableEntries, _removedDraggableIds);
  }

  /// Stores [rect] for the droppable [id].
  void updateDroppableRect(DndId id, DndRect rect) {
    _updateRect(id, rect, _droppableEntries, _removedDroppableIds);
  }

  /// Marks the draggable [id] as needing a measurement refresh.
  void markDraggableDirty(DndId id, {DndRect? Function()? measure}) {
    _markDirty(id, _draggableEntries, _removedDraggableIds, measure: measure);
  }

  /// Marks the droppable [id] as needing a measurement refresh.
  void markDroppableDirty(DndId id, {DndRect? Function()? measure}) {
    _markDirty(id, _droppableEntries, _removedDroppableIds, measure: measure);
  }

  /// Refreshes all dirty measurements with registered measurement callbacks.
  void refreshDirty() {
    _refreshDirty(_draggableEntries);
    _refreshDirty(_droppableEntries);
  }

  /// Removes measured draggable data for [id].
  DndRect? removeDraggableRect(DndId id) {
    return _removeRect(id, _draggableEntries, _removedDraggableIds);
  }

  /// Removes measured droppable data for [id].
  DndRect? removeDroppableRect(DndId id) {
    return _removeRect(id, _droppableEntries, _removedDroppableIds);
  }

  /// Clears all measured rectangles.
  void clear() {
    _draggableEntries.clear();
    _droppableEntries.clear();
    _removedDraggableIds.clear();
    _removedDroppableIds.clear();
  }

  Map<DndId, DndRect> _rectsFor(Map<DndId, _DndMeasurementEntry> entries) {
    return <DndId, DndRect>{
      for (final entry in entries.entries)
        if (entry.value.rect case final rect?) entry.key: rect,
    };
  }

  DndMeasurementStatus _statusFor(
    DndId id,
    Map<DndId, _DndMeasurementEntry> entries,
    Set<DndId> removedIds,
  ) {
    final entry = entries[id];
    if (entry != null) {
      return entry.dirty ? DndMeasurementStatus.dirty : DndMeasurementStatus.clean;
    }

    return removedIds.contains(id) ? DndMeasurementStatus.removed : DndMeasurementStatus.missing;
  }

  void _updateRect(
    DndId id,
    DndRect rect,
    Map<DndId, _DndMeasurementEntry> entries,
    Set<DndId> removedIds,
  ) {
    final entry = entries[id];
    if (entry == null) {
      entries[id] = _DndMeasurementEntry(rect: rect, dirty: false);
    } else {
      entry
        ..rect = rect
        ..dirty = false;
    }
    removedIds.remove(id);
  }

  void _markDirty(
    DndId id,
    Map<DndId, _DndMeasurementEntry> entries,
    Set<DndId> removedIds, {
    DndRect? Function()? measure,
  }) {
    final entry = entries[id];
    if (entry == null) {
      entries[id] = _DndMeasurementEntry(measurer: measure);
    } else {
      entry
        ..dirty = true
        ..measurer = measure ?? entry.measurer;
    }
    removedIds.remove(id);
  }

  void _refreshDirty(Map<DndId, _DndMeasurementEntry> entries) {
    for (final entry in entries.values) {
      if (!entry.dirty) {
        continue;
      }

      final rect = entry.measurer?.call();
      if (rect == null) {
        continue;
      }

      entry
        ..rect = rect
        ..dirty = false;
    }
  }

  DndRect? _removeRect(
    DndId id,
    Map<DndId, _DndMeasurementEntry> entries,
    Set<DndId> removedIds,
  ) {
    final rect = entries.remove(id)?.rect;
    removedIds.add(id);
    return rect;
  }
}
