import 'package:dnd_kit/dnd_kit.dart';
import 'package:flutter/widgets.dart';

import '../scope/controller.dart';
import '../scope/scope.dart';

/// Builds the visual shown by [DndDragOverlay] for an active drag session.
typedef DndDragOverlayBuilder = Widget Function(
  BuildContext context,
  DndDragOverlayDetails details,
);

/// State exposed to a [DndDragOverlayBuilder].
final class DndDragOverlayDetails {
  /// Creates drag overlay builder details.
  const DndDragOverlayDetails({
    required this.session,
    required this.activeRect,
    required this.overId,
  });

  /// The active drag session.
  final DndDragSession session;

  /// The active draggable rectangle, anchored at drag start.
  final DndRect activeRect;

  /// The droppable currently under the active drag, when one exists.
  final DndId? overId;

  /// The stable id of the active draggable.
  DndId get activeId => session.activeId;

  /// The current drag transform after modifiers have been applied.
  DndTransform get transform => session.transform;
}

/// Renders an independently positioned visual for the active drag session.
///
/// The widget is intended to be placed in a full-size [Stack] above draggable
/// and droppable content.
class DndDragOverlay extends StatelessWidget {
  /// Creates a drag overlay.
  const DndDragOverlay({
    super.key,
    this.controller,
    required this.builder,
    this.ignoringPointer = true,
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
  Widget build(BuildContext context) {
    final effectiveController = controller ?? DndScope.of(context);
    return AnimatedBuilder(
      animation: effectiveController,
      builder: (context, _) {
        final session = effectiveController.activeSession;
        final activeRect = effectiveController.activeRect;
        if (session == null || activeRect == null) {
          return const SizedBox.shrink();
        }

        final details = DndDragOverlayDetails(
          session: session,
          activeRect: activeRect,
          overId: effectiveController.overId,
        );
        final origin = _stackOriginOf(context);

        return Positioned(
          left: activeRect.left - origin.dx,
          top: activeRect.top - origin.dy,
          width: activeRect.width,
          height: activeRect.height,
          child: Transform.translate(
            offset: Offset(details.transform.x, details.transform.y),
            child: IgnorePointer(
              ignoring: ignoringPointer,
              child: builder(context, details),
            ),
          ),
        );
      },
    );
  }

  Offset _stackOriginOf(BuildContext context) {
    RenderBox? stackBox;
    context.visitAncestorElements((element) {
      if (element.widget is Stack) {
        final renderObject = element.findRenderObject();
        if (renderObject is RenderBox) {
          stackBox = renderObject;
        }
        return false;
      }
      return true;
    });

    if (stackBox != null) {
      return stackBox!.localToGlobal(Offset.zero);
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return Offset.zero;
    }
    return renderObject.localToGlobal(Offset.zero);
  }
}
