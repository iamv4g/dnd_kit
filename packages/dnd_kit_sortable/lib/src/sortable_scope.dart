import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'sortable_details.dart';

/// Provides sortable order and drag controller state to a subtree.
class SortableScope extends StatelessWidget {
  /// Creates a sortable scope.
  SortableScope({
    super.key,
    this.controller,
    this.containerId,
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
      child: _SortableScope(
        data: SortableScopeData(
          containerId: containerId,
          itemIds: itemIds,
          onMove: onMove,
        ),
        child: child,
      ),
    );
  }
}

/// Immutable data exposed by [SortableScope].
@immutable
final class SortableScopeData {
  /// Creates sortable scope data.
  SortableScopeData({
    required Iterable<DndId> itemIds,
    this.containerId,
    this.onMove,
  }) : itemIds = List<DndId>.unmodifiable(itemIds);

  /// Optional sortable container id for future multi-container APIs.
  final DndId? containerId;

  /// The application-owned item order.
  final List<DndId> itemIds;

  /// Called when a sortable item is dropped over another item in this scope.
  final SortableMoveCallback? onMove;

  /// Returns the current index for [id], or -1 when the item is outside this scope.
  int indexOf(DndId id) => itemIds.indexOf(id);

  /// Builds move intent details for [event], when the drop is a same-scope move.
  SortableMoveDetails? moveDetailsFor(DndDragEndEvent event) {
    final overId = event.overId;
    if (overId == null || overId == event.activeId) {
      return null;
    }

    final oldIndex = indexOf(event.activeId);
    final newIndex = indexOf(overId);
    if (oldIndex < 0 || newIndex < 0) {
      return null;
    }

    return SortableMoveDetails(
      activeId: event.activeId,
      overId: overId,
      oldIndex: oldIndex,
      newIndex: newIndex,
      containerId: containerId,
      event: event,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SortableScopeData &&
        listEquals(other.itemIds, itemIds) &&
        other.containerId == containerId &&
        other.onMove == onMove;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(itemIds), containerId, onMove);

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
