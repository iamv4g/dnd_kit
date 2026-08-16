import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// The `auto-scroll` catalog demo: [DndAutoScroll] scrolls a bounded list while
/// the drag pointer rests in its edge band, so the token can reach an
/// off-screen slot.
class AutoScrollDemo extends StatefulWidget {
  const AutoScrollDemo({super.key});

  @override
  State<AutoScrollDemo> createState() => _AutoScrollDemoState();
}

class _AutoScrollDemoState extends State<AutoScrollDemo> {
  static const int _slotCount = 14;

  late final DndController _controller = DndController();
  int _tokenSlot = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragEnd(DndDragEndEvent event) {
    final overId = event.overId;
    if (overId != null && overId.value.startsWith('slot-')) {
      setState(() {
        _tokenSlot = int.parse(overId.value.substring('slot-'.length));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DndScope(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('Auto-scroll')),
        body: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Pick up the token and drag it toward the top or bottom '
                    'edge of the bounded list. DndAutoScroll scrolls while the '
                    'pointer stays in the edge band, so the token can reach an '
                    'off-screen slot.',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    // The bounded scroller is a recess, so the edge band the
                    // auto-scroll reacts to reads as an inside edge.
                    child: DecoratedBox(
                      decoration: dropZoneDecoration(isOver: false, radius: 24),
                      child: ClipPath(
                        clipper: ShapeBorderClipper(shape: squircle(24)),
                        child: DndAutoScroll(
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: <Widget>[
                              for (var slot = 1; slot <= _slotCount; slot++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _Slot(
                                    slot: slot,
                                    hasToken: slot == _tokenSlot,
                                    onDragEnd: _handleDragEnd,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DndDragOverlay(
              controller: _controller,
              builder: (context, details) => _Token(lifted: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.slot,
    required this.hasToken,
    required this.onDragEnd,
  });

  final int slot;
  final bool hasToken;
  final DndDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return DndDroppable(
      id: DndId('slot-$slot'),
      builder: (context, details, child) {
        return AnimatedContainer(
          duration: GalleryTokens.settle,
          curve: Curves.easeOutCubic,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: details.isOver
              ? dropZoneDecoration(isOver: true, radius: 18)
              : cardDecoration(radius: 18),
          child: child,
        );
      },
      child: Row(
        children: <Widget>[
          Text(
            'Slot $slot',
            style: const TextStyle(
              color: GalleryTokens.faint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (hasToken)
            DndDraggable(
              id: const DndId('auto-scroll-token'),
              onDragEnd: onDragEnd,
              builder: (context, details, child) =>
                  Opacity(opacity: details.isDragging ? 0.3 : 1, child: child),
              child: const _Token(),
            ),
        ],
      ),
    );
  }
}

/// The draggable token: a gradient capsule cut from the same Flutter→Dart ramp
/// as the site's primary button.
class _Token extends StatelessWidget {
  const _Token({this.lifted = false});

  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: <Color>[GalleryTokens.accentDeep, GalleryTokens.accent],
        ),
        shape: const StadiumBorder(),
        shadows: lifted ? GalleryTokens.liftHigh : GalleryTokens.lift,
      ),
      child: const Text(
        'Drag token',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
    if (!lifted) return chip;
    return Transform.rotate(
      angle: 0.035,
      child: Transform.scale(scale: 1.04, child: chip),
    );
  }
}
