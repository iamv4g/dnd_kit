import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../scope/controller.dart';
import '../scope/scope.dart';

/// [DndAutoScrollOptions] and the edge/velocity math are framework-neutral and
/// live in `dnd_kit_core`; the options class is re-exported here so existing
/// imports keep working.
export 'package:dnd_kit_core/dnd_kit_core.dart' show DndAutoScrollOptions;

/// Controls drag-driven scrolling for a single [Scrollable].
final class DndAutoScrollController {
  /// Creates an auto-scroll controller.
  DndAutoScrollController({
    required ScrollPosition position,
    required BuildContext viewportContext,
    required TickerProvider vsync,
    this.options = const DndAutoScrollOptions(),
  })  : _position = position,
        _viewportContext = viewportContext {
    _ticker = vsync.createTicker(_tick);
  }

  ScrollPosition _position;
  BuildContext _viewportContext;
  late Ticker _ticker;
  DndAutoScrollOptions options;
  DndPoint? _pointer;

  /// Whether this controller is actively ticking.
  bool get isActive => _ticker.isActive;

  /// Updates the scroll position driven by this controller.
  void updatePosition(ScrollPosition position) {
    _position = position;
  }

  /// Updates the viewport bounds used for edge detection.
  void updateViewport(BuildContext viewportContext) {
    _viewportContext = viewportContext;
  }

  /// Updates the ticker callback used for frame-based scrolling.
  void updateVsync(TickerProvider vsync) {
    final wasActive = _ticker.isActive;
    _ticker.dispose();
    _ticker = vsync.createTicker(_tick);
    if (wasActive) {
      _ticker.start();
    }
  }

  /// Starts or updates auto-scroll from the global drag [pointer].
  void update(DndPoint pointer) {
    _pointer = pointer;
    if (_velocityFor(pointer) == 0) {
      stop();
      return;
    }

    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  /// Stops active auto-scroll.
  void stop() {
    _pointer = null;
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  /// Releases ticker resources.
  void dispose() {
    _ticker.dispose();
  }

  void _tick(Duration elapsed) {
    final pointer = _pointer;
    if (pointer == null) {
      stop();
      return;
    }

    final velocity = _velocityFor(pointer);
    if (velocity == 0) {
      stop();
      return;
    }

    final position = _position;
    final nextPixels = (position.pixels + velocity).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (nextPixels == position.pixels) {
      stop();
      return;
    }

    position.jumpTo(nextPixels);
  }

  double _velocityFor(DndPoint pointer) {
    final position = _position;
    if (!position.hasPixels) {
      return 0;
    }

    final box = _viewportContext.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return 0;
    }

    final localPointer = box.globalToLocal(Offset(pointer.x, pointer.y));
    return dndAutoScrollVelocity(
      localPointer: DndPoint(localPointer.dx, localPointer.dy),
      viewportSize: DndSize(box.size.width, box.size.height),
      scrollPixels: position.pixels,
      minScrollExtent: position.minScrollExtent,
      maxScrollExtent: position.maxScrollExtent,
      options: options,
    );
  }
}

/// Enables vertical drag auto-scroll for the nearest [Scrollable] descendant.
class DndAutoScroll extends StatefulWidget {
  /// Creates an auto-scroll wrapper.
  const DndAutoScroll({
    super.key,
    this.controller,
    this.scrollController,
    this.enabled = true,
    this.options = const DndAutoScrollOptions(),
    required this.child,
  });

  /// Optional controller to listen to.
  ///
  /// When omitted, the nearest [DndScope] controller is used.
  final DndController? controller;

  /// Optional scroll controller to drive.
  ///
  /// When omitted, the first descendant [Scrollable] is used.
  final ScrollController? scrollController;

  /// Whether auto-scroll should react to active drags.
  final bool enabled;

  /// Auto-scroll activation and velocity settings.
  final DndAutoScrollOptions options;

  /// The subtree containing a vertical [Scrollable].
  final Widget child;

  @override
  State<DndAutoScroll> createState() => _DndAutoScrollState();
}

class _DndAutoScrollState extends State<DndAutoScroll> with TickerProviderStateMixin {
  final GlobalKey _viewportKey = GlobalKey();
  DndController? _controller;
  DndAutoScrollController? _autoScrollController;
  bool _scrollableLookupScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
    _scheduleScrollableLookup();
  }

  @override
  void didUpdateWidget(DndAutoScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController();
    _scheduleScrollableLookup();
    _autoScrollController?.options = widget.options;
    if (!widget.enabled) {
      _autoScrollController?.stop();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_syncAutoScroll);
    _autoScrollController?.dispose();
    super.dispose();
  }

  void _syncController() {
    final nextController = widget.controller ?? DndScope.of(context);
    if (_controller == nextController) {
      return;
    }

    _controller?.removeListener(_syncAutoScroll);
    _controller = nextController;
    _controller?.addListener(_syncAutoScroll);
    _syncAutoScroll();
  }

  void _syncAutoScroll() {
    if (!mounted) {
      return;
    }

    final autoScrollController = _autoScrollController;
    final controller = _controller;
    final session = controller?.activeSession;
    if (!widget.enabled ||
        autoScrollController == null ||
        controller?.isDragging != true ||
        session == null) {
      autoScrollController?.stop();
      return;
    }

    autoScrollController.update(session.currentPointer);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleScrollableLookup();
    return DecoratedBox(
      key: _viewportKey,
      decoration: const BoxDecoration(),
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _handleScrollMetrics,
        child: widget.child,
      ),
    );
  }

  bool _handleScrollMetrics(ScrollMetricsNotification notification) {
    final scrollable = Scrollable.maybeOf(notification.context);
    if (scrollable != null) {
      _handleScrollableReady(scrollable);
    }
    return false;
  }

  void _handleScrollableReady(ScrollableState scrollable) {
    _handlePositionReady(scrollable.position);
  }

  void _handlePositionReady(ScrollPosition position) {
    final viewportContext = _viewportKey.currentContext;
    if (viewportContext == null) {
      return;
    }

    final autoScrollController = _autoScrollController;
    if (autoScrollController == null) {
      _autoScrollController = DndAutoScrollController(
        position: position,
        viewportContext: viewportContext,
        vsync: this,
        options: widget.options,
      );
    } else {
      autoScrollController
        ..updatePosition(position)
        ..updateViewport(viewportContext)
        ..updateVsync(this)
        ..options = widget.options;
    }

    _syncAutoScroll();
  }

  void _scheduleScrollableLookup() {
    if (_scrollableLookupScheduled) {
      return;
    }

    _scrollableLookupScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollableLookupScheduled = false;
      if (!mounted) {
        return;
      }

      final scrollController = widget.scrollController;
      if (scrollController != null && scrollController.hasClients) {
        _handlePositionReady(scrollController.position);
        return;
      }

      final scrollable = _findScrollableDescendant(context);
      if (scrollable != null && scrollable.position.hasPixels) {
        _handleScrollableReady(scrollable);
        return;
      }

      _scheduleScrollableLookup();
    });
  }

  ScrollableState? _findScrollableDescendant(BuildContext context) {
    ScrollableState? found;

    void visit(Element element) {
      if (found != null) {
        return;
      }

      if (element is StatefulElement && element.state is ScrollableState) {
        found = element.state as ScrollableState;
        return;
      }

      element.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);
    return found;
  }
}
