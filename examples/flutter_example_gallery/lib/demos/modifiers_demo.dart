import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// The `modifiers` catalog demo: [DndModifiers] reshape the active drag
/// transform before collision. Modifiers are fixed per controller, so switching
/// one rebuilds the controller.
class ModifiersDemo extends StatefulWidget {
  const ModifiersDemo({super.key});

  @override
  State<ModifiersDemo> createState() => _ModifiersDemoState();
}

enum _Choice { none, vertical, horizontal, grid }

class _ModifiersDemoState extends State<ModifiersDemo> {
  _Choice _choice = _Choice.vertical;
  DndController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  DndController get _activeController {
    return _controller ??= DndController(modifiers: _modifiersFor(_choice));
  }

  void _select(_Choice choice) {
    if (choice == _choice) return;
    setState(() {
      _choice = choice;
      _controller?.dispose();
      _controller = null;
    });
  }

  List<DndModifier> _modifiersFor(_Choice choice) {
    return switch (choice) {
      _Choice.none => const <DndModifier>[],
      _Choice.vertical => <DndModifier>[DndModifiers.restrictToVerticalAxis],
      _Choice.horizontal => <DndModifier>[
          DndModifiers.restrictToHorizontalAxis
        ],
      _Choice.grid => <DndModifier>[
          DndModifiers.snapToGrid(width: 40, height: 40),
        ],
    };
  }

  String _choiceLabel(_Choice choice) {
    return switch (choice) {
      _Choice.none => 'None',
      _Choice.vertical => 'Vertical axis',
      _Choice.horizontal => 'Horizontal axis',
      _Choice.grid => 'Snap to grid',
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = _activeController;

    return DndScope(
      key: ValueKey<_Choice>(_choice),
      controller: controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('Modifiers')),
        body: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Pick a modifier and drag the card. The modifier reshapes '
                    'the transform in the shared runtime before collision, so '
                    'the overlay follows the constrained path.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final choice in _Choice.values)
                        ChoiceChip(
                          label: Text(_choiceLabel(choice)),
                          selected: choice == _choice,
                          onSelected: (_) => _select(choice),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: DndDraggable(
                      id: const DndId('modifier-card'),
                      builder: (context, details, child) => Opacity(
                        opacity: details.isDragging ? 0.4 : 1,
                        child: child,
                      ),
                      child: _ModifierCard(label: _choiceLabel(_choice)),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            DndDragOverlay(
              controller: controller,
              builder: (context, details) => demoCard(
                width: 200,
                lifted: true,
                child: const Text('Following the modifier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModifierCard extends StatelessWidget {
  const _ModifierCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return demoCard(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Drag me'),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: GalleryTokens.muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
