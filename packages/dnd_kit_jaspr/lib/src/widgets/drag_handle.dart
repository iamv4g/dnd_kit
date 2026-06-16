import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'draggable.dart';

/// Marks a child region as an explicit drag activation handle.
class DndDragHandle extends StatefulComponent {
  /// Creates a drag handle.
  const DndDragHandle({
    required this.child,
    this.disabled = false,
    super.key,
  });

  /// The component users can interact with to start a drag.
  final Component child;

  /// Whether this handle should ignore drag gestures.
  final bool disabled;

  @override
  State<DndDragHandle> createState() => _DndDragHandleState();
}

class _DndDragHandleState extends State<DndDragHandle> {
  DndDraggableHandleScope? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextScope = DndDraggableHandleScope.maybeOf(context);
    if (identical(_scope, nextScope)) {
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

  void _handlePointerDown(web.Event event) {
    if (component.disabled) {
      return;
    }
    _scope?.draggable.markHandlePointerActive();
  }

  void _clearPointerHandle(web.Event event) {
    _scope?.draggable.clearHandlePointerActive();
  }

  void _handleKeyDown(web.Event event) {
    if (component.disabled) {
      return;
    }

    final keyboardEvent = event as web.KeyboardEvent;
    final handled = _scope?.draggable.handleKeyboardEvent(keyboardEvent) ?? false;
    if (handled) {
      keyboardEvent.preventDefault();
    }
  }

  @override
  Component build(BuildContext context) {
    final draggable = _scope?.draggable;
    return div(
      attributes: <String, String>{
        if (!component.disabled && draggable != null) 'tabindex': '0',
        'role': 'button',
        'aria-disabled': component.disabled ? 'true' : 'false',
        'aria-roledescription': 'drag handle',
      },
      events: component.disabled || draggable == null
          ? null
          : <String, EventCallback>{
              'pointerdown': _handlePointerDown,
              'pointerup': _clearPointerHandle,
              'pointercancel': _clearPointerHandle,
              'keydown': _handleKeyDown,
            },
      [component.child],
    );
  }
}
