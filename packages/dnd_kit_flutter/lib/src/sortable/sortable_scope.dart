import 'package:dnd_kit/dnd_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../scope/controller.dart';
import '../scope/scope.dart';

/// Provides sortable order and drag controller state to a subtree.
class SortableScope extends StatelessWidget {
  /// Creates a sortable scope.
  SortableScope({
    super.key,
    this.controller,
    this.containerId,
    this.strategy = SortableStrategies.verticalList,
    required Iterable<DndId> itemIds,
    this.onMove,
    required this.child,
  }) : itemIds = List<DndId>.unmodifiable(itemIds);

  /// The externally owned drag-and-drop controller for controlled usage.
  ///
  /// When omitted, the underlying [DndScope] creates and disposes an internal
  /// controller.
  final DndController? controller;

  /// Optional sortable container id for future multi-container APIs.
  final DndId? containerId;

  /// Computes reorder intent from the drag end event and measured item layout.
  final SortableStrategy strategy;

  /// The application-owned item order.
  final List<DndId> itemIds;

  /// Called when a sortable item is dropped over another item in this scope.
  final SortableMoveCallback? onMove;

  /// The sortable subtree.
  final Widget child;

  /// Returns the nearest sortable scope details, or null when no scope exists.
  static SortableScopeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SortableScope>()?.data;
  }

  /// Returns the nearest sortable scope details.
  ///
  /// Throws a [FlutterError] when called outside a [SortableScope].
  static SortableScopeData of(BuildContext context) {
    final data = maybeOf(context);
    if (data != null) {
      return data;
    }

    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('SortableScope.of() was called without a SortableScope in the widget tree.'),
      ErrorDescription(
        'No SortableScope ancestor could be found from the provided BuildContext.',
      ),
      ErrorHint('Wrap the sortable subtree in a SortableScope.'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DndScope(
      controller: controller,
      child: _SortablePreviewHost(
        containerId: containerId,
        strategy: strategy,
        itemIds: itemIds,
        onMove: onMove,
        child: child,
      ),
    );
  }
}

/// Owns the scope's [SortablePreview] and keeps it in step with the controller.
///
/// This lives below [DndScope] so it can reach the controller that scope may
/// have created, and it is stateful so the preview instance — and therefore its
/// cache — survives rebuilds.
class _SortablePreviewHost extends StatefulWidget {
  const _SortablePreviewHost({
    required this.containerId,
    required this.strategy,
    required this.itemIds,
    required this.onMove,
    required this.child,
  });

  final DndId? containerId;
  final SortableStrategy strategy;
  final List<DndId> itemIds;
  final SortableMoveCallback? onMove;
  final Widget child;

  @override
  State<_SortablePreviewHost> createState() => _SortablePreviewHostState();
}

class _SortablePreviewHostState extends State<_SortablePreviewHost> {
  late final SortablePreview _preview = SortablePreview.resolvedBy(_resolvePreview);
  DndController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DndScope.of(context);
    if (identical(_controller, controller)) {
      return;
    }

    _controller?.removeListener(_preview.invalidate);
    _controller = controller;
    _controller?.addListener(_preview.invalidate);
    _preview.invalidate();
  }

  @override
  void didUpdateWidget(_SortablePreviewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Item order and strategy feed the resolution, so a change to either makes
    // the cached preview stale even when the drag itself has not moved.
    if (oldWidget.strategy != widget.strategy || !listEquals(oldWidget.itemIds, widget.itemIds)) {
      _preview.invalidate();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_preview.invalidate);
    super.dispose();
  }

  SortableScopeData _data() {
    return SortableScopeData(
      containerId: widget.containerId,
      strategy: widget.strategy,
      itemIds: widget.itemIds,
      onMove: widget.onMove,
      preview: _preview,
    );
  }

  SortableMoveDetails? _resolvePreview() {
    final controller = _controller;
    final session = controller?.activeSession;
    if (controller == null || session == null || !controller.isDragging) {
      return null;
    }

    return _data().resolveDetails(
      SortableDragContext.preview(session: session, overId: controller.overId),
      itemRects: controller.measuring.droppableRects,
      activeRect: controller.activeRect,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SortableScope(
      data: _data(),
      child: widget.child,
    );
  }
}

/// Immutable data exposed by [SortableScope].
@immutable
final class SortableScopeData {
  /// Creates sortable scope data.
  SortableScopeData({
    required Iterable<DndId> itemIds,
    this.strategy = SortableStrategies.verticalList,
    this.containerId,
    this.onMove,
    SortablePreview? preview,
  })  : itemIds = List<DndId>.unmodifiable(itemIds),
        preview = preview ?? SortablePreview.inactive();

  /// Where the active item would land if the drag were released now.
  ///
  /// Resolved lazily and cached per move, so reading it from many items costs
  /// one resolution. Reports nothing when no drag is active.
  ///
  /// Deliberately excluded from [operator ==]: this is live drag state, not
  /// part of the scope's identity, and the instance is stable for the lifetime
  /// of the scope.
  final SortablePreview preview;

  /// Optional sortable container id for future multi-container APIs.
  final DndId? containerId;

  /// Computes reorder intent from the drag end event and measured item layout.
  final SortableStrategy strategy;

  /// The application-owned item order.
  final List<DndId> itemIds;

  /// Called when a sortable item is dropped over another item in this scope.
  final SortableMoveCallback? onMove;

  /// Returns the current index for [id], or -1 when the item is outside this scope.
  int indexOf(DndId id) => itemIds.indexOf(id);

  /// Builds move intent details for [event], when the drop is a same-scope move.
  SortableMoveDetails? moveDetailsFor(
    DndDragEndEvent event, {
    Map<DndId, DndRect> itemRects = const <DndId, DndRect>{},
    DndRect? activeRect,
  }) {
    return resolveDetails(
      SortableDragContext.commit(event),
      itemRects: itemRects,
      activeRect: activeRect,
    );
  }

  /// Resolves same-scope move intent for [context].
  ///
  /// Serves both drag phases: a preview context reports where the item would
  /// land right now, a commit context reports the move to apply. Both run the
  /// same [strategy] over the same input, so a preview and the move that
  /// follows it cannot disagree.
  SortableMoveDetails? resolveDetails(
    SortableDragContext context, {
    Map<DndId, DndRect> itemRects = const <DndId, DndRect>{},
    DndRect? activeRect,
  }) {
    final overId = context.overId;
    if (overId == null || overId == context.activeId) {
      return null;
    }

    final fromIndex = indexOf(context.activeId);
    final toIndex = indexOf(overId);
    if (fromIndex < 0 || toIndex < 0) {
      return null;
    }

    return strategy(
      SortableStrategyInput(
        activeId: context.activeId,
        overId: overId,
        itemIds: itemIds,
        itemRects: itemRects,
        fromIndex: fromIndex,
        fromContainerId: containerId,
        toContainerId: containerId,
        context: context,
        activeRect: activeRect,
        activeTranslatedRect: activeRect?.translate(context.transform.offset),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SortableScopeData &&
        listEquals(other.itemIds, itemIds) &&
        other.containerId == containerId &&
        other.strategy == strategy &&
        other.onMove == onMove;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(itemIds),
        containerId,
        strategy,
        onMove,
      );

  @override
  String toString() {
    return 'SortableScopeData(containerId: $containerId, itemIds: $itemIds)';
  }
}

class _SortableScope extends InheritedWidget {
  const _SortableScope({
    required this.data,
    required super.child,
  });

  final SortableScopeData data;

  @override
  bool updateShouldNotify(_SortableScope oldWidget) => data != oldWidget.data;
}
