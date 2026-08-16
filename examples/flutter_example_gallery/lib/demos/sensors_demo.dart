import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// The `sensors` catalog demo: a [DndSensorActivationConstraint] decides how
/// deliberate a gesture must be before a drag begins, so a tap is never
/// mistaken for a drag.
class SensorsDemo extends StatefulWidget {
  const SensorsDemo({super.key});

  @override
  State<SensorsDemo> createState() => _SensorsDemoState();
}

enum _Mode { immediate, distance, delay }

class _SensorsDemoState extends State<SensorsDemo> {
  _Mode _mode = _Mode.distance;
  late final DndController _controller = DndController()
    ..addListener(_handleChanged);

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  void _select(_Mode mode) {
    if (mode != _mode) setState(() => _mode = mode);
  }

  DndSensorActivationConstraint _constraintFor(_Mode mode) {
    return switch (mode) {
      _Mode.immediate => DndSensorActivationConstraint.none,
      _Mode.distance => const DndSensorActivationConstraint(distance: 12),
      _Mode.delay => const DndSensorActivationConstraint(
          delay: Duration(milliseconds: 250),
        ),
    };
  }

  String _modeLabel(_Mode mode) {
    return switch (mode) {
      _Mode.immediate => 'Immediate',
      _Mode.distance => 'Distance 12px',
      _Mode.delay => 'Delay 250ms',
    };
  }

  String _modeHint(_Mode mode) {
    return switch (mode) {
      _Mode.immediate => 'Lifts on the first move',
      _Mode.distance => 'Move 12px to lift',
      _Mode.delay => 'Hold 250ms to lift',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dragging = _controller.isDragging;

    return DndScope(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('Sensors & activation')),
        body: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'The pointer sensor only starts a drag once the gesture '
                    'clears its activation constraint. Try each mode.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final mode in _Mode.values)
                        ChoiceChip(
                          label: Text(_modeLabel(mode)),
                          selected: mode == _mode,
                          onSelected: (_) => _select(mode),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Dragging: ${dragging ? 'yes' : 'no'}'),
                  const Spacer(),
                  Center(
                    child: DndDraggable(
                      key: ValueKey<_Mode>(_mode),
                      id: const DndId('sensor-card'),
                      activationConstraint: _constraintFor(_mode),
                      builder: (context, details, child) => Opacity(
                        opacity: details.isDragging ? 0.4 : 1,
                        child: child,
                      ),
                      child: _SensorCard(label: _modeHint(_mode)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            DndDragOverlay(
              controller: _controller,
              builder: (context, details) => demoCard(
                width: 200,
                lifted: true,
                child: const Text('Dragging'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return demoCard(width: 200, child: Text(label));
  }
}
