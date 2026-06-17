import 'package:dnd_kit/dnd_kit.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:universal_web/web.dart' as web;

import '../scope/controller.dart';
import '../scope/scope.dart';

/// Builds a droppable visual from the current drag state.
typedef DndDroppableBuilder = Component Function(
  BuildContext context,
  DndDroppableDetails details,
  Component child,
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
class DndDroppable extends StatefulComponent {
  /// Creates a droppable component.
  const DndDroppable({
    required this.id,
    required this.child,
    this.builder,
    this.disabled = false,
    this.data,
    super.key,
  });

  /// The stable droppable id.
  final DndId id;

  /// The component users can drop over.
  final Component child;

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
  final GlobalNodeKey<web.HTMLElement> _nodeKey = GlobalNodeKey<web.HTMLElement>();

  DndController? _controller;
  DndController? _registeredController;
  DndController? _listeningController;
  DndDroppableRegistration? _registration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = DndScope.of(context);
    _syncRegistration();
    _syncControllerListener();
  }

  @override
  void didUpdateComponent(DndDroppable oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.id != component.id ||
        oldComponent.disabled != component.disabled ||
        oldComponent.data != component.data) {
      _syncRegistration();
    }
    if (oldComponent.builder != component.builder) {
      _syncControllerListener();
    }
  }

  @override
  void dispose() {
    _removeControllerListener();
    _unregister();
    super.dispose();
  }

  DndDroppableRegistration get _currentRegistration {
    return DndDroppableRegistration(
      id: component.id,
      disabled: component.disabled,
      data: component.data,
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
      final removed = controller.registry.unregisterDroppable(registration.id, owner: this);
      if (removed != null) {
        controller.measuring.removeDroppableRect(registration.id);
      }
    }

    _registeredController = null;
    _registration = null;
  }

  void _syncControllerListener() {
    final controller = component.builder == null ? null : _controller;
    if (identical(_listeningController, controller)) {
      return;
    }

    _removeControllerListener();
    if (controller != null) {
      controller.addListener(_handleControllerChanged);
    }
    _listeningController = controller;
  }

  void _removeControllerListener() {
    _listeningController?.removeListener(_handleControllerChanged);
    _listeningController = null;
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  DndRect? _measure() {
    if (!kIsWeb) {
      return null;
    }

    final node = _nodeKey.currentNode;
    if (node == null) {
      return null;
    }

    final rect = node.getBoundingClientRect();
    return DndRect(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
    );
  }

  void _markMeasurementDirty() {
    final controller = _registeredController;
    final registration = _registration;
    if (controller == null || registration == null) {
      return;
    }

    controller.measuring.markDroppableDirty(
      registration.id,
      measure: _measure,
    );
  }

  DndDroppableDetails _detailsFor(DndController controller) {
    return DndDroppableDetails(
      id: component.id,
      disabled: component.disabled,
      isOver: controller.overId == component.id,
      activeId: controller.activeId,
      session: controller.activeSession,
    );
  }

  @override
  Component build(BuildContext context) {
    _markMeasurementDirty();
    final controller = _controller;
    final builder = component.builder;
    final child = builder == null || controller == null
        ? component.child
        : builder(
            context,
            _detailsFor(controller),
            component.child,
          );

    return div(
      key: _nodeKey,
      [child],
    );
  }
}
