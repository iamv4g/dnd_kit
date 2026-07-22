import 'package:meta/meta.dart';

import 'collision.dart';
import 'events.dart';
import 'geometry.dart';
import 'id.dart';
import 'sortable.dart';

/// Sortable container metadata for multi-container sorting.
///
/// Applications own the actual container and item collections. This model only
/// describes the current order so dnd_kit can report move intent.
@immutable
final class SortableContainer {
  /// Creates sortable container metadata.
  SortableContainer({
    required this.id,
    required Iterable<DndId> itemIds,
  }) : itemIds = List<DndId>.unmodifiable(itemIds);

  /// The stable container id.
  final DndId id;

  /// The application-owned item order inside this container.
  final List<DndId> itemIds;

  /// Returns the current index for [itemId], or -1 when absent.
  int indexOf(DndId itemId) => itemIds.indexOf(itemId);

  /// Whether this container contains [itemId].
  bool contains(DndId itemId) => indexOf(itemId) >= 0;

  @override
  bool operator ==(Object other) {
    return other is SortableContainer && other.id == id && _listEquals(other.itemIds, itemIds);
  }

  @override
  int get hashCode => Object.hash(id, Object.hashAll(itemIds));

  @override
  String toString() {
    return 'SortableContainer(id: $id, itemIds: $itemIds)';
  }
}

/// How cross-container drops resolve around an over-item target.
enum SortableMultiInsertionStrategy {
  /// Insert before the item currently under the drag.
  beforeOverItem,

  /// Insert after the item currently under the drag.
  afterOverItem,

  /// Insert before/after using the active translated rect and container axis.
  adaptive,
}

/// Pure-Dart input used to resolve multi-container move intent.
@immutable
final class SortableMultiMoveInput {
  /// Creates multi-container move input.
  SortableMultiMoveInput({
    required this.context,
    required Iterable<SortableContainer> containers,
    this.itemRects = const <DndId, DndRect>{},
    this.activeRect,
    this.strategy = SortableStrategies.verticalList,
    this.crossContainerInsertion = SortableMultiInsertionStrategy.adaptive,
  }) : containers = List<SortableContainer>.unmodifiable(containers);

  /// Creates multi-container input for a drag that has ended.
  factory SortableMultiMoveInput.fromDragEnd({
    required DndDragEndEvent event,
    required Iterable<SortableContainer> containers,
    Map<DndId, DndRect> itemRects = const <DndId, DndRect>{},
    DndRect? activeRect,
    SortableStrategy strategy = SortableStrategies.verticalList,
    SortableMultiInsertionStrategy crossContainerInsertion =
        SortableMultiInsertionStrategy.adaptive,
  }) {
    return SortableMultiMoveInput(
      context: SortableDragContext.commit(event),
      containers: containers,
      itemRects: itemRects,
      activeRect: activeRect,
      strategy: strategy,
      crossContainerInsertion: crossContainerInsertion,
    );
  }

  /// The drag to resolve, and which phase it is in.
  final SortableDragContext context;

  /// The drag end event to resolve.
  ///
  /// Null while a drag is still active, because a preview has no end event
  /// yet.
  @Deprecated(
    'Use context (SortableDragContext) instead. This getter is null during '
    'preview resolutions and will be removed in a future release.',
  )
  DndDragEndEvent? get event => context.endEvent;

  /// The application-owned container order and item membership.
  final List<SortableContainer> containers;

  /// Measured item rectangles keyed by sortable item id.
  final Map<DndId, DndRect> itemRects;

  /// The measured active draggable rect before translation, when known.
  final DndRect? activeRect;

  /// The same-container sortable strategy for each container list.
  final SortableStrategy strategy;

  /// How cross-container drops resolve around an item target.
  final SortableMultiInsertionStrategy crossContainerInsertion;

  /// The active rect translated by the drag session transform, when known.
  DndRect? get activeTranslatedRect {
    final activeRect = this.activeRect;
    if (activeRect == null) {
      return null;
    }

    return activeRect.translate(context.transform.offset);
  }
}

/// Resolves multi-container move intent from pure-Dart input.
typedef SortableMultiMoveResolver = SortableMoveDetails? Function(
  SortableMultiMoveInput input,
);

/// Helpers for production multi-container sortable semantics.
abstract final class SortableMultiContainer {
  /// Builds a default collision detector for multi-container boards/lists.
  ///
  /// Pointer hits prefer item droppables over container droppables so a card
  /// dropped inside a populated column resolves to the card it is over, not the
  /// whole column behind it. When the pointer is not inside any droppable, the
  /// [fallback] detector decides the ranking.
  static DndCollisionDetector collisionDetector({
    required Iterable<SortableContainer> Function() containers,
    DndCollisionDetector fallback = DndCollisionDetectors.closestCenter,
    int fallbackLimit = 3,
  }) {
    final limit = fallbackLimit < 1 ? 1 : fallbackLimit;
    return (input) {
      final snapshot = List<SortableContainer>.unmodifiable(containers());
      final pointerWithin = DndCollisionDetectors.pointerWithin(input);
      final prioritizedPointer = _prioritizePointerCollisions(pointerWithin, snapshot);
      if (prioritizedPointer.isNotEmpty) {
        return prioritizedPointer;
      }

      final fallbackResult = fallback(input);
      if (fallbackResult.collisions.length <= limit) {
        return fallbackResult;
      }

      return DndCollisionResult(fallbackResult.collisions.take(limit));
    };
  }

  /// Builds move intent details for a drag ending over an item or container.
  ///
  /// If the event's `overId` is a container id, the move targets the end of
  /// that container. If `overId` is an item id, same-container moves use the
  /// configured [strategy] and cross-container moves use the configured
  /// [crossContainerInsertion] behavior.
  static SortableMoveDetails? moveDetailsFor(
    DndDragEndEvent event, {
    required Iterable<SortableContainer> containers,
    Map<DndId, DndRect> itemRects = const <DndId, DndRect>{},
    DndRect? activeRect,
    SortableStrategy strategy = SortableStrategies.verticalList,
    SortableMultiInsertionStrategy crossContainerInsertion =
        SortableMultiInsertionStrategy.adaptive,
  }) {
    return resolveMove(
      SortableMultiMoveInput.fromDragEnd(
        event: event,
        containers: containers,
        itemRects: itemRects,
        activeRect: activeRect,
        strategy: strategy,
        crossContainerInsertion: crossContainerInsertion,
      ),
    );
  }

  /// Resolves move intent for [input].
  static SortableMoveDetails? resolveMove(SortableMultiMoveInput input) {
    final context = input.context;
    final overId = context.overId;
    if (overId == null || overId == context.activeId) {
      return null;
    }

    final fromContainer = _containerContaining(input.containers, context.activeId);
    final target = _targetFor(input.containers, overId);
    if (fromContainer == null || target == null) {
      return null;
    }

    final fromIndex = fromContainer.indexOf(context.activeId);
    if (fromIndex < 0) {
      return null;
    }

    final toContainer = target.container;
    if (fromContainer.id == toContainer.id && !target.overContainer) {
      return input.strategy(
        SortableStrategyInput(
          activeId: context.activeId,
          overId: overId,
          itemIds: toContainer.itemIds,
          itemRects: input.itemRects,
          fromIndex: fromIndex,
          fromContainerId: fromContainer.id,
          toContainerId: toContainer.id,
          context: context,
          activeRect: input.activeRect,
          activeTranslatedRect: input.activeTranslatedRect,
        ),
      );
    }

    var toIndex = target.index;
    if (fromContainer.id == toContainer.id && target.overContainer) {
      toIndex = (toIndex - 1).clamp(0, toContainer.itemIds.length).toInt();
    } else if (fromContainer.id != toContainer.id && !target.overContainer) {
      toIndex = _crossContainerIndex(input, target);
    }

    if (fromContainer.id == toContainer.id && fromIndex == toIndex) {
      return null;
    }

    return SortableMoveDetails(
      activeId: context.activeId,
      overId: overId,
      fromContainerId: fromContainer.id,
      toContainerId: toContainer.id,
      fromIndex: fromIndex,
      toIndex: toIndex,
      event: context.endEvent,
    );
  }

  static SortableContainer? _containerContaining(
    List<SortableContainer> containers,
    DndId itemId,
  ) {
    for (final container in containers) {
      if (container.contains(itemId)) {
        return container;
      }
    }
    return null;
  }

  static _SortableTarget? _targetFor(
    List<SortableContainer> containers,
    DndId overId,
  ) {
    for (final container in containers) {
      if (container.id == overId) {
        return _SortableTarget(
          container: container,
          index: container.itemIds.length,
          overContainer: true,
        );
      }

      final itemIndex = container.indexOf(overId);
      if (itemIndex >= 0) {
        return _SortableTarget(
          container: container,
          index: itemIndex,
          overContainer: false,
        );
      }
    }
    return null;
  }

  static DndCollisionResult _prioritizePointerCollisions(
    DndCollisionResult result,
    List<SortableContainer> containers,
  ) {
    if (result.isEmpty) {
      return result;
    }

    final containerIds = <DndId>{for (final container in containers) container.id};
    final itemIds = <DndId>{
      for (final container in containers) ...container.itemIds,
    };

    final itemCollisions = result.collisions.where((collision) => itemIds.contains(collision.id));
    if (itemCollisions.isNotEmpty) {
      return DndCollisionResult(itemCollisions);
    }

    final containerCollisions = result.collisions.where(
      (collision) => containerIds.contains(collision.id),
    );
    if (containerCollisions.isNotEmpty) {
      return DndCollisionResult(containerCollisions);
    }

    return result;
  }

  static int _crossContainerIndex(
    SortableMultiMoveInput input,
    _SortableTarget target,
  ) {
    final baseIndex = target.index;
    switch (input.crossContainerInsertion) {
      case SortableMultiInsertionStrategy.beforeOverItem:
        return baseIndex;
      case SortableMultiInsertionStrategy.afterOverItem:
        return baseIndex + 1;
      case SortableMultiInsertionStrategy.adaptive:
        final activeTranslatedRect = input.activeTranslatedRect;
        final overId = input.context.overId;
        final overRect = overId == null ? null : input.itemRects[overId];
        if (activeTranslatedRect == null || overRect == null) {
          return baseIndex;
        }

        return _shouldInsertAfter(
          strategy: input.strategy,
          activeTranslatedRect: activeTranslatedRect,
          overRect: overRect,
        )
            ? baseIndex + 1
            : baseIndex;
    }
  }

  static bool _shouldInsertAfter({
    required SortableStrategy strategy,
    required DndRect activeTranslatedRect,
    required DndRect overRect,
  }) {
    final activeCenter = activeTranslatedRect.center;
    final overCenter = overRect.center;

    if (identical(strategy, SortableStrategies.horizontalList)) {
      return activeCenter.x > overCenter.x;
    }

    if (identical(strategy, SortableStrategies.grid)) {
      final deltaY = activeCenter.y - overCenter.y;
      if (deltaY.abs() > overRect.height / 2) {
        return deltaY > 0;
      }

      return activeCenter.x > overCenter.x;
    }

    return activeCenter.y > overCenter.y;
  }
}

bool _listEquals(List<DndId> a, List<DndId> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

final class _SortableTarget {
  const _SortableTarget({
    required this.container,
    required this.index,
    required this.overContainer,
  });

  final SortableContainer container;
  final int index;
  final bool overContainer;
}
