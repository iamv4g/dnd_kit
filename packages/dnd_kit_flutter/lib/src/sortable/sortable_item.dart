import 'package:dnd_kit/dnd_kit.dart';
import 'package:flutter/widgets.dart';

import '../scope/controller.dart';
import '../scope/scope.dart';
import '../sensors/long_press_activation.dart';
import '../widgets/draggable.dart';
import '../widgets/droppable.dart';
import 'sortable_scope.dart';

/// Builds a sortable item visual from current drag state.
typedef SortableItemBuilder = Widget Function(
  BuildContext context,
  SortableItemDetails details,
  Widget child,
);

/// State exposed to a [SortableItemBuilder].
final class SortableItemDetails {
  /// Creates sortable item visual state details.
  const SortableItemDetails({
    required this.id,
    required this.index,
    required this.disabled,
    required this.isActive,
    required this.isDragging,
    required this.isDropping,
    required this.isOver,
    required this.overId,
    required this.session,
  });

  /// The stable sortable item id.
  final DndId id;

  /// The item's index in the nearest sortable scope.
  final int index;

  /// Whether drag and drop behavior is disabled for this item.
  final bool disabled;

  /// Whether this item is the active drag source.
  final bool isActive;

  /// Whether this item is actively dragging.
  final bool isDragging;

  /// Whether this item is completing a drop.
  final bool isDropping;

  /// Whether the active drag is currently over this item.
  final bool isOver;

  /// The sortable item currently under the active drag, when one exists.
  final DndId? overId;

  /// The active session for this item, when available.
  final DndDragSession? session;
}

/// Registers a child as a sortable item in the nearest [SortableScope].
class SortableItem extends StatelessWidget {
  /// Creates a sortable item.
  const SortableItem({
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
    SortableScopeData scope,
    DndController controller,
    DndDragEndEvent event,
  ) {
    final details = scope.moveDetailsFor(
      event,
      itemRects: controller.measuring.droppableRects,
      activeRect: controller.activeRect,
    );
    if (details != null) {
      scope.onMove?.call(details);
    }
  }

  SortableItemDetails _detailsFor(
    SortableScopeData scope,
    DndDraggableDetails draggable,
    DndController controller,
  ) {
    return SortableItemDetails(
      id: id,
      index: scope.indexOf(id),
      disabled: disabled,
      isActive: draggable.isActive,
      isDragging: draggable.isDragging,
      isDropping: draggable.isDropping,
      isOver: controller.overId == id,
      overId: controller.overId,
      session: draggable.session,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = SortableScope.of(context);
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
        onDragEnd: (event) => _handleDragEnd(scope, controller, event),
        builder: builder == null
            ? null
            : (context, draggableDetails, child) {
                return builder!(
                  context,
                  _detailsFor(scope, draggableDetails, controller),
                  child,
                );
              },
        child: child,
      ),
    );
  }
}
