import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class HorizontalBoardAutoScroll extends StatefulWidget {
  const HorizontalBoardAutoScroll({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.child,
  });

  final DndController controller;
  final ScrollController scrollController;
  final Widget child;

  @override
  State<HorizontalBoardAutoScroll> createState() =>
      _HorizontalBoardAutoScrollState();
}

class _HorizontalBoardAutoScrollState extends State<HorizontalBoardAutoScroll>
    with SingleTickerProviderStateMixin {
  final GlobalKey _viewportKey = GlobalKey();
  late final Ticker _ticker;
  DndPoint? _pointer;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.controller.addListener(_syncAutoScroll);
  }

  @override
  void didUpdateWidget(HorizontalBoardAutoScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncAutoScroll);
      widget.controller.addListener(_syncAutoScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncAutoScroll);
    _ticker.dispose();
    super.dispose();
  }

  void _syncAutoScroll() {
    final session = widget.controller.activeSession;
    if (session == null || !widget.controller.isDragging) {
      _stop();
      return;
    }

    _pointer = session.currentPointer;
    if (_velocityFor(session.currentPointer) == 0) {
      _stop();
      return;
    }

    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final pointer = _pointer;
    if (pointer == null || !widget.scrollController.hasClients) {
      _stop();
      return;
    }

    final velocity = _velocityFor(pointer);
    if (velocity == 0) {
      _stop();
      return;
    }

    final position = widget.scrollController.position;
    final nextPixels = (position.pixels + velocity).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (nextPixels == position.pixels) {
      _stop();
      return;
    }
    position.jumpTo(nextPixels);
  }

  double _velocityFor(DndPoint pointer) {
    if (!widget.scrollController.hasClients) {
      return 0;
    }

    final box = _viewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return 0;
    }

    final localPointer = box.globalToLocal(Offset(pointer.x, pointer.y));
    if (localPointer.dy < 0 ||
        localPointer.dy > box.size.height ||
        localPointer.dx < 0 ||
        localPointer.dx > box.size.width) {
      return 0;
    }

    const edgeThreshold = 96.0;
    const maxVelocity = 14.0;
    final position = widget.scrollController.position;
    if (localPointer.dx < edgeThreshold &&
        position.pixels > position.minScrollExtent) {
      return -maxVelocity * ((edgeThreshold - localPointer.dx) / edgeThreshold);
    }

    final trailingDistance = box.size.width - localPointer.dx;
    if (trailingDistance < edgeThreshold &&
        position.pixels < position.maxScrollExtent) {
      return maxVelocity * ((edgeThreshold - trailingDistance) / edgeThreshold);
    }

    return 0;
  }

  void _stop() {
    _pointer = null;
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: _viewportKey,
      decoration: const BoxDecoration(),
      child: widget.child,
    );
  }
}
