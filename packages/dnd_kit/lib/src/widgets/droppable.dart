import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:flutter/widgets.dart';

import '../measuring/measuring.dart';
import '../scope/controller.dart';
import '../scope/scope.dart';

/// Builds a droppable visual from the current drag state.
typedef DndDroppableBuilder = Widget Function(
  BuildContext context,
  DndDroppableDetails details,
  Widget child,
);

/// State exposed to a [DndDroppableBuilder].
final class DndDroppableDetails {
  /// Creates droppable visual state details.
  const DndDroppableDetails({
    required this.id,
    required this.disabled,
    required this.isOver,
    required this.activeId,
    required this.session,
  });

  /// The stable droppable id.
  final DndId id;

  /// Whether this droppable is ignored by drag/drop runtimes.
  final bool disabled;

  /// Whether this droppable is the current collision target.
  final bool isOver;

  /// The active draggable id, when a drag is pending, active, dropping, or cancelled.
  final DndId? activeId;

  /// The active session when a drag is moving or dropping.
  final DndDragSession? session;
}

/// Registers a child as a droppable target in the nearest drag-and-drop scope.
class DndDroppable extends StatefulWidget {
  /// Creates a droppable widget.
  const DndDroppable({
    super.key,
    required this.id,
    required this.child,
    this.builder,
    this.disabled = false,
    this.data,
  });

  /// The stable droppable id.
  final DndId id;

  /// The widget users can drop over.
  final Widget child;

  /// Optional visual builder for drag-over state-aware rendering.
  final DndDroppableBuilder? builder;

  /// Whether this droppable should be ignored by drag/drop runtimes.
  final bool disabled;

  /// Optional application-owned metadata stored in the controller registry.
  final Object? data;

  @override
  State<DndDroppable> createState() => _DndDroppableState();
}

class _DndDroppableState extends State<DndDroppable> {
  final GlobalKey _measureKey = GlobalKey();
  DndController? _controller;
  DndController? _registeredController;
  DndDroppableRegistration? _registration;
  bool _measureScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = DndScope.of(context);
    _syncRegistration();
  }

  @override
  void didUpdateWidget(DndDroppable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRegistration();
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  DndDroppableRegistration get _currentRegistration {
    return DndDroppableRegistration(
      id: widget.id,
      disabled: widget.disabled,
      data: widget.data,
    );
  }

  void _syncRegistration() {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final next = _currentRegistration;
    if (_registeredController != controller || _registration?.id != next.id) {
      _unregister();
      controller.registry.registerDroppable(next, owner: this);
      _registeredController = controller;
      _registration = next;
      _markMeasurementDirty();
      return;
    }

    if (_registration != next) {
      controller.registry.updateDroppable(next, owner: this);
      _registration = next;
      _markMeasurementDirty();
    }
  }

  void _unregister() {
    final controller = _registeredController;
    final registration = _registration;
    if (controller != null && registration != null) {
      // Only drop the measured rect if we still owned the registration; a newer
      // owner (lazy list rebuild) may have already taken it over.
      final removed = controller.registry.unregisterDroppable(registration.id, owner: this);
      if (removed != null) {
        controller.measuring.removeDroppableRect(registration.id);
      }
    }

    _registeredController = null;
    _registration = null;
  }

  DndRect? _measureCurrentRect() {
    final measureContext = _measureKey.currentContext;
    return measureContext == null ? null : measureDndRect(measureContext);
  }

  void _markMeasurementDirty() {
    final controller = _registeredController;
    final registration = _registration;
    if (controller == null || registration == null) {
      return;
    }

    controller.measuring.markDroppableDirty(
      registration.id,
      measure: _measureCurrentRect,
    );
  }

  void _scheduleMeasure() {
    if (_measureScheduled) {
      return;
    }

    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) {
        return;
      }

      final controller = _registeredController;
      final registration = _registration;
      if (controller == null || registration == null) {
        return;
      }

      controller.measuring.markDroppableDirty(
        registration.id,
        measure: _measureCurrentRect,
      );
      controller.measuring.refreshDirty();
    });
  }

  DndDroppableDetails _detailsFor(DndController controller) {
    return DndDroppableDetails(
      id: widget.id,
      disabled: widget.disabled,
      isOver: controller.overId == widget.id,
      activeId: controller.activeId,
      session: controller.activeSession,
    );
  }

  Widget _buildVisual(BuildContext context, Widget child) {
    final builder = widget.builder;
    final controller = _controller;
    if (builder == null || controller == null) {
      return child;
    }

    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        return builder(
          context,
          _detailsFor(controller),
          child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure();
    return DndMeasuredBox(
      key: _measureKey,
      onLayout: _markMeasurementDirty,
      child: _buildVisual(context, widget.child),
    );
  }
}
