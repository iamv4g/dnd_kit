import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../measuring/measuring.dart';
import '../scope/controller.dart';
import '../scope/scope.dart';

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
      controller.measuring.removeDroppableRect(registration.id);
    }

    _registeredController = null;
    _registration = null;
  }

  void _scheduleMeasure(BuildContext measureContext) {
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
      final currentMeasureContext = _measureKey.currentContext ?? measureContext;
      final rect = measureDndRect(currentMeasureContext);
      if (controller == null || registration == null || rect == null) {
        return;
      }

      controller.measuring.updateDroppableRect(registration.id, rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure(context);
    return _DndMeasuredBox(
      key: _measureKey,
      child: widget.child,
    );
  }
}

class _DndMeasuredBox extends SingleChildRenderObjectWidget {
  const _DndMeasuredBox({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDndMeasuredBox();
  }
}

class _RenderDndMeasuredBox extends RenderProxyBox {
  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }
}
