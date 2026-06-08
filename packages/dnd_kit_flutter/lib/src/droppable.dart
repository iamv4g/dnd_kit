import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'scope.dart';

/// Registers a child as a droppable target in the nearest drag-and-drop scope.
class DndDroppable extends StatefulWidget {
  /// Creates a droppable widget.
  const DndDroppable({
    super.key,
    required this.id,
    required this.child,
    this.disabled = false,
    this.data,
  });

  /// The stable droppable id.
  final DndId id;

  /// The widget users can drop over.
  final Widget child;

  /// Whether this droppable should be ignored by drag/drop runtimes.
  final bool disabled;

  /// Optional application-owned metadata stored in the controller registry.
  final Object? data;

  @override
  State<DndDroppable> createState() => _DndDroppableState();
}

class _DndDroppableState extends State<DndDroppable> {
  DndController? _controller;
  DndController? _registeredController;
  DndDroppableRegistration? _registration;

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
      controller.registry.registerDroppable(next);
      _registeredController = controller;
      _registration = next;
      return;
    }

    if (_registration != next) {
      controller.registry.updateDroppable(next);
      _registration = next;
    }
  }

  void _unregister() {
    final controller = _registeredController;
    final registration = _registration;
    if (controller != null && registration != null) {
      controller.registry.unregisterDroppable(registration.id);
    }

    _registeredController = null;
    _registration = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
