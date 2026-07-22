import 'package:dnd_kit/dnd_kit.dart';
import 'package:jaspr/jaspr.dart';

import '../scope/controller.dart';
import '../scope/scope.dart';
import '../widgets/draggable.dart';
import '../widgets/droppable.dart';
import 'sortable_item.dart';

/// Provides production multi-container sortable behavior to a Jaspr subtree.
class SortableMultiScope extends StatefulComponent {
  /// Creates a multi-container sortable scope.
  SortableMultiScope({
    this.controller,
    this.announcements = const DndAnnouncements(),
    required Iterable<SortableContainer> containers,
    this.moveResolver,
    this.collisionDetector,
    this.crossContainerInsertion = SortableMultiInsertionStrategy.adaptive,
    required this.onMove,
    required this.child,
    super.key,
  }) : containers = List<SortableContainer>.unmodifiable(containers);

  /// The externally owned drag-and-drop controller for controlled usage.
  final DndController? controller;

  /// Screen-reader announcements provided to descendant live regions.
  final DndAnnouncements announcements;

  /// The application-owned multi-container order and membership.
  final List<SortableContainer> containers;

  /// Optional pure-Dart override hook for move-intent resolution.
  final SortableMultiMoveResolver? moveResolver;

  /// Optional override for collision ranking.
  final DndCollisionDetector? collisionDetector;

  /// How cross-container drops resolve around an over-item target.
  final SortableMultiInsertionStrategy crossContainerInsertion;

  /// Called when the library resolves a move intent.
  final SortableMoveCallback onMove;

  /// The sortable subtree.
  final Component child;

  /// Returns the nearest multi-container scope details, or null when absent.
  static SortableMultiScopeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedComponentOfExactType<_SortableMultiScopeProvider>()?.data;
  }

  /// Returns the nearest multi-container scope details.
  static SortableMultiScopeData of(BuildContext context) {
    final data = maybeOf(context);
    assert(data != null, 'SortableMultiScope.of() called without an enclosing SortableMultiScope.');
    return data!;
  }

  @override
  State<SortableMultiScope> createState() => _SortableMultiScopeState();
}

class _SortableMultiScopeState extends State<SortableMultiScope> {
  DndController? _ownController;

  DndController get _controller => component.controller ?? _ownController!;

  DndCollisionDetector get _effectiveCollisionDetector {
    return component.collisionDetector ??
        SortableMultiContainer.collisionDetector(
          containers: () => component.containers,
        );
  }

  @override
  void initState() {
    super.initState();
    if (component.controller == null) {
      _ownController = DndController(
        collisionDetector: _effectiveCollisionDetector,
      );
    }
  }

  @override
  void didUpdateComponent(SortableMultiScope oldComponent) {
    super.didUpdateComponent(oldComponent);

    if (oldComponent.controller == null && component.controller != null) {
      _ownController?.dispose();
      _ownController = null;
      return;
    }

    if (oldComponent.controller != null && component.controller == null) {
      _ownController = DndController(
        collisionDetector: _effectiveCollisionDetector,
      );
      return;
    }

    if (component.controller == null &&
        oldComponent.collisionDetector != component.collisionDetector) {
      _ownController?.dispose();
      _ownController = DndController(
        collisionDetector: _effectiveCollisionDetector,
      );
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return DndScope(
      controller: _controller,
      announcements: component.announcements,
      child: _SortableMultiScopeProvider(
        data: SortableMultiScopeData(
          containers: component.containers,
          moveResolver: component.moveResolver,
          crossContainerInsertion: component.crossContainerInsertion,
          onMove: component.onMove,
        ),
        child: component.child,
      ),
    );
  }
}

/// Immutable data exposed by [SortableMultiScope].
final class SortableMultiScopeData {
  /// Creates multi-container scope data.
  SortableMultiScopeData({
    required Iterable<SortableContainer> containers,
    required this.onMove,
    this.moveResolver,
    this.crossContainerInsertion = SortableMultiInsertionStrategy.adaptive,
  }) : containers = List<SortableContainer>.unmodifiable(containers);

  /// The application-owned container order and membership.
  final List<SortableContainer> containers;

  /// Optional override hook for move-intent resolution.
  final SortableMultiMoveResolver? moveResolver;

  /// How cross-container drops resolve around an over-item target.
  final SortableMultiInsertionStrategy crossContainerInsertion;

  /// Called when the library resolves a move intent.
  final SortableMoveCallback onMove;

  /// Returns the current container for [containerId], or null when unknown.
  SortableContainer? containerById(DndId containerId) {
    for (final container in containers) {
      if (container.id == containerId) {
        return container;
      }
    }
    return null;
  }

  /// Builds move intent details for [event] from the current controller state.
  SortableMoveDetails? moveDetailsFor(
    DndDragEndEvent event, {
    required SortableMultiContainerAreaData container,
    Map<DndId, DndRect> itemRects = const <DndId, DndRect>{},
    DndRect? activeRect,
  }) {
    return resolveDetails(
      SortableDragContext.commit(event),
      container: container,
      itemRects: itemRects,
      activeRect: activeRect,
    );
  }

  /// Resolves move intent for [context].
  ///
  /// Serves both drag phases: a preview context reports where the item would
  /// land right now, a commit context reports the move to apply.
  SortableMoveDetails? resolveDetails(
    SortableDragContext context, {
    required SortableMultiContainerAreaData container,
    Map<DndId, DndRect> itemRects = const <DndId, DndRect>{},
    DndRect? activeRect,
  }) {
    final input = SortableMultiMoveInput(
      context: context,
      containers: containers,
      itemRects: itemRects,
      activeRect: activeRect,
      strategy: container.strategy,
      crossContainerInsertion: crossContainerInsertion,
    );

    return moveResolver?.call(input) ?? SortableMultiContainer.resolveMove(input);
  }

  @override
  bool operator ==(Object other) {
    return other is SortableMultiScopeData &&
        _listEquals(other.containers, containers) &&
        other.moveResolver == moveResolver &&
        other.crossContainerInsertion == crossContainerInsertion &&
        other.onMove == onMove;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(containers),
        moveResolver,
        crossContainerInsertion,
        onMove,
      );
}

/// Registers a sortable container area for the common multi-container case.
class SortableMultiContainerArea extends StatelessComponent {
  /// Creates a multi-container area.
  SortableMultiContainerArea({
    required this.id,
    required Iterable<DndId> itemIds,
    this.strategy = SortableStrategies.verticalList,
    this.disabled = false,
    this.data,
    this.builder,
    required this.child,
    super.key,
  }) : itemIds = List<DndId>.unmodifiable(itemIds);

  /// The stable container id.
  final DndId id;

  /// The application-owned item order for this container.
  final List<DndId> itemIds;

  /// Computes same-container reorder intent from measured item layout.
  final SortableStrategy strategy;

  /// Whether this container should be ignored by drag/drop runtimes.
  final bool disabled;

  /// Optional application-owned metadata stored in drag/drop registries.
  final Object? data;

  /// Optional visual builder for drag-over state-aware rendering.
  final DndDroppableBuilder? builder;

  /// The container subtree.
  final Component child;

  /// Returns the nearest container-area details, or null when absent.
  static SortableMultiContainerAreaData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<_SortableMultiContainerAreaProvider>()
        ?.data;
  }

  /// Returns the nearest container-area details.
  static SortableMultiContainerAreaData of(BuildContext context) {
    final data = maybeOf(context);
    assert(
      data != null,
      'SortableMultiContainerArea.of() called without an enclosing SortableMultiContainerArea.',
    );
    return data!;
  }

  @override
  Component build(BuildContext context) {
    return DndDroppable(
      id: id,
      disabled: disabled,
      data: data,
      builder: builder,
      child: _SortableMultiContainerAreaProvider(
        data: SortableMultiContainerAreaData(
          id: id,
          itemIds: itemIds,
          strategy: strategy,
        ),
        child: child,
      ),
    );
  }
}

/// Immutable data exposed by [SortableMultiContainerArea].
final class SortableMultiContainerAreaData {
  /// Creates container-area data.
  SortableMultiContainerAreaData({
    required this.id,
    required Iterable<DndId> itemIds,
    this.strategy = SortableStrategies.verticalList,
  }) : itemIds = List<DndId>.unmodifiable(itemIds);

  /// The stable container id.
  final DndId id;

  /// The application-owned item order for this container.
  final List<DndId> itemIds;

  /// Computes same-container reorder intent from measured item layout.
  final SortableStrategy strategy;

  /// Returns the current index for [itemId], or -1 when absent.
  int indexOf(DndId itemId) => itemIds.indexOf(itemId);

  @override
  bool operator ==(Object other) {
    return other is SortableMultiContainerAreaData &&
        other.id == id &&
        other.strategy == strategy &&
        _listEquals(other.itemIds, itemIds);
  }

  @override
  int get hashCode => Object.hash(id, strategy, Object.hashAll(itemIds));
}

/// Registers a child as a sortable item in the nearest [SortableMultiScope].
class SortableMultiItem extends StatelessComponent {
  /// Creates a multi-container sortable item.
  const SortableMultiItem({
    required this.id,
    required this.child,
    this.builder,
    this.disabled = false,
    this.data,
    this.constraint = DndSensorActivationConstraint.none,
    this.keyboardDragStep = 25,
    this.label,
    this.description,
    super.key,
  });

  /// The stable sortable item id.
  final DndId id;

  /// The component users can drag and drop.
  final Component child;

  /// Optional visual builder for sortable item state-aware rendering.
  final SortableItemBuilder? builder;

  /// Whether drag and drop behavior should be ignored for this item.
  final bool disabled;

  /// Optional application-owned metadata stored in drag/drop registries.
  final Object? data;

  /// The activation constraint applied before a pointer drag starts.
  final DndSensorActivationConstraint constraint;

  /// Logical pixels moved for each keyboard arrow key press.
  final double keyboardDragStep;

  /// Optional accessible label applied to the draggable as `aria-label`.
  final String? label;

  /// Optional keyboard-usage instructions exposed to assistive tech.
  final String? description;

  void _handleDragEnd(
    SortableMultiScopeData multiScope,
    SortableMultiContainerAreaData container,
    DndController controller,
    DndDragEndEvent event,
  ) {
    final details = multiScope.moveDetailsFor(
      event,
      container: container,
      itemRects: controller.measuring.droppableRects,
      activeRect: controller.activeRect,
    );
    if (details != null) {
      multiScope.onMove(details);
    }
  }

  SortableItemDetails _detailsFor(
    SortableMultiContainerAreaData container,
    DndController controller,
  ) {
    final state = controller.state;
    return SortableItemDetails(
      id: id,
      index: container.indexOf(id),
      disabled: disabled,
      isActive: controller.activeId == id,
      isDragging: state is DndDragging && state.session.activeId == id,
      isDropping: state is DndDropping && state.session.activeId == id,
      isOver: controller.overId == id,
      overId: controller.overId,
      session: controller.activeSession,
    );
  }

  @override
  Component build(BuildContext context) {
    final multiScope = SortableMultiScope.of(context);
    final container = SortableMultiContainerArea.of(context);
    final controller = DndScope.of(context);
    final itemBuilder = builder;

    return DndDroppable(
      id: id,
      disabled: disabled,
      data: data,
      builder: itemBuilder == null
          ? null
          : (innerContext, _, droppableChild) {
              return itemBuilder(
                innerContext,
                _detailsFor(container, controller),
                droppableChild,
              );
            },
      child: DndDraggable(
        id: id,
        disabled: disabled,
        data: data,
        constraint: constraint,
        keyboardDragStep: keyboardDragStep,
        label: label,
        description: description,
        onDragEnd: (event) => _handleDragEnd(multiScope, container, controller, event),
        child: child,
      ),
    );
  }
}

class _SortableMultiScopeProvider extends InheritedComponent {
  const _SortableMultiScopeProvider({
    required this.data,
    required super.child,
  });

  final SortableMultiScopeData data;

  @override
  bool updateShouldNotify(_SortableMultiScopeProvider oldComponent) => data != oldComponent.data;
}

class _SortableMultiContainerAreaProvider extends InheritedComponent {
  const _SortableMultiContainerAreaProvider({
    required this.data,
    required super.child,
  });

  final SortableMultiContainerAreaData data;

  @override
  bool updateShouldNotify(_SortableMultiContainerAreaProvider oldComponent) {
    return data != oldComponent.data;
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
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
