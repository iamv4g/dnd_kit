import 'dart:async';

import 'package:dnd_kit/dnd_kit.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../scope/controller.dart';
import '../scope/scope.dart';

/// Drag-driven vertical auto-scroll for a Jaspr scroll container.
///
/// `DndAutoScroll` renders a scroll viewport (style it via [classes]/[styles]/
/// [attributes] with `overflow` + a bounded height) and, while a drag is active
/// over the enclosing [DndScope]'s controller, scrolls that viewport when the
/// drag pointer enters its leading or trailing edge band.
///
/// Reuse posture (SPEC_JASPR §6.4): the edge-threshold and velocity math lives
/// in `dnd_kit` ([dndAutoScrollVelocity]); this component only adds the
/// browser execution layer — measuring the viewport via `getBoundingClientRect`
/// and applying `scrollTop`. The shared [DndRuntime] stays the only drag engine.
///
/// The loop is paced by a frame-interval [Timer] (not `requestAnimationFrame`,
/// which would need `dart:js_interop`), keeping the package SSR-safe: all DOM
/// access is guarded by `kIsWeb` and the timer only runs during a client drag.
///
/// Horizontal auto-scroll is intentionally out of scope here; it depends on a
/// DOM-free horizontal axis being added to the shared math first (US-056).
class DndAutoScroll extends StatefulComponent {
  /// Creates an auto-scroll viewport around [child].
  const DndAutoScroll({
    required this.child,
    this.controller,
    this.enabled = true,
    this.options = const DndAutoScrollOptions(),
    this.classes,
    this.styles,
    this.id,
    this.attributes,
    super.key,
  });

  /// The scrollable content. Make the rendered viewport scroll vertically via
  /// [classes]/[styles]/[attributes] (e.g. `overflow:auto` + a fixed height).
  final Component child;

  /// Optional controller to drive auto-scroll from.
  ///
  /// When omitted, the nearest [DndScope] controller is used.
  final DndController? controller;

  /// Whether auto-scroll should react to active drags.
  final bool enabled;

  /// Edge-threshold and velocity settings.
  final DndAutoScrollOptions options;

  /// CSS classes applied to the viewport element.
  final String? classes;

  /// Typed styles applied to the viewport element.
  final Styles? styles;

  /// DOM id applied to the viewport element.
  final String? id;

  /// Extra attributes applied to the viewport element (e.g. an inline `style`).
  final Map<String, String>? attributes;

  @override
  State<DndAutoScroll> createState() => _DndAutoScrollState();
}

class _DndAutoScrollState extends State<DndAutoScroll> {
  static const Duration _frameInterval = Duration(milliseconds: 16);

  final GlobalNodeKey<web.HTMLElement> _nodeKey = GlobalNodeKey<web.HTMLElement>();

  DndController? _controller;
  Timer? _timer;
  DndPoint? _pointer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
  }

  @override
  void didUpdateComponent(DndAutoScroll oldComponent) {
    super.didUpdateComponent(oldComponent);
    _syncController();
    if (!component.enabled) {
      _stop();
    } else {
      _syncAutoScroll();
    }
  }

  @override
  void dispose() {
    _stop();
    _controller?.removeListener(_syncAutoScroll);
    super.dispose();
  }

  void _syncController() {
    final next = component.controller ?? DndScope.of(context);
    if (identical(_controller, next)) {
      return;
    }

    _controller?.removeListener(_syncAutoScroll);
    _controller = next;
    _controller?.addListener(_syncAutoScroll);
    _syncAutoScroll();
  }

  void _syncAutoScroll() {
    if (!mounted) {
      return;
    }

    final controller = _controller;
    final session = controller?.activeSession;
    if (!component.enabled || controller == null || !controller.isDragging || session == null) {
      _stop();
      return;
    }

    _update(session.currentPointer);
  }

  void _update(DndPoint pointer) {
    _pointer = pointer;
    if (!kIsWeb) {
      return;
    }

    if (_velocityFor(pointer) == 0) {
      _stop();
      return;
    }

    _timer ??= Timer.periodic(_frameInterval, (_) => _tick());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _pointer = null;
  }

  void _tick() {
    final controller = _controller;
    final pointer = _pointer;
    if (controller == null || pointer == null || !controller.isDragging) {
      _stop();
      return;
    }

    final node = _nodeKey.currentNode;
    if (node == null) {
      _stop();
      return;
    }

    final velocity = _velocityFor(pointer);
    if (velocity == 0) {
      _stop();
      return;
    }

    final maxScroll = (node.scrollHeight - node.clientHeight).toDouble();
    final before = node.scrollTop;
    final next = (before + velocity).clamp(0.0, maxScroll);
    if (next == before) {
      _stop();
      return;
    }

    node.scrollTop = next;

    // The viewport moved without rebuilding any draggable/droppable, so every
    // cached rect is stale. Re-measure and re-resolve collision against the
    // post-scroll coordinates through the shared runtime's normal move path.
    final session = controller.activeSession;
    if (session != null) {
      controller.measuring.markAllDirty();
      controller.moveDrag(session.currentPointer);
    }
  }

  double _velocityFor(DndPoint pointer) {
    if (!kIsWeb) {
      return 0;
    }

    final node = _nodeKey.currentNode;
    if (node == null) {
      return 0;
    }

    final rect = node.getBoundingClientRect();
    if (rect.width == 0 || rect.height == 0) {
      return 0;
    }

    return dndAutoScrollVelocity(
      localPointer: DndPoint(pointer.x - rect.left, pointer.y - rect.top),
      viewportSize: DndSize(rect.width, rect.height),
      scrollPixels: node.scrollTop,
      minScrollExtent: 0,
      maxScrollExtent: (node.scrollHeight - node.clientHeight).toDouble(),
      options: component.options,
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      key: _nodeKey,
      id: component.id,
      classes: component.classes,
      styles: component.styles,
      attributes: component.attributes,
      [component.child],
    );
  }
}
