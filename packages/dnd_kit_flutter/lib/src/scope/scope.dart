import 'package:flutter/widgets.dart';

import 'controller.dart';

/// Provides a [DndController] to a subtree.
class DndScope extends StatefulWidget {
  /// Creates a drag-and-drop scope.
  const DndScope({
    super.key,
    this.controller,
    required this.child,
  });

  /// The externally owned controller for controlled usage.
  ///
  /// When omitted, the scope creates and disposes an internal controller.
  final DndController? controller;

  /// The subtree that can read this scope's controller.
  final Widget child;

  /// Returns the nearest [DndController], or null when no scope exists.
  static DndController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_DndControllerScope>()?.controller;
  }

  /// Returns the nearest [DndController].
  ///
  /// Throws a [FlutterError] when called outside a [DndScope].
  static DndController of(BuildContext context) {
    final controller = maybeOf(context);
    if (controller != null) {
      return controller;
    }

    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('DndScope.of() was called without a DndScope in the widget tree.'),
      ErrorDescription(
        'No DndScope ancestor could be found from the provided BuildContext.',
      ),
      ErrorHint('Wrap the subtree in a DndScope.'),
    ]);
  }

  @override
  State<DndScope> createState() => _DndScopeState();
}

class _DndScopeState extends State<DndScope> {
  DndController? _internalController;

  DndController get _controller {
    return widget.controller ?? _internalController!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = DndController();
    }
  }

  @override
  void didUpdateWidget(DndScope oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller == null && widget.controller != null) {
      _internalController?.dispose();
      _internalController = null;
      return;
    }

    if (oldWidget.controller != null && widget.controller == null) {
      _internalController = DndController();
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DndControllerScope(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _DndControllerScope extends InheritedNotifier<DndController> {
  const _DndControllerScope({
    required DndController controller,
    required super.child,
  }) : super(notifier: controller);

  DndController get controller => notifier!;
}
