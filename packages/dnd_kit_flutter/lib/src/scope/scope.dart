import 'package:dnd_kit/dnd_kit.dart' show DndAnnouncements;
import 'package:flutter/widgets.dart';

import 'controller.dart';

/// Provides a [DndController] to a subtree.
class DndScope extends StatefulWidget {
  /// Creates a drag-and-drop scope.
  const DndScope({
    super.key,
    this.controller,
    this.enableHapticFeedback = true,
    this.announcements,
    required this.child,
  });

  /// The externally owned controller for controlled usage.
  ///
  /// When omitted, the scope creates and disposes an internal controller.
  final DndController? controller;

  /// Default haptic feedback behavior for draggable touch activation.
  ///
  /// Defaults to true.
  final bool enableHapticFeedback;

  /// Optional drag lifecycle announcements for assistive technologies.
  ///
  /// When null, no accessibility announcements are emitted by the adapter.
  final DndAnnouncements? announcements;

  /// The subtree that can read this scope's controller.
  final Widget child;

  /// Returns the nearest [DndController], or null when no scope exists.
  static DndController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_DndControllerScope>()?.controller;
  }

  /// Returns the nearest scope-level haptic feedback default, if any.
  static bool? maybeEnableHapticFeedbackOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_DndControllerScope>()?.enableHapticFeedback;
  }

  /// Returns the nearest scope-level announcement configuration, if any.
  static DndAnnouncements? maybeAnnouncementsOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_DndControllerScope>()?.announcements;
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
      enableHapticFeedback: widget.enableHapticFeedback,
      announcements: widget.announcements,
      child: widget.child,
    );
  }
}

class _DndControllerScope extends InheritedNotifier<DndController> {
  const _DndControllerScope({
    required DndController controller,
    required this.enableHapticFeedback,
    required this.announcements,
    required super.child,
  }) : super(notifier: controller);

  DndController get controller => notifier!;

  final bool enableHapticFeedback;
  final DndAnnouncements? announcements;

  @override
  bool updateShouldNotify(_DndControllerScope oldWidget) {
    return enableHapticFeedback != oldWidget.enableHapticFeedback ||
        announcements != oldWidget.announcements ||
        super.updateShouldNotify(oldWidget);
  }
}
