import 'package:dnd_kit/dnd_kit.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../scope/controller.dart';
import '../scope/scope.dart';

/// Builds the visual shown by [DndDragOverlay] for an active drag session.
typedef DndDragOverlayBuilder = Component Function(
  BuildContext context,
  DndDragOverlayDetails details,
);

/// State exposed to a [DndDragOverlayBuilder].
final class DndDragOverlayDetails {
  /// Creates drag overlay builder details.
  const DndDragOverlayDetails({
    required this.session,
    required this.activeRect,
    required this.initialActiveRect,
    required this.overId,
  });

  /// The active drag session.
  final DndDragSession session;

  /// The live active draggable rectangle.
  ///
  /// The origin is anchored at drag start; the size follows the source
  /// element, so it collapses with the source when the application opens a
  /// placeholder gap. The overlay itself is sized from [initialActiveRect].
  final DndRect activeRect;

  /// The active draggable rectangle as measured at drag start.
  ///
  /// This is the size the overlay is laid out with, and it stays constant for
  /// the whole session.
  final DndRect initialActiveRect;

  /// The droppable currently under the active drag, when one exists.
  final DndId? overId;

  /// The stable id of the active draggable.
  DndId get activeId => session.activeId;

  /// The current drag transform after modifiers have been applied.
  DndTransform get transform => session.transform;
}

/// Renders an independently positioned visual for the active drag session.
class DndDragOverlay extends StatefulComponent {
  /// Creates a drag overlay.
  const DndDragOverlay({
    this.controller,
    required this.builder,
    this.ignoringPointer = true,
    super.key,
  });

  /// Optional controller to listen to.
  ///
  /// When omitted, the nearest [DndScope] controller is used.
  final DndController? controller;

  /// Builds the overlay visual for the active drag.
  final DndDragOverlayBuilder builder;

  /// Whether the overlay should ignore pointer events.
  ///
  /// Defaults to true so the overlay does not block drag interactions below it.
  final bool ignoringPointer;

  @override
  State<DndDragOverlay> createState() => _DndDragOverlayState();
}

class _DndDragOverlayState extends State<DndDragOverlay> {
  DndController? _listeningController;

  DndController get _effectiveController {
    return component.controller ?? DndScope.of(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllerListener();
  }

  @override
  void didUpdateComponent(DndDragOverlay oldComponent) {
    super.didUpdateComponent(oldComponent);
    _syncControllerListener();
  }

  @override
  void dispose() {
    _removeControllerListener();
    super.dispose();
  }

  void _syncControllerListener() {
    final controller = _effectiveController;
    if (identical(_listeningController, controller)) {
      return;
    }

    _removeControllerListener();
    controller.addListener(_handleControllerChanged);
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

  @override
  Component build(BuildContext context) {
    final controller = _effectiveController;
    final session = controller.activeSession;
    final activeRect = controller.activeRect;
    final initialActiveRect = controller.initialActiveRect ?? activeRect;
    if (session == null || activeRect == null || initialActiveRect == null) {
      return const Component.empty();
    }

    final details = DndDragOverlayDetails(
      session: session,
      activeRect: activeRect,
      initialActiveRect: initialActiveRect,
      overId: controller.overId,
    );

    return div(
      attributes: const <String, String>{
        'data-dnd-overlay': 'true',
        'aria-hidden': 'true',
      },
      // Sized from the drag-start rect so collapsing the source slot to open a
      // placeholder gap cannot shrink the drag preview to nothing.
      styles: Styles(
        position: Position.fixed(
          left: initialActiveRect.left.px,
          top: initialActiveRect.top.px,
        ),
        width: initialActiveRect.width.px,
        height: initialActiveRect.height.px,
        zIndex: const ZIndex(1),
        pointerEvents: component.ignoringPointer ? PointerEvents.none : PointerEvents.auto,
        transform: details.transform.isIdentity
            ? Transform.none
            : Transform.translate(
                x: details.transform.x.px,
                y: details.transform.y.px,
              ),
      ),
      [component.builder(context, details)],
    );
  }
}
