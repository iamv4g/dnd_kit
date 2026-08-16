import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// The `accessibility` catalog demo: every draggable is operable from the
/// keyboard, and the adapter emits semantics announcements as the drag
/// progresses — accessibility is built in, not bolted on.
class AccessibilityDemo extends StatefulWidget {
  const AccessibilityDemo({super.key});

  @override
  State<AccessibilityDemo> createState() => _AccessibilityDemoState();
}

const _laneIds = <String>['todo', 'doing', 'done'];
const _laneLabels = <String, String>{
  'todo': 'To do',
  'doing': 'Doing',
  'done': 'Done',
};

class _AccessibilityDemoState extends State<AccessibilityDemo> {
  late final DndController _controller = DndController();
  String _lane = 'todo';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragEnd(DndDragEndEvent event) {
    final overId = event.overId;
    if (overId != null && _laneIds.contains(overId.value)) {
      setState(() => _lane = overId.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DndScope(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('Accessibility')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _Instructions(),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final id in _laneIds) ...<Widget>[
                      Expanded(
                        child: _Lane(
                          id: id,
                          hasCard: id == _lane,
                          onDragEnd: _handleDragEnd,
                        ),
                      ),
                      if (id != _laneIds.last) const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions();

  @override
  Widget build(BuildContext context) {
    // An aside is a recess in the reading surface, not a bordered box.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: GalleryTokens.raised.withValues(alpha: 0.7),
        shape: squircle(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            'Operate the card without a mouse:',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: GalleryTokens.ink,
            ),
          ),
          SizedBox(height: 6),
          Text('• Tab to focus the card, then Space or Enter to pick it up.'),
          Text('• Arrow keys move it between lanes; Space drops it.'),
          Text('• Escape cancels and returns it. A live region announces each '
              'step.'),
        ],
      ),
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane({
    required this.id,
    required this.hasCard,
    required this.onDragEnd,
  });

  final String id;
  final bool hasCard;
  final DndDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return DndDroppable(
      id: DndId(id),
      builder: (context, details, child) {
        return AnimatedContainer(
          duration: GalleryTokens.settle,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: dropZoneDecoration(isOver: details.isOver),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          galleryEyebrow(_laneLabels[id]!),
          const SizedBox(height: 10),
          if (hasCard)
            DndDraggable(
              id: const DndId('a11y-card'),
              label: 'Release task',
              hint: 'Drag or use the keyboard to move between lanes',
              onDragEnd: onDragEnd,
              builder: (context, details, child) =>
                  Opacity(opacity: details.isDragging ? 0.3 : 1, child: child),
              child: demoCard(
                radius: 16,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                child: const Text('Release task'),
              ),
            ),
        ],
      ),
    );
  }
}
