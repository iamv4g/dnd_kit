import 'dart:async' show unawaited;

import 'package:dnd_kit/dnd_kit.dart';
import 'package:flutter/gestures.dart'
    show
        DelayedMultiDragGestureRecognizer,
        Drag,
        DragEndDetails,
        DragUpdateDetails,
        ImmediateMultiDragGestureRecognizer,
        MultiDragGestureRecognizer,
        PointerDeviceKind,
        kLongPressTimeout;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../a11y/announcements.dart';
import '../measuring/measuring.dart';
import '../scope/controller.dart';
import '../scope/scope.dart';
import '../sensors/long_press_activation.dart';

/// Builds a draggable visual from the current drag state.
typedef DndDraggableBuilder = Widget Function(
  BuildContext context,
  DndDraggableDetails details,
  Widget child,
);

/// State exposed to a [DndDraggableBuilder].
final class DndDraggableDetails {
  /// Creates draggable visual state details.
  const DndDraggableDetails({
    required this.id,
    required this.disabled,
    required this.isActive,
    required this.isDragging,
    required this.isDropping,
    required this.session,
  });

  /// The stable draggable id.
  final DndId id;

  /// Whether drag gestures are ignored for this draggable.
  final bool disabled;

  /// Whether this draggable is the active drag source.
  final bool isActive;

  /// Whether this draggable is actively dragging.
  final bool isDragging;

  /// Whether this draggable is completing a drop.
  final bool isDropping;

  /// The active session for this draggable, when available.
  final DndDragSession? session;
}

/// Registers a child as draggable and wires basic pointer gestures to a scope.
class DndDraggable extends StatefulWidget {
  /// Creates a draggable widget.
  const DndDraggable({
    super.key,
    required this.id,
    required this.child,
    this.builder,
    this.disabled = false,
    this.data,
    this.activationConstraint = DndSensorActivationConstraint.none,
    this.longPressActivation,
    this.enableHapticFeedback,
    this.keyboardDragStep = 25,
    this.label,
    this.hint,
    this.hitTestBehavior,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
  })  : assert(
          longPressActivation == null || activationConstraint == DndSensorActivationConstraint.none,
          'Use either activationConstraint or longPressActivation, not both.',
        ),
        assert(keyboardDragStep > 0, 'Keyboard drag step must be positive.');

  /// The stable draggable id.
  final DndId id;

  /// The widget users can drag.
  final Widget child;

  /// Optional visual builder for drag state-aware rendering.
  final DndDraggableBuilder? builder;

  /// Whether drag gestures should be ignored for this draggable.
  final bool disabled;

  /// Optional application-owned metadata stored in the controller registry.
  final Object? data;

  /// The pointer activation constraint required before a drag starts.
  final DndSensorActivationConstraint activationConstraint;

  /// Optional long-press activation behavior for pointer drags.
  final DndLongPressActivation? longPressActivation;

  /// Whether touch drag activation emits haptic feedback.
  ///
  /// When null, this inherits the nearest [DndScope] default and then the
  /// library default of true. Haptics only fire for touch activation.
  final bool? enableHapticFeedback;

  /// Logical pixels moved for each keyboard arrow key press.
  final double keyboardDragStep;

  /// Optional semantics label announced for this draggable.
  final String? label;

  /// Optional semantics hint announced for this draggable.
  ///
  /// When null, the adapter provides the default keyboard drag instructions.
  final String? hint;

  /// How this draggable participates in hit testing.
  final HitTestBehavior? hitTestBehavior;

  /// Callback for a started drag session.
  final DndDragStartCallback? onDragStart;

  /// Callback for active drag movement.
  final DndDragMoveCallback? onDragMove;

  /// Callback for a completed drag.
  final DndDragEndCallback? onDragEnd;

  /// Callback for a cancelled drag.
  final DndDragCancelCallback? onDragCancel;

  @override
  State<DndDraggable> createState() => _DndDraggableState();
}

class _DndDraggableState extends State<DndDraggable> implements DndDraggableHandleController {
  final GlobalKey _measureKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(debugLabel: 'DndDraggable');
  DndController? _controller;
  DndController? _registrationController;
  DndController? _announcementController;
  DndDraggableRegistration? _registration;
  DndPointerSensor? _pointerSensor;
  MultiDragGestureRecognizer? _dragRecognizer;
  MultiDragGestureRecognizer? _detachedRecognizer;
  bool? _scopeEnableHapticFeedback;
  bool _disabledCancelScheduled = false;
  bool _handlePointerActive = false;
  int _handleCount = 0;
  DndAnnouncements? _announcements;
  String? _lastAnnouncementStateLabel;
  DndId? _lastAnnouncementOverId;
  DndId? _announcementActiveId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = DndScope.of(context);
    _scopeEnableHapticFeedback = DndScope.maybeEnableHapticFeedbackOf(context);
    _announcements = DndScope.maybeAnnouncementsOf(context);
    _syncRegistration();
    _bindControllerListener();
  }

  @override
  void didUpdateWidget(DndDraggable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRegistration();

    if (!oldWidget.disabled && widget.disabled && (_isWidgetGestureDrag || _isKeyboardDrag)) {
      _scheduleDisabledCancel();
    }
  }

  @override
  void dispose() {
    _announcementController?.removeListener(_handleControllerChanged);
    if (_isWidgetGestureDrag) {
      // A lazy list (e.g. ListView.builder) is recycling this element while it
      // is the active drag source. Keep the in-flight gesture, registration,
      // and measured rect alive for the rest of the session instead of
      // cancelling the drag. The recognizer disposes itself once the gesture
      // completes (see _handlePanEnd / _handlePanCancel).
      _detachedRecognizer = _dragRecognizer;
    } else {
      _pointerSensor?.dispose();
      _dragRecognizer?.dispose();
      _unregister();
    }
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isWidgetGestureDrag {
    return _pointerSensor?.isActive == true && _controller?.activeId == widget.id;
  }

  bool get _isKeyboardDrag {
    final state = _controller?.state;
    return state is DndDragging &&
        state.session.activeId == widget.id &&
        state.session.inputKind == DndInputKind.keyboard;
  }

  bool get _usesLongPressActivation => widget.longPressActivation != null;

  DndDraggableRegistration get _currentRegistration {
    return DndDraggableRegistration(
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
    if (_registrationController != controller || _registration?.id != next.id) {
      _unregister();
      controller.registry.registerDraggable(next, owner: this);
      _registrationController = controller;
      _registration = next;
      _markMeasurementDirty();
      return;
    }

    if (_registration != next) {
      controller.registry.updateDraggable(next, owner: this);
      _registration = next;
      _markMeasurementDirty();
    }
  }

  void _bindControllerListener() {
    final controller = _controller;
    if (_announcementController == controller) {
      return;
    }

    _announcementController?.removeListener(_handleControllerChanged);
    _announcementController = controller;
    _announcementController?.addListener(_handleControllerChanged);
    if (controller != null) {
      _syncAnnouncements(controller);
    }
  }

  void _unregister() {
    final controller = _registrationController;
    final registration = _registration;
    if (controller != null && registration != null) {
      // Only drop the measured rect if we still owned the registration; a newer
      // owner (lazy list rebuild) may have already taken it over.
      final removed = controller.registry.unregisterDraggable(registration.id, owner: this);
      if (removed != null) {
        controller.measuring.removeDraggableRect(registration.id);
      }
    }

    _registrationController = null;
    _registration = null;
  }

  DndRect? _measureCurrentRect() {
    final measureContext = _measureKey.currentContext;
    return measureContext == null ? null : measureDndRect(measureContext);
  }

  void _markMeasurementDirty() {
    final controller = _registrationController;
    final registration = _registration;
    if (controller == null || registration == null) {
      return;
    }

    controller.measuring.markDraggableDirty(
      registration.id,
      measure: _measureCurrentRect,
    );
  }

  DndRect? _refreshDraggableMeasurement() {
    final controller = _controller;
    if (controller == null) {
      return null;
    }

    controller.measuring.markDraggableDirty(
      widget.id,
      measure: _measureCurrentRect,
    );
    controller.measuring.refreshDirty();

    final cachedRect = controller.measuring.draggableRect(widget.id);
    if (cachedRect != null) {
      return cachedRect;
    }

    final rect = _measureCurrentRect();
    if (rect != null) {
      controller.measuring.updateDraggableRect(widget.id, rect);
    }
    return rect;
  }

  @internal
  @override
  void registerHandle() {
    _handleCount += 1;
  }

  @internal
  @override
  void unregisterHandle() {
    assert(_handleCount > 0, 'Cannot unregister a drag handle before registration.');
    if (_handleCount == 0) {
      return;
    }

    _handleCount -= 1;
  }

  @internal
  @override
  void markHandlePointerActive() {
    _handlePointerActive = true;
  }

  @internal
  @override
  void clearHandlePointerActive() {
    _handlePointerActive = false;
  }

  /// Routes a raw pointer-down into an arena-winning drag recognizer.
  ///
  /// Long-press activation keeps using the [Listener] path. Other activations
  /// use a [MultiDragGestureRecognizer] so the drag can win the gesture arena
  /// against an enclosing [Scrollable].
  void _routePointer(PointerDownEvent event) {
    if (widget.disabled || _usesLongPressActivation) {
      return;
    }

    final startedFromHandle = _handlePointerActive;
    if (_handleCount > 0 && !startedFromHandle) {
      return;
    }

    final controller = _controller;
    if (controller == null || !controller.isIdle) {
      return;
    }

    _dragRecognizer?.dispose();
    final recognizer = _createDragRecognizer(event.kind, startedFromHandle);
    _dragRecognizer = recognizer;
    recognizer.addPointer(event);
  }

  MultiDragGestureRecognizer _createDragRecognizer(
    PointerDeviceKind kind,
    bool fromHandle,
  ) {
    final inputKind = _inputKindFromPointerKind(kind);
    if (_usesDelayedRecognizer(kind)) {
      return DelayedMultiDragGestureRecognizer(
        delay: kLongPressTimeout,
        debugOwner: this,
      )..onStart = (position) => _onRecognizerStart(
            position,
            inputKind: inputKind,
            fromHandle: fromHandle,
            // The recognizer already enforced the activation delay.
            constraint: DndSensorActivationConstraint.none,
          );
    }

    return ImmediateMultiDragGestureRecognizer(debugOwner: this)
      ..onStart = (position) => _onRecognizerStart(
            position,
            inputKind: inputKind,
            fromHandle: fromHandle,
            constraint: widget.activationConstraint,
          );
  }

  /// Touch with the default activation drags after a hold so it can coexist
  /// with scrolling; precise pointers and explicit constraints drag eagerly.
  bool _usesDelayedRecognizer(PointerDeviceKind kind) {
    if (widget.activationConstraint != DndSensorActivationConstraint.none) {
      return false;
    }

    return switch (kind) {
      PointerDeviceKind.touch ||
      PointerDeviceKind.stylus ||
      PointerDeviceKind.invertedStylus ||
      PointerDeviceKind.unknown =>
        true,
      PointerDeviceKind.mouse || PointerDeviceKind.trackpad => false,
    };
  }

  Drag? _onRecognizerStart(
    Offset position, {
    required DndInputKind inputKind,
    required bool fromHandle,
    required DndSensorActivationConstraint constraint,
  }) {
    _startPointerSensor(
      _pointFromOffset(position),
      inputKind: inputKind,
      fromHandle: fromHandle,
      constraint: constraint,
    );

    if (_pointerSensor == null) {
      return null;
    }

    return _DndDrag(
      onUpdate: (details) => _pointerSensor?.move(_pointFromOffset(details.globalPosition)),
      onEnd: (_) => _handlePanEnd(),
      onCancel: _handlePanCancel,
    );
  }

  /// Single Listener entry point: drives the long-press path and the
  /// arena-winning recognizer path; each ignores the other's activation mode.
  void _handlePointerDownEvent(PointerDownEvent event) {
    _handlePointerDown(event);
    _routePointer(event);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_usesLongPressActivation) {
      return;
    }

    _startPointerSensor(
      _pointFromOffset(event.position),
      inputKind: _inputKindFromPointerKind(event.kind),
      fromHandle: false,
      constraint: _effectiveActivationConstraint,
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_usesLongPressActivation) {
      return;
    }

    _pointerSensor?.move(_pointFromOffset(event.position));
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_usesLongPressActivation) {
      return;
    }

    _pointerSensor?.end();
    _pointerSensor = null;
    _handlePointerActive = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (!_usesLongPressActivation) {
      return;
    }

    _cancelDrag(reason: DndCancelReason.sensor);
  }

  void _startPointerSensor(
    DndPoint initialPointer, {
    required DndInputKind inputKind,
    required bool fromHandle,
    required DndSensorActivationConstraint constraint,
  }) {
    final startedFromHandle = fromHandle || _handlePointerActive;
    if (_handleCount > 0 && !startedFromHandle) {
      return;
    }

    if (widget.disabled) {
      return;
    }

    final controller = _controller;
    if (controller == null || !controller.isIdle) {
      assert(false, 'Cannot start a draggable while another drag is active.');
      return;
    }

    final activeRect = _refreshDraggableMeasurement();

    final sensor = DndPointerSensor(
      runtime: controller.runtime,
      activeRect: activeRect,
      constraint: constraint,
      onDragStart: _handleDragStart,
      onDragMove: widget.onDragMove,
      onDragEnd: widget.onDragEnd,
      onDragCancel: widget.onDragCancel,
    );
    _pointerSensor = sensor;
    sensor.start(
      DndSensorActivationEvent(
        activeId: widget.id,
        position: initialPointer,
        inputKind: inputKind,
      ),
    );
  }

  DndInputKind _inputKindFromPointerKind(PointerDeviceKind? kind) {
    return switch (kind) {
      PointerDeviceKind.mouse => DndInputKind.mouse,
      PointerDeviceKind.touch => DndInputKind.touch,
      _ => DndInputKind.pointer,
    };
  }

  DndSensorActivationConstraint get _effectiveActivationConstraint {
    final longPressActivation = widget.longPressActivation;
    if (longPressActivation == null) {
      return widget.activationConstraint;
    }

    return DndSensorActivationConstraint(
      delay: longPressActivation.delay,
      tolerance: longPressActivation.tolerance,
    );
  }

  DndDraggableDetails _detailsFor(DndController controller) {
    final state = controller.state;
    final session = switch (state) {
      DndDragging(:final session) ||
      DndDropping(:final session) when session.activeId == widget.id =>
        session,
      _ => null,
    };

    return DndDraggableDetails(
      id: widget.id,
      disabled: widget.disabled,
      isActive: controller.activeId == widget.id,
      isDragging: state is DndDragging && state.session.activeId == widget.id,
      isDropping: state is DndDropping && state.session.activeId == widget.id,
      session: session,
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

  void _handleDragStart(DndDragStartEvent event) {
    final shouldEmitHaptic = event.inputKind == DndInputKind.touch &&
        (widget.enableHapticFeedback ?? _scopeEnableHapticFeedback ?? true);

    if (shouldEmitHaptic) {
      unawaited(HapticFeedback.selectionClick());
    }

    widget.onDragStart?.call(event);
  }

  void _handlePanEnd() {
    _pointerSensor?.end();
    _pointerSensor = null;
    _handlePointerActive = false;
    _disposeDetachedRecognizer();
  }

  void _handlePanCancel() {
    if (mounted && !_isWidgetGestureDrag) {
      _handlePointerActive = false;
      return;
    }

    _cancelDrag(reason: DndCancelReason.sensor);
    _handlePointerActive = false;
    _disposeDetachedRecognizer();
  }

  /// Disposes a recognizer that outlived this element after a lazy recycle,
  /// once its in-flight gesture has finished.
  void _disposeDetachedRecognizer() {
    if (mounted) {
      return;
    }

    _detachedRecognizer?.dispose();
    _detachedRecognizer = null;
    _pointerSensor?.dispose();
    _pointerSensor = null;
  }

  void _cancelDrag({required DndCancelReason reason}) {
    _pointerSensor?.cancel(reason: reason);
    _pointerSensor = null;
    _handlePointerActive = false;

    if (_isKeyboardDrag) {
      final event = _controller?.cancelDrag(reason: reason);
      if (event != null) {
        widget.onDragCancel?.call(event);
        _controller?.reset();
      }
    }
  }

  void _scheduleDisabledCancel() {
    if (_disabledCancelScheduled) {
      return;
    }

    _disabledCancelScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disabledCancelScheduled = false;
      if (!mounted || !widget.disabled || (!_isWidgetGestureDrag && !_isKeyboardDrag)) {
        return;
      }

      _cancelDrag(reason: DndCancelReason.disabled);
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (widget.disabled) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      return _toggleKeyboardDrag();
    }

    if (key == LogicalKeyboardKey.escape) {
      return _cancelKeyboardDrag();
    }

    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => DndPoint(-widget.keyboardDragStep, 0),
      LogicalKeyboardKey.arrowRight => DndPoint(widget.keyboardDragStep, 0),
      LogicalKeyboardKey.arrowUp => DndPoint(0, -widget.keyboardDragStep),
      LogicalKeyboardKey.arrowDown => DndPoint(0, widget.keyboardDragStep),
      _ => null,
    };

    if (delta == null) {
      return KeyEventResult.ignored;
    }

    return _moveKeyboardDrag(delta);
  }

  KeyEventResult _toggleKeyboardDrag() {
    if (_isKeyboardDrag) {
      final event = _controller?.endDrag();
      if (event != null) {
        widget.onDragEnd?.call(event);
        _controller?.reset();
      }
      return KeyEventResult.handled;
    }

    if (_startKeyboardDrag()) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleControllerChanged() {
    final controller = _announcementController;
    if (controller == null || !mounted) {
      return;
    }
    _syncAnnouncements(controller);
  }

  void _syncAnnouncements(DndController controller) {
    final announcements = _announcements;
    if (announcements == null || !MediaQuery.supportsAnnounceOf(context)) {
      _resetAnnouncementTrackingIfIdle(controller);
      return;
    }

    final activeId = controller.activeId ?? _announcementActiveId;
    if (activeId != widget.id) {
      _resetAnnouncementTrackingIfIdle(controller);
      return;
    }

    final state = controller.state;
    final label = state.runtimeType.toString();
    String? message;

    if (state is DndDragging) {
      _announcementActiveId = state.session.activeId;
      if (_lastAnnouncementStateLabel != 'DndDragging') {
        message = announcements.onDragStart(state.session.activeId);
        _lastAnnouncementOverId = controller.overId;
      } else if (controller.overId != _lastAnnouncementOverId) {
        message = announcements.onDragOver(state.session.activeId, controller.overId);
        _lastAnnouncementOverId = controller.overId;
      }
    } else if (state is DndDropping && _lastAnnouncementStateLabel != 'DndDropping') {
      if (activeId != null) {
        message = announcements.onDragEnd(activeId, controller.overId);
      }
    } else if (state is DndCancelled && _lastAnnouncementStateLabel != 'DndCancelled') {
      if (activeId != null) {
        message = announcements.onDragCancel(activeId);
      }
    } else if (state is DndIdle) {
      _announcementActiveId = null;
      _lastAnnouncementOverId = null;
    }

    _lastAnnouncementStateLabel = label;
    if (message != null) {
      final view = View.maybeOf(context);
      final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
      if (view != null) {
        unawaited(SemanticsService.sendAnnouncement(view, message, textDirection));
      }
    }
  }

  void _resetAnnouncementTrackingIfIdle(DndController controller) {
    if (controller.state is DndIdle) {
      _announcementActiveId = null;
      _lastAnnouncementOverId = null;
      _lastAnnouncementStateLabel = 'DndIdle';
    }
  }

  bool _startKeyboardDrag() {
    final controller = _controller;
    if (controller == null || !controller.isIdle) {
      return false;
    }

    final activeRect = _refreshDraggableMeasurement();

    final initialPointer = activeRect?.center ?? DndPoint.zero;
    controller.beginDrag(
      DndSensorActivationEvent(
        activeId: widget.id,
        position: initialPointer,
        inputKind: DndInputKind.keyboard,
      ),
      activeRect: activeRect,
    );

    final event = controller.startDrag();
    if (event == null) {
      return false;
    }

    widget.onDragStart?.call(event);
    return true;
  }

  KeyEventResult _moveKeyboardDrag(DndPoint delta) {
    final session = _controller?.activeSession;
    if (!_isKeyboardDrag || session == null) {
      return KeyEventResult.ignored;
    }

    final event = _controller?.moveDrag(session.currentPointer.translate(delta));
    if (event != null) {
      widget.onDragMove?.call(event);
    }

    return KeyEventResult.handled;
  }

  KeyEventResult _cancelKeyboardDrag() {
    if (!_isKeyboardDrag) {
      return KeyEventResult.ignored;
    }

    final event = _controller?.cancelDrag(reason: DndCancelReason.user);
    if (event != null) {
      widget.onDragCancel?.call(event);
      _controller?.reset();
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return DndDraggableHandleScope(
      draggable: this,
      child: Semantics(
        enabled: !widget.disabled,
        focusable: !widget.disabled,
        label: widget.label,
        hint:
            widget.hint ?? 'Press Space or Enter to pick up, arrow keys to move, Escape to cancel.',
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        child: Focus(
          focusNode: _focusNode,
          canRequestFocus: !widget.disabled,
          onKeyEvent: _handleKeyEvent,
          child: Listener(
            behavior: widget.hitTestBehavior ?? HitTestBehavior.opaque,
            onPointerDown: widget.disabled ? null : _handlePointerDownEvent,
            onPointerMove: widget.disabled ? null : _handlePointerMove,
            onPointerUp: widget.disabled ? null : _handlePointerUp,
            onPointerCancel: widget.disabled ? null : _handlePointerCancel,
            child: DndMeasuredBox(
              key: _measureKey,
              onLayout: _markMeasurementDirty,
              child: _buildVisual(context, widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

@internal
class DndDraggableHandleScope extends InheritedWidget {
  const DndDraggableHandleScope({
    super.key,
    required this.draggable,
    required super.child,
  });

  final DndDraggableHandleController draggable;

  static DndDraggableHandleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DndDraggableHandleScope>();
  }

  @override
  bool updateShouldNotify(DndDraggableHandleScope oldWidget) {
    return draggable != oldWidget.draggable;
  }
}

@internal
abstract interface class DndDraggableHandleController {
  void registerHandle();

  void unregisterHandle();

  void markHandlePointerActive();

  void clearHandlePointerActive();
}

DndPoint _pointFromOffset(Offset offset) {
  return DndPoint(offset.dx, offset.dy);
}

/// Adapts a [MultiDragGestureRecognizer] drag into pointer-sensor callbacks.
class _DndDrag extends Drag {
  _DndDrag({
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final void Function(DragUpdateDetails details) onUpdate;
  final void Function(DragEndDetails details) onEnd;
  final VoidCallback onCancel;

  @override
  void update(DragUpdateDetails details) => onUpdate(details);

  @override
  void end(DragEndDetails details) => onEnd(details);

  @override
  void cancel() => onCancel();
}
