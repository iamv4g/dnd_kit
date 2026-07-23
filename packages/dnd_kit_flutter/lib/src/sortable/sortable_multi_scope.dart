import 'package:dnd_kit/dnd_kit.dart';
import 'package:flutter/widgets.dart';

import '../scope/controller.dart';
import '../scope/scope.dart';
import '../sensors/long_press_activation.dart';
import '../widgets/draggable.dart';
import '../widgets/droppable.dart';
import 'sortable_item.dart';

/// Provides production multi-container sortable behavior to a subtree.
class SortableMultiScope extends StatefulWidget {
  /// Creates a multi-container sortable scope.
  SortableMultiScope({
    super.key,
    this.controller,
    this.enableHapticFeedback = true,
    this.announcements,
    required Iterable<SortableContainer> containers,
    this.moveResolver,
    this.collisionDetector,
    this.offsetResolver = SortableMultiOffsets.none,
    this.crossContainerInsertion = SortableMultiInsertionStrategy.adaptive,
    required this.onMove,
    required this.child,
  }) : containers = List<SortableContainer>.unmodifiable(containers);

  /// The externally owned drag-and-drop controller for controlled usage.
  final DndController? controller;

  /// Default haptic feedback behavior for descendant draggables.
  final bool enableHapticFeedback;

  /// Optional drag lifecycle announcements for assistive technologies.
  final DndAnnouncements? announcements;

  /// The application-owned multi-container order and membership.
  final List<SortableContainer> containers;

  /// Optional pure-Dart override hook for move-intent resolution.
  final SortableMultiMoveResolver? moveResolver;

  /// Optional override for collision ranking.
  final DndCollisionDetector? collisionDetector;

  /// Reports how far each item a previewed move displaces should shift.
  ///
  /// Defaults to [SortableMultiOffsets.none], which moves nothing. Set
  /// [SortableMultiOffsets.verticalLists] (or `horizontalLists`) to open a live
  /// gap within and across columns, then apply `details.offset` inside your
  /// [SortableMultiItem] builder. Apply it inside the builder so the shift
  /// stays below the measured box and cannot feed back into collision.
  final SortableMultiOffsetResolver offsetResolver;

  /// How cross-container drops resolve around an over-item target.
  final SortableMultiInsertionStrategy crossContainerInsertion;

  /// Called when the library resolves a move intent.
  final SortableMoveCallback onMove;

  /// The sortable subtree.
  final Widget child;

  /// Returns the nearest multi-container scope details, or null when absent.
  static SortableMultiScopeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SortableMultiScopeProvider>()?.data;
  }

  /// Returns the nearest multi-container scope details.
  static SortableMultiScopeData of(BuildContext context) {
    final data = maybeOf(context);
    if (data != null) {
      return data;
    }

    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'SortableMultiScope.of() was called without a SortableMultiScope in the widget tree.',
      ),
      ErrorDescription(
        'No SortableMultiScope ancestor could be found from the provided BuildContext.',
      ),
      ErrorHint('Wrap the multi-container subtree in a SortableMultiScope.'),
    ]);
  }

  @override
  State<SortableMultiScope> createState() => _SortableMultiScopeState();
}

/// A container area's registered reorder strategy and the widget that owns it.
typedef _AreaStrategy = ({Object owner, SortableStrategy strategy});

class _SortableMultiScopeState extends State<SortableMultiScope> {
  DndController? _internalController;
  DndController? _listeningTo;
  late final SortablePreview _preview = SortablePreview.resolvedBy(
    _resolvePreview,
    resolveOffsets: _resolveOffsets,
  );

  /// Reorder strategies published by the container areas in this scope.
  ///
  /// Resolving a preview needs the strategy of the container holding the item
  /// being dragged, but strategies are configured on each
  /// [SortableMultiContainerArea] rather than on the scope, so the areas
  /// register them here. Registration is owner-aware so a rebuilt area cannot
  /// remove an entry a newer area already took over.
  final Map<DndId, _AreaStrategy> _strategies = <DndId, _AreaStrategy>{};

  DndController get _controller => widget.controller ?? _internalController!;

  DndCollisionDetector get _effectiveCollisionDetector {
    return widget.collisionDetector ??
        SortableMultiContainer.collisionDetector(
          containers: () => widget.containers,
        );
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = DndController(
        collisionDetector: _effectiveCollisionDetector,
      );
    }
    _bindController();
  }

  @override
  void didUpdateWidget(SortableMultiScope oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller == null && widget.controller != null) {
      _internalController?.dispose();
      _internalController = null;
    } else if (oldWidget.controller != null && widget.controller == null) {
      _internalController = DndController(
        collisionDetector: _effectiveCollisionDetector,
      );
    } else if (widget.controller == null &&
        oldWidget.collisionDetector != widget.collisionDetector) {
      _internalController?.dispose();
      _internalController = DndController(
        collisionDetector: _effectiveCollisionDetector,
      );
    }

    _bindController();
    // Container membership and the resolver feed the resolution, so a change to
    // either makes the cached preview stale even when the drag has not moved.
    if (oldWidget.offsetResolver != widget.offsetResolver ||
        !_containersEqual(oldWidget.containers, widget.containers)) {
      _preview.invalidate();
    }
  }

  @override
  void dispose() {
    _listeningTo?.removeListener(_preview.invalidate);
    _internalController?.dispose();
    super.dispose();
  }

  void _bindController() {
    final next = _controller;
    if (identical(_listeningTo, next)) {
      return;
    }

    _listeningTo?.removeListener(_preview.invalidate);
    _listeningTo = next;
    next.addListener(_preview.invalidate);
    _preview.invalidate();
  }

  void _registerStrategy(DndId id, SortableStrategy strategy, Object owner) {
    final existing = _strategies[id];
    if (existing != null && existing.owner == owner && existing.strategy == strategy) {
      return;
    }

    _strategies[id] = (owner: owner, strategy: strategy);
    _preview.invalidate();
  }

  void _unregisterStrategy(DndId id, Object owner) {
    if (_strategies[id]?.owner != owner) {
      return;
    }

    _strategies.remove(id);
    _preview.invalidate();
  }

  SortableMoveDetails? _resolvePreview() {
    final controller = _controller;
    final session = controller.activeSession;
    if (session == null || !controller.isDragging) {
      return null;
    }

    // The strategy that matters is the one configured on the container holding
    // the item being dragged, not the container being hovered.
    SortableContainer? sourceContainer;
    for (final container in widget.containers) {
      if (container.contains(session.activeId)) {
        sourceContainer = container;
        break;
      }
    }

    if (sourceContainer == null) {
      return null;
    }

    return _data().resolveDetails(
      SortableDragContext.preview(session: session, overId: controller.overId),
      container: SortableMultiContainerAreaData(
        id: sourceContainer.id,
        itemIds: sourceContainer.itemIds,
        strategy: _strategies[sourceContainer.id]?.strategy ?? SortableStrategies.verticalList,
      ),
      itemRects: controller.measuring.droppableRects,
      activeRect: controller.activeRect,
    );
  }

  Map<DndId, DndPoint> _resolveOffsets() {
    final move = _preview.details;
    if (move == null) {
      return const <DndId, DndPoint>{};
    }

    return widget.offsetResolver(
      SortableMultiOffsetInput(
        activeId: move.activeId,
        containers: widget.containers,
        itemRects: _controller.measuring.droppableRects,
        fromContainerId: move.fromContainerId,
        fromIndex: move.fromIndex,
        toContainerId: move.toContainerId,
        toIndex: move.toIndex,
        activeRect: _controller.activeRect,
      ),
    );
  }

  SortableMultiScopeData _data() {
    return SortableMultiScopeData(
      containers: widget.containers,
      moveResolver: widget.moveResolver,
      crossContainerInsertion: widget.crossContainerInsertion,
      onMove: widget.onMove,
      preview: _preview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DndScope(
      controller: _controller,
      enableHapticFeedback: widget.enableHapticFeedback,
      announcements: widget.announcements,
      child: _SortableMultiStrategyScope(
        state: this,
        child: _SortableMultiScopeProvider(
          data: _data(),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Gives descendant container areas a way to publish their reorder strategy.
class _SortableMultiStrategyScope extends InheritedWidget {
  const _SortableMultiStrategyScope({
    required this.state,
    required super.child,
  });

  final _SortableMultiScopeState state;

  static _SortableMultiScopeState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SortableMultiStrategyScope>()?.state;
  }

  @override
  bool updateShouldNotify(_SortableMultiStrategyScope oldWidget) => state != oldWidget.state;
}

bool _containersEqual(List<SortableContainer> a, List<SortableContainer> b) {
  return _listEquals(a, b);
}

/// Immutable data exposed by [SortableMultiScope].
@immutable
final class SortableMultiScopeData {
  /// Creates multi-container scope data.
  SortableMultiScopeData({
    required Iterable<SortableContainer> containers,
    required this.onMove,
    this.moveResolver,
    this.crossContainerInsertion = SortableMultiInsertionStrategy.adaptive,
    SortablePreview? preview,
  })  : containers = List<SortableContainer>.unmodifiable(containers),
        preview = preview ?? SortablePreview.inactive();

  /// Where the active item would land if the drag were released now.
  ///
  /// Resolved lazily and cached per move, using the reorder strategy of the
  /// container the dragged item came from. Reports nothing when no drag is
  /// active.
  ///
  /// Deliberately excluded from [operator ==]: this is live drag state, not
  /// part of the scope's identity, and the instance is stable for the lifetime
  /// of the scope.
  final SortablePreview preview;

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
class SortableMultiContainerArea extends StatefulWidget {
  /// Creates a multi-container area.
  SortableMultiContainerArea({
    super.key,
    required this.id,
    required Iterable<DndId> itemIds,
    this.strategy = SortableStrategies.verticalList,
    this.disabled = false,
    this.data,
    this.builder,
    required this.child,
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
  final Widget child;

  /// Returns the nearest container-area details, or null when absent.
  static SortableMultiContainerAreaData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SortableMultiContainerAreaProvider>()?.data;
  }

  /// Returns the nearest container-area details.
  static SortableMultiContainerAreaData of(BuildContext context) {
    final data = maybeOf(context);
    if (data != null) {
      return data;
    }

    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'SortableMultiContainerArea.of() was called without a SortableMultiContainerArea in the widget tree.',
      ),
      ErrorDescription(
        'No SortableMultiContainerArea ancestor could be found from the provided BuildContext.',
      ),
      ErrorHint('Wrap sortable items in a SortableMultiContainerArea.'),
    ]);
  }

  @override
  State<SortableMultiContainerArea> createState() => _SortableMultiContainerAreaState();
}

class _SortableMultiContainerAreaState extends State<SortableMultiContainerArea> {
  _SortableMultiScopeState? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _SortableMultiStrategyScope.maybeOf(context);
    if (!identical(_scope, scope)) {
      _scope?._unregisterStrategy(widget.id, this);
      _scope = scope;
    }
    _scope?._registerStrategy(widget.id, widget.strategy, this);
  }

  @override
  void didUpdateWidget(SortableMultiContainerArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _scope?._unregisterStrategy(oldWidget.id, this);
    }
    _scope?._registerStrategy(widget.id, widget.strategy, this);
  }

  @override
  void dispose() {
    _scope?._unregisterStrategy(widget.id, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DndDroppable(
      id: widget.id,
      disabled: widget.disabled,
      data: widget.data,
      builder: widget.builder,
      child: _SortableMultiContainerAreaProvider(
        data: SortableMultiContainerAreaData(
          id: widget.id,
          itemIds: widget.itemIds,
          strategy: widget.strategy,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Immutable data exposed by [SortableMultiContainerArea].
@immutable
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
class SortableMultiItem extends StatelessWidget {
  /// Creates a multi-container sortable item.
  const SortableMultiItem({
    super.key,
    required this.id,
    required this.child,
    this.builder,
    this.disabled = false,
    this.data,
    this.activationConstraint = DndSensorActivationConstraint.none,
    this.longPressActivation,
    this.keyboardDragStep = 25,
    this.hitTestBehavior,
  });

  /// The stable sortable item id.
  final DndId id;

  /// The widget users can drag and drop.
  final Widget child;

  /// Optional visual builder for sortable item state-aware rendering.
  final SortableItemBuilder? builder;

  /// Whether drag and drop behavior should be ignored for this item.
  final bool disabled;

  /// Optional application-owned metadata stored in drag/drop registries.
  final Object? data;

  /// The pointer activation constraint required before a drag starts.
  final DndSensorActivationConstraint activationConstraint;

  /// Optional long-press activation behavior for pointer drags.
  final DndLongPressActivation? longPressActivation;

  /// Logical pixels moved for each keyboard arrow key press.
  final double keyboardDragStep;

  /// How this sortable item participates in hit testing.
  final HitTestBehavior? hitTestBehavior;

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
    SortableMultiScopeData multiScope,
    SortableMultiContainerAreaData container,
    DndDraggableDetails draggable,
    DndController controller,
  ) {
    return SortableItemDetails(
      id: id,
      index: container.indexOf(id),
      disabled: disabled,
      isActive: draggable.isActive,
      isDragging: draggable.isDragging,
      isDropping: draggable.isDropping,
      isOver: controller.overId == id,
      overId: controller.overId,
      session: draggable.session,
      preview: multiScope.preview,
    );
  }

  @override
  Widget build(BuildContext context) {
    final multiScope = SortableMultiScope.of(context);
    final container = SortableMultiContainerArea.of(context);
    final controller = DndScope.of(context);

    return DndDroppable(
      id: id,
      disabled: disabled,
      data: data,
      child: DndDraggable(
        id: id,
        disabled: disabled,
        data: data,
        activationConstraint: activationConstraint,
        longPressActivation: longPressActivation,
        keyboardDragStep: keyboardDragStep,
        hitTestBehavior: hitTestBehavior,
        onDragEnd: (event) => _handleDragEnd(multiScope, container, controller, event),
        builder: builder == null
            ? null
            : (context, draggableDetails, child) {
                return builder!(
                  context,
                  _detailsFor(multiScope, container, draggableDetails, controller),
                  child,
                );
              },
        child: child,
      ),
    );
  }
}

class _SortableMultiScopeProvider extends InheritedWidget {
  const _SortableMultiScopeProvider({
    required this.data,
    required super.child,
  });

  final SortableMultiScopeData data;

  @override
  bool updateShouldNotify(_SortableMultiScopeProvider oldWidget) => data != oldWidget.data;
}

class _SortableMultiContainerAreaProvider extends InheritedWidget {
  const _SortableMultiContainerAreaProvider({
    required this.data,
    required super.child,
  });

  final SortableMultiContainerAreaData data;

  @override
  bool updateShouldNotify(_SortableMultiContainerAreaProvider oldWidget) {
    return data != oldWidget.data;
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
