import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The recurring grip-dot (⠿) drag handle used across the page.
///
/// Must be rendered inside a [DndDraggable]; it wraps [DndDragHandle] so a
/// drag starts only from the handle, and exposes [label] as the accessible
/// name for keyboard and screen-reader users.
class Grip extends StatelessComponent {
  const Grip({required this.label, super.key});

  final String label;

  @override
  Component build(BuildContext context) {
    return DndDragHandle(
      label: label,
      child: span(
        classes: 'grip',
        attributes: const {'aria-hidden': 'true'},
        [.text('⠿')],
      ),
    );
  }
}
