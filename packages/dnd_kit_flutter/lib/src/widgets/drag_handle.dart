import 'package:flutter/widgets.dart';

import 'draggable.dart';

/// Marks a child region as an explicit drag activation handle.
class DndDragHandle extends StatefulWidget {
  /// Creates a drag handle.
  const DndDragHandle({
    super.key,
    required this.child,
    this.disabled = false,
    this.label,
    this.hint,
    this.hitTestBehavior,
  });

  /// The widget users can interact with to start a drag.
  final Widget child;

  /// Whether this handle should ignore drag gestures.
  final bool disabled;

  /// Optional semantics label announced for this handle.
  final String? label;

  /// Optional semantics hint announced for this handle.
  final String? hint;

  /// How this handle participates in hit testing.
  final HitTestBehavior? hitTestBehavior;

  @override
  State<DndDragHandle> createState() => _DndDragHandleState();
}

class _DndDragHandleState extends State<DndDragHandle> {
  DndDraggableHandleScope? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextScope = DndDraggableHandleScope.maybeOf(context);
    if (_scope == nextScope) {
      return;
    }

    _scope?.draggable.unregisterHandle();
    _scope = nextScope;
    _scope?.draggable.registerHandle();
  }

  @override
  void dispose() {
    _scope?.draggable.unregisterHandle();
    _scope = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draggable = _scope?.draggable;
    return Semantics(
      enabled: !widget.disabled && draggable != null,
      label: widget.label,
      hint: widget.hint,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Listener(
        behavior: widget.hitTestBehavior ?? HitTestBehavior.opaque,
        onPointerDown: widget.disabled || draggable == null
            ? null
            : (_) {
                draggable.markHandlePointerActive();
              },
        onPointerUp: widget.disabled || draggable == null
            ? null
            : (_) {
                draggable.clearHandlePointerActive();
              },
        onPointerCancel: widget.disabled || draggable == null
            ? null
            : (_) {
                draggable.clearHandlePointerActive();
              },
        child: widget.child,
      ),
    );
  }
}
