import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';

/// The wrapper every sortable surface on the site puts around an item: the
/// dragged item goes invisible, because its floating copy is in the overlay,
/// and every displaced item slides to the slot it is making room in.
///
/// Apply it inside the item builder, so the transform sits below the measured
/// element and cannot feed back into collision.
Styles slotStyles(SortableItemDetails details) {
  final offset = details.offset;
  return Styles(
    opacity: details.isActive ? 0 : 1,
    transform: offset == DndPoint.zero
        ? Transform.none
        : Transform.translate(x: offset.x.px, y: offset.y.px),
    raw: const {'transition': 'transform 150ms ease'},
  );
}

/// Opens the drop gap for layouts the built-in list resolvers do not cover: a
/// wrapped row or a responsive grid, where a displaced item can move sideways,
/// on to the next line, or both at once.
///
/// Every displaced item shifts by exactly one slot, so its offset is the delta
/// between its own measured origin and that of the slot it moves into. Reading
/// both from [SortableOffsetInput.itemRects] keeps this correct across
/// breakpoints without knowing the column count or the wrap points.
Map<DndId, DndPoint> gridOffsets(SortableOffsetInput input) {
  final fromIndex = input.fromIndex;
  final toIndex = input.toIndex;
  if (fromIndex == toIndex || fromIndex < 0 || toIndex < 0) {
    return const <DndId, DndPoint>{};
  }

  final itemIds = input.itemIds;
  final lastIndex = itemIds.length - 1;
  if (fromIndex > lastIndex || toIndex > lastIndex) {
    return const <DndId, DndPoint>{};
  }

  // Moving forward pulls the items in between back one slot; moving backward
  // pushes them on one.
  final movingForward = toIndex > fromIndex;
  final first = movingForward ? fromIndex + 1 : toIndex;
  final last = movingForward ? toIndex : fromIndex - 1;
  final step = movingForward ? -1 : 1;

  final offsets = <DndId, DndPoint>{};
  for (var index = first; index <= last; index += 1) {
    final id = itemIds[index];
    if (id == input.activeId) {
      continue;
    }
    final delta = _slotDelta(input.itemRects, id, itemIds, index + step);
    if (delta != null) {
      offsets[id] = delta;
    }
  }

  return Map<DndId, DndPoint>.unmodifiable(offsets);
}

/// The multi-container counterpart of [gridOffsets], for boards whose columns
/// are wrapped rows rather than plain vertical lists.
Map<DndId, DndPoint> flowOffsets(SortableMultiOffsetInput input) {
  final fromContainer = input.containerById(input.fromContainerId);
  final toContainer = input.containerById(input.toContainerId);
  if (fromContainer == null || toContainer == null) {
    return const <DndId, DndPoint>{};
  }

  final rects = input.itemRects;
  if (fromContainer.id == toContainer.id) {
    return gridOffsets(
      SortableOffsetInput(
        activeId: input.activeId,
        itemIds: fromContainer.itemIds,
        itemRects: rects,
        fromIndex: input.fromIndex,
        toIndex: input.toIndex,
      ),
    );
  }

  final offsets = <DndId, DndPoint>{};

  // Source container: everything after the dragged item closes the vacated slot.
  final fromIds = fromContainer.itemIds;
  for (var index = input.fromIndex + 1; index < fromIds.length; index += 1) {
    final id = fromIds[index];
    if (id == input.activeId) {
      continue;
    }
    final delta = _slotDelta(rects, id, fromIds, index - 1);
    if (delta != null) {
      offsets[id] = delta;
    }
  }

  // Target container: everything at or after the landing index opens a slot.
  // The last item is the one case with no next slot to read, so where it goes
  // has to be derived from the container's own flow.
  final toIds = toContainer.itemIds;
  final appended = _appendedSlotOrigin(rects, toIds);
  for (var index = input.toIndex; index < toIds.length; index += 1) {
    final id = toIds[index];
    if (id == input.activeId) {
      continue;
    }

    DndPoint? delta;
    if (index + 1 < toIds.length) {
      delta = _slotDelta(rects, id, toIds, index + 1);
    } else if (appended != null) {
      final current = rects[id];
      if (current != null) {
        delta = DndPoint(appended.x - current.left, appended.y - current.top);
      }
    }
    if (delta != null && delta != DndPoint.zero) {
      offsets[id] = delta;
    }
  }

  return Map<DndId, DndPoint>.unmodifiable(offsets);
}

/// How far [id] must move to sit where the item at [slotIndex] sits now.
///
/// Null when either rectangle is unmeasured: a guessed offset in a wrapped
/// layout moves an item to a slot that does not exist.
DndPoint? _slotDelta(
  Map<DndId, DndRect> rects,
  DndId id,
  List<DndId> slotIds,
  int slotIndex,
) {
  if (slotIndex < 0 || slotIndex >= slotIds.length) {
    return null;
  }
  final current = rects[id];
  final target = rects[slotIds[slotIndex]];
  if (current == null || target == null) {
    return null;
  }
  return DndPoint(target.left - current.left, target.top - current.top);
}

/// Where one more item appended to [itemIds] would sit.
///
/// Read from the flow the container already shows: the column count is the
/// index of the first item that starts a new line, and the pitches come from
/// the first pair on either axis. A vertical list is the one-column case of the
/// same reading, so a board column works too.
///
/// Null when there are too few measured items to show a flow; the caller then
/// leaves the last item where it is rather than send it to a slot that may not
/// exist.
DndPoint? _appendedSlotOrigin(Map<DndId, DndRect> rects, List<DndId> itemIds) {
  final flow = <DndRect>[];
  for (final id in itemIds) {
    final rect = rects[id];
    if (rect == null) {
      return null;
    }
    flow.add(rect);
  }
  if (flow.length < 2) {
    return null;
  }

  final last = flow.last;
  for (var index = 1; index < flow.length; index += 1) {
    if (_startsNewLine(flow[index], flow[index - 1])) {
      // The appended item wraps exactly when it would start a new line.
      if (flow.length % index == 0) {
        return DndPoint(
          flow.first.left,
          last.top + flow[index].top - flow.first.top,
        );
      }
      break;
    }
  }

  for (var index = 1; index < flow.length; index += 1) {
    if (!_startsNewLine(flow[index], flow[index - 1])) {
      return DndPoint(
        last.left + flow[index].left - flow[index - 1].left,
        last.top,
      );
    }
  }
  return null;
}

bool _startsNewLine(DndRect rect, DndRect previous) =>
    rect.top > previous.top + 1;
