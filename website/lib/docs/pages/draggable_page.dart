import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/draggable`
class DraggablePage extends StatelessComponent {
  const DraggablePage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'draggable',
      toc: const [
        (id: 'usage', label: 'Usage'),
        (id: 'handle', label: 'Drag handles'),
        (id: 'activation', label: 'Activation'),
        (id: 'events', label: 'Drag events'),
      ],
      body: [
        docLead(
          'A draggable is any element that can be picked up and moved. Wrap it '
          'in DndDraggable, give it a stable DndId, and the engine handles the '
          'pointer, keyboard, and transform.',
        ),
        youWillLearn(const [
          'How to make an element draggable.',
          'How to restrict the drag surface to a handle.',
          'How to require intent before a drag begins.',
          'Which events fire over a drag lifecycle.',
        ]),
        docSection(
          id: 'usage',
          title: 'Usage',
          children: [
            docProseRich([
              docText('Every draggable needs a unique '),
              inlineCode('DndId'),
              docText(
                ' within its scope. The id is how collision results and drag '
                'events refer back to it.',
              ),
            ]),
            const CodeTabs(
              flutterFile: 'draggable.dart',
              jasprFile: 'draggable.dart',
              flutter: _usageFlutter,
              jaspr: _usageJaspr,
            ),
          ],
        ),
        docSection(
          id: 'handle',
          title: 'Drag handles',
          children: [
            docProseRich([
              docText('Wrap part of the child in a '),
              inlineCode('DndDragHandle'),
              docText(
                ' to make only that part the drag surface — useful when the '
                'rest of the element stays interactive (links, buttons, text '
                'selection).',
              ),
            ]),
            const CodeTabs(
              flutterFile: 'handle.dart',
              jasprFile: 'handle.dart',
              flutter: _handleFlutter,
              jaspr: _handleJaspr,
            ),
          ],
        ),
        docSection(
          id: 'activation',
          title: 'Activation',
          children: [
            docProseRich([
              docText('Pass a '),
              inlineCode('DndSensorActivationConstraint'),
              docText(
                ' so a drag only starts after deliberate intent — a small '
                'distance or a press delay — instead of on the first pixel of '
                'movement. This keeps taps and clicks responsive.',
              ),
            ]),
            const CodeTabs(
              flutterFile: 'activation.dart',
              jasprFile: 'activation.dart',
              flutter: _activationFlutter,
              jaspr: _activationJaspr,
            ),
          ],
        ),
        docSection(
          id: 'events',
          title: 'Drag events',
          children: [
            docProse('A draggable reports its lifecycle through callbacks:'),
            docBullets(const [
              'onDragStart — the drag was activated and picked up.',
              'onDragUpdate — the pointer moved; the active transform changed.',
              'onDragEnd — the drag finished; read event.overId for the target '
                  'it landed on, or handle a cancel.',
            ]),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Droppable',
            desc: 'Define the targets a draggable can land on.',
            href: docHref('droppable'),
          ),
          NextStep(
            label: 'Drag overlay',
            desc: 'Render a floating preview that follows the pointer.',
            href: docHref('overlay'),
          ),
        ]),
      ],
    );
  }
}

const _usageFlutter = '''DndDraggable(
  id: const DndId('card-1'),
  data: card, // optional payload carried through the drag
  child: CardTile(card),
)''';

const _usageJaspr = '''DndDraggable(
  id: const DndId('card-1'),
  data: card, // optional payload carried through the drag
  child: cardTile(card),
)''';

const _handleFlutter = '''DndDraggable(
  id: const DndId('card-1'),
  child: Row(
    children: [
      DndDragHandle(
        label: 'Reorder card',
        child: const Icon(Icons.drag_indicator),
      ),
      const Expanded(child: Text('Card title')),
    ],
  ),
)''';

const _handleJaspr = '''DndDraggable(
  id: const DndId('card-1'),
  child: div([
    DndDragHandle(
      label: 'Reorder card',
      child: span([.text('⠿')]),
    ),
    span([.text('Card title')]),
  ]),
)''';

const _activationFlutter = '''DndDraggable(
  id: const DndId('card-1'),
  constraint: const DndSensorActivationConstraint(distance: 6),
  child: CardTile(card),
)''';

const _activationJaspr = '''DndDraggable(
  id: const DndId('card-1'),
  constraint: const DndSensorActivationConstraint(distance: 6),
  child: cardTile(card),
)''';
