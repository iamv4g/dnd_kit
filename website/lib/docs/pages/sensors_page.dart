import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/sensors`
class SensorsPage extends StatelessComponent {
  const SensorsPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'sensors',
      toc: const [
        (id: 'what', label: 'What sensors do'),
        (id: 'activation', label: 'Activation constraints'),
        (id: 'keyboard', label: 'Keyboard'),
      ],
      body: [
        docLead(
          'Sensors translate raw input — pointer, keyboard — into drag intent. '
          'The pointer sensor is active by default; activation constraints '
          'decide how deliberate a gesture must be before a drag begins.',
        ),
        youWillLearn(const [
          'How sensors turn input into drags.',
          'How to require a distance or delay before activation.',
          'How keyboard dragging fits in.',
        ]),
        docSection(
          id: 'what',
          title: 'What sensors do',
          children: [
            docProseRich([
              docText('A '),
              inlineCode('DndSensor'),
              docText(
                ' watches an input source and starts, updates, and ends '
                'a drag on the controller. The built-in ',
              ),
              inlineCode('DndPointerSensor'),
              docText(
                ' handles mouse, touch, and pen through unified pointer '
                'events, so the same code works across devices.',
              ),
            ]),
          ],
        ),
        docSection(
          id: 'activation',
          title: 'Activation constraints',
          children: [
            docProseRich([
              docText('A '),
              inlineCode('DndSensorActivationConstraint'),
              docText(
                ' delays activation until the gesture clears a threshold, so a '
                'tap or click is never mistaken for a drag. Set a small '
                'distance for immediate-feeling drags, or a delay for '
                'press-and-hold.',
              ),
            ]),
            const CodeTabs(
              flutterFile: 'activation.dart',
              jasprFile: 'activation.dart',
              flutter: _distanceCode,
              jaspr: _distanceCode,
            ),
            docProse('A press delay instead of a distance:'),
            const CodeTabs(
              flutterFile: 'activation.dart',
              jasprFile: 'activation.dart',
              flutter: _delayCode,
              jaspr: _delayCode,
            ),
          ],
        ),
        docSection(
          id: 'keyboard',
          title: 'Keyboard',
          children: [
            docProse(
              'Keyboard dragging is built in: a focused draggable is picked up '
              'with space or enter, moved with the arrow keys, and cancelled '
              'with escape — no extra wiring. See the accessibility page for '
              'the full keyboard model.',
            ),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Accessibility',
            desc: 'The full keyboard and announcement model.',
            href: docHref('accessibility'),
          ),
          NextStep(
            label: 'Modifiers',
            desc: 'Constrain the drag transform.',
            href: docHref('modifiers'),
          ),
        ]),
      ],
    );
  }
}

const _distanceCode = '''DndDraggable(
  id: const DndId('card'),
  constraint: const DndSensorActivationConstraint(distance: 6),
  child: card,
)''';

const _delayCode = '''DndDraggable(
  id: const DndId('card'),
  constraint: const DndSensorActivationConstraint(
    delay: Duration(milliseconds: 200),
  ),
  child: card,
)''';
