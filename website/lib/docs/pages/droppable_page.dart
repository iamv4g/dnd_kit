import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/droppable`
class DroppablePage extends StatelessComponent {
  const DroppablePage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'droppable',
      toc: const [
        (id: 'usage', label: 'Usage'),
        (id: 'collision', label: 'Collision detection'),
        (id: 'feedback', label: 'Hover feedback'),
      ],
      body: [
        docLead(
          'A droppable is a target a draggable can land on. Mark an area with '
          'DndDroppable and a unique id; the engine reports when a draggable '
          'is over it and which target a drag ends on.',
        ),
        youWillLearn(const [
          'How to define a drop target.',
          'How the engine decides which target is under the pointer.',
          'How to give visual feedback while a draggable hovers.',
        ]),
        docSection(
          id: 'usage',
          title: 'Usage',
          children: [
            docProseRich([
              docText('Give each droppable a unique '),
              inlineCode('DndId'),
              docText('. On the draggable, '),
              inlineCode('onDragEnd'),
              docText(' reports the target id through '),
              inlineCode('event.overId'),
              docText('.'),
            ]),
            const CodeTabs(
              flutterFile: 'droppable.dart',
              jasprFile: 'droppable.dart',
              flutter: _usageFlutter,
              jaspr: _usageJaspr,
            ),
          ],
        ),
        docSection(
          id: 'collision',
          title: 'Collision detection',
          children: [
            docProse(
              'When a draggable overlaps several droppables, a collision '
              'strategy decides which one wins. The strategy is shared math in '
              'the engine, so Flutter and Jaspr resolve the same target:',
            ),
            docBullets(const [
              'Closest center — the target whose center is nearest the '
                  'pointer. A solid default for grids and free layouts.',
              'Largest overlap — the target the dragged element overlaps most. '
                  'Natural for list and Kanban reordering.',
            ]),
          ],
        ),
        docSection(
          id: 'feedback',
          title: 'Hover feedback',
          children: [
            docProse(
              'Read whether a target is currently being hovered to highlight '
              'it — the drop zones on this site light up exactly this way.',
            ),
            const CodeTabs(
              flutterFile: 'feedback.dart',
              jasprFile: 'feedback.dart',
              flutter: _feedbackFlutter,
              jaspr: _feedbackJaspr,
            ),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Drag overlay',
            desc: 'Render a floating preview that follows the pointer.',
            href: docHref('overlay'),
          ),
          NextStep(
            label: 'Sortable lists',
            desc: 'Reorder a list without wiring targets by hand.',
            href: docHref('sortable'),
          ),
        ]),
      ],
    );
  }
}

const _usageFlutter = '''DndDroppable(
  id: const DndId('inbox'),
  child: const SizedBox(width: 240, height: 160, child: Text('Inbox')),
)''';

const _usageJaspr = '''DndDroppable(
  id: const DndId('inbox'),
  child: div([.text('Inbox')]),
)''';

const _feedbackFlutter = '''DndDroppable(
  id: const DndId('inbox'),
  builder: (context, state, child) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(
        color: state.isOver ? Colors.orange : Colors.grey,
      ),
    ),
    child: child,
  ),
  child: const Text('Inbox'),
)''';

const _feedbackJaspr = '''DndDroppable(
  id: const DndId('inbox'),
  builder: (context, state, child) => div(
    classes: state.isOver ? 'border-accent' : 'border-line',
    [child],
  ),
  child: div([.text('Inbox')]),
)''';
