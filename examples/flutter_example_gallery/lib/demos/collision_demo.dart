import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// The `collision` catalog demo: the active [DndCollisionDetector] decides which
/// zone wins when the dragged card overlaps several targets. The detector is
/// fixed per controller, so switching one rebuilds the controller.
class CollisionDemo extends StatefulWidget {
  const CollisionDemo({super.key});

  @override
  State<CollisionDemo> createState() => _CollisionDemoState();
}

enum _Detector { closestCenter, rectIntersection, pointerWithin }

const _zoneIds = <String>['zone-a', 'zone-b', 'zone-c'];

class _CollisionDemoState extends State<CollisionDemo> {
  _Detector _detector = _Detector.closestCenter;
  DndController? _controller;

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _controller
      ?..removeListener(_handleChanged)
      ..dispose();
    _controller = null;
  }

  DndController get _activeController {
    return _controller ??=
        DndController(collisionDetector: _detectorFor(_detector))
          ..addListener(_handleChanged);
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  void _select(_Detector detector) {
    if (detector == _detector) return;
    setState(() {
      _detector = detector;
      _disposeController();
    });
  }

  DndCollisionDetector _detectorFor(_Detector detector) {
    return switch (detector) {
      _Detector.closestCenter => DndCollisionDetectors.closestCenter,
      _Detector.rectIntersection => DndCollisionDetectors.rectIntersection,
      _Detector.pointerWithin => DndCollisionDetectors.pointerWithin,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = _activeController;
    final over = controller.overId?.value;

    return DndScope(
      key: ValueKey<_Detector>(_detector),
      controller: controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('Collision detection')),
        body: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Drag the card across the zones. The active detector — '
                    'shared math in dnd_kit — decides which zone is "over".',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final detector in _Detector.values)
                        ChoiceChip(
                          label: Text(_detectorLabel(detector)),
                          selected: detector == _detector,
                          onSelected: (_) => _select(detector),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Over: ${over ?? 'none'}'),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      for (final id in _zoneIds) ...<Widget>[
                        Expanded(child: _Zone(id: id)),
                        if (id != _zoneIds.last) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                  const Spacer(),
                  const Center(child: _CollisionCard(label: 'Drag me')),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            DndDragOverlay(
              controller: controller,
              builder: (context, details) =>
                  const _CollisionCard(label: 'Resolving…', overlay: true),
            ),
          ],
        ),
      ),
    );
  }

  String _detectorLabel(_Detector detector) {
    return switch (detector) {
      _Detector.closestCenter => 'closestCenter',
      _Detector.rectIntersection => 'rectIntersection',
      _Detector.pointerWithin => 'pointerWithin',
    };
  }
}

class _Zone extends StatelessWidget {
  const _Zone({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return DndDroppable(
      id: DndId(id),
      builder: (context, details, child) {
        return AnimatedContainer(
          duration: GalleryTokens.settle,
          curve: Curves.easeOutCubic,
          height: 120,
          alignment: Alignment.center,
          decoration: dropZoneDecoration(isOver: details.isOver),
          child: child,
        );
      },
      child: Text(
        id,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: GalleryTokens.muted,
        ),
      ),
    );
  }
}

class _CollisionCard extends StatelessWidget {
  const _CollisionCard({required this.label, this.overlay = false});

  final String label;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: GalleryTokens.surface,
        shape: squircle(20),
        shadows: overlay ? GalleryTokens.liftHigh : GalleryTokens.lift,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: GalleryTokens.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    // The lifted copy leans; the resting one does not.
    if (overlay) {
      return Transform.rotate(
        angle: 0.035,
        child: Transform.scale(scale: 1.04, child: card),
      );
    }
    return DndDraggable(
      id: const DndId('collision-card'),
      builder: (context, details, child) =>
          Opacity(opacity: details.isDragging ? 0.4 : 1, child: child),
      child: card,
    );
  }
}
