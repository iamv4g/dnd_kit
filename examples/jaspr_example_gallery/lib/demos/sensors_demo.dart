import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../ui.dart';

/// Sensors & activation: a [DndSensorActivationConstraint] decides how
/// deliberate a gesture must be before a drag begins, so a tap or click is
/// never mistaken for a drag.
class SensorsDemo extends StatefulComponent {
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
    if (mounted) {
      setState(() {});
    }
  }

  void _select(_Mode mode) {
    if (mode != _mode) {
      setState(() => _mode = mode);
    }
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

  @override
  Component build(BuildContext context) {
    final dragging = _controller.activeSession != null;

    return DndScope(
      controller: _controller,
      child: DemoPanel(
        children: [
          const DemoIntro(
            title: 'Sensors & activation',
            description:
                'The pointer sensor only starts a drag once the gesture clears '
                'its activation constraint. Try each mode: immediate lifts on '
                'the first move, distance needs a 12px drag, and delay needs a '
                '250ms press-and-hold.',
          ),
          div(
            styles: Styles(display: .flex, flexWrap: .wrap, gap: .all(10.px)),
            [
              _modeButton(_Mode.immediate, 'Immediate'),
              _modeButton(_Mode.distance, 'Distance 12px'),
              _modeButton(_Mode.delay, 'Delay 250ms'),
            ],
          ),
          StatusBar(
            children: [
              Pill(label: 'Activation', value: _modeLabel(_mode)),
              Pill(label: 'Dragging', value: dragging ? 'yes' : 'no'),
            ],
          ),
          div(
            styles: Styles(
              display: .flex,
              position: .relative(),
              height: 220.px,
              shadow: kLift,
              radius: .circular(22.px),
              justifyContent: .center,
              alignItems: .center,
              backgroundColor: cPanelBg,
            ),
            [
              DndDraggable(
                key: ValueKey<_Mode>(_mode),
                id: const DndId('sensor-card'),
                constraint: _constraintFor(_mode),
                label: 'Activation test card',
                description:
                    'Press space to pick up, arrow keys to move, space to drop, '
                    'escape to cancel.',
                child: _card(_modeHint(_mode), cCardBg),
              ),
              DndDragOverlay(
                builder: (context, overlayDetails) =>
                    _card('Dragging', cAccent, light: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Component _card(String label, Color background, {bool light = false}) {
    return div(
      styles: Styles(
        maxWidth: 240.px,
        padding: .symmetric(vertical: 18.px, horizontal: 22.px),
        shadow: kLift,
        radius: .circular(18.px),
        cursor: .grab,
        userSelect: .none,
        fontWeight: .w600,
        textAlign: .center,
        color: light ? cWhiteWarm : cText,
        backgroundColor: background,
      ),
      [.text(label)],
    );
  }

  Component _modeButton(_Mode mode, String label) {
    final active = mode == _mode;
    return button(
      styles: Styles(
        padding: .symmetric(vertical: 10.px, horizontal: 16.px),
        border: .none,
        radius: .circular(999.px),
        shadow: kLift,
        cursor: .pointer,
        fontFamily: kFontFamily,
        fontSize: 14.px,
        fontWeight: .w700,
        color: active ? cWhiteWarm : cMuted,
        backgroundColor: active ? cAccentBright : cPillBg,
        transition: kSettle,
      ),
      onClick: () => _select(mode),
      [.text(label)],
    );
  }

  String _modeLabel(_Mode mode) {
    return switch (mode) {
      _Mode.immediate => 'none',
      _Mode.distance => 'distance: 12',
      _Mode.delay => 'delay: 250ms',
    };
  }

  String _modeHint(_Mode mode) {
    return switch (mode) {
      _Mode.immediate => 'Lifts on the first move',
      _Mode.distance => 'Move 12px to lift',
      _Mode.delay => 'Hold 250ms to lift',
    };
  }
}
