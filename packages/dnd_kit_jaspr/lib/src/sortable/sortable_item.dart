import 'package:dnd_kit/dnd_kit.dart';
import 'package:jaspr/jaspr.dart';

import '../scope/controller.dart';
import '../scope/scope.dart';
import '../widgets/draggable.dart';
import '../widgets/droppable.dart';
import 'sortable_scope.dart';

/// Builds a sortable item visual from current drag state.
typedef SortableItemBuilder = Component Function(
  BuildContext context,
  SortableItemDetails details,
  Component child,
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
    this.preview,
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

  /// The scope's live preview, when a sortable scope is driving one.
  ///
  /// Reading [previewIndex] or [previewContainerId] resolves it once per move
  /// and shares that result with every other item, so it is safe to read from
  /// each item's builder.
  final SortablePreview? preview;

  /// The index the active item would land at if released now.
  ///
  /// Null when no drag is active or the drag would not move anything. Unlike
  /// [isOver], which reports the raw collision result, this is the index the
  /// scope's strategy will actually commit to.
  int? get previewIndex => preview?.index;

  /// The container the active item would land in if released now.
  DndId? get previewContainerId => preview?.containerId;
}

/// Registers a child as a sortable item in the nearest [SortableScope].
///
/// `SortableItem` mirrors the Flutter adapter's sortable item: it composes a
/// [DndDroppable] over a [DndDraggable] and, on drag end, asks the enclosing
/// [SortableScope]'s shared engine strategy for a [SortableMoveDetails] reorder
/// intent. Optional [builder] rendering rebuilds with live drag state because
/// the droppable layer listens to the controller.
class SortableItem extends StatelessComponent {
  /// Creates a sortable item wrapping [child].
  const SortableItem({
    super.key,
    required this.id,
    required this.child,
    this.builder,
    this.disabled = false,
    this.data,
    this.constraint = DndSensorActivationConstraint.none,
    this.keyboardDragStep = 25,
    this.label,
    this.description,
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
    DndController controller,
  ) {
    final state = controller.state;
    return SortableItemDetails(
      id: id,
      index: scope.indexOf(id),
      disabled: disabled,
      isActive: controller.activeId == id,
      isDragging: state is DndDragging && state.session.activeId == id,
      isDropping: state is DndDropping && state.session.activeId == id,
      isOver: controller.overId == id,
      overId: controller.overId,
      session: controller.activeSession,
      preview: scope.preview,
    );
  }

  @override
  Component build(BuildContext context) {
    final scope = SortableScope.of(context);
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
                _detailsFor(scope, controller),
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
        onDragEnd: (event) => _handleDragEnd(scope, controller, event),
        child: child,
      ),
    );
  }
}
