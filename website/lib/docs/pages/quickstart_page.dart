import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/quickstart`
class QuickstartPage extends StatelessComponent {
  const QuickstartPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'quickstart',
      toc: const [
        (id: 'scope', label: 'Wrap in a scope'),
        (id: 'draggable', label: 'Make a draggable'),
        (id: 'droppable', label: 'Add a droppable'),
        (id: 'together', label: 'Put it together'),
      ],
      body: [
        docLead(
          'Three steps to your first drag-and-drop: wrap an area in a scope, '
          'mark a draggable and a drop target, then react when they meet. The '
          'API is the same on Flutter and Jaspr — switch the tab on any '
          'snippet to compare.',
        ),
        youWillLearn(const [
          'How to wrap an interactive area in a DndScope.',
          'How to make an element draggable and define a drop target.',
          'How to react to a drop with onDragEnd.',
        ]),
        docSection(
          id: 'scope',
          title: 'Wrap in a scope',
          children: [
            docProseRich([
              docText('A '),
              inlineCode('DndScope'),
              docText(
                ' owns one drag interaction. Everything draggable or droppable '
                'lives inside it. Start by wrapping the area you want to make '
                'interactive.',
              ),
            ]),
          ],
        ),
        docSection(
          id: 'draggable',
          title: 'Make a draggable',
          children: [
            docProseRich([
              docText('Wrap any element in a '),
              inlineCode('DndDraggable'),
              docText(' with a unique '),
              inlineCode('DndId'),
              docText('. That is all it takes to pick it up.'),
            ]),
            const CodeTabs(
              flutterFile: 'draggable.dart',
              jasprFile: 'draggable.dart',
              flutter: _draggableFlutter,
              jaspr: _draggableJaspr,
            ),
          ],
        ),
        docSection(
          id: 'droppable',
          title: 'Add a droppable',
          children: [
            docProseRich([
              docText('A '),
              inlineCode('DndDroppable'),
              docText(
                ' is a target a draggable can land on. It also takes a unique '
                'id, which you read back when the drag ends.',
              ),
            ]),
            const CodeTabs(
              flutterFile: 'droppable.dart',
              jasprFile: 'droppable.dart',
              flutter: _droppableFlutter,
              jaspr: _droppableJaspr,
            ),
          ],
        ),
        docSection(
          id: 'together',
          title: 'Put it together',
          children: [
            docProseRich([
              docText('Listen to '),
              inlineCode('onDragEnd'),
              docText(
                ' to move your data when a draggable lands on a target. You own '
                'the state; dnd_kit reports the move.',
              ),
            ]),
            const CodeTabs(
              flutterFile: 'main.dart',
              jasprFile: 'main.dart',
              flutter: _togetherFlutter,
              jaspr: _togetherJaspr,
            ),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Draggable',
            desc: 'Drag handles, activation, and drag data in depth.',
            href: docHref('draggable'),
          ),
          NextStep(
            label: 'Sortable lists',
            desc: 'Reorder a list with the sortable preset.',
            href: docHref('sortable'),
          ),
        ]),
      ],
    );
  }
}

const _draggableFlutter =
    '''import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/widgets.dart';

DndDraggable(
  id: const DndId('card'),
  child: const Text('Drag me'),
)''';

const _draggableJaspr = '''import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';

DndDraggable(
  id: const DndId('card'),
  child: div([.text('Drag me')]),
)''';

const _droppableFlutter = '''DndDroppable(
  id: const DndId('inbox'),
  child: const Text('Inbox'),
)''';

const _droppableJaspr = '''DndDroppable(
  id: const DndId('inbox'),
  child: div([.text('Inbox')]),
)''';

const _togetherFlutter = '''DndScope(
  child: Column(
    children: [
      DndDraggable(
        id: const DndId('card'),
        onDragEnd: (event) {
          if (event.overId == const DndId('inbox')) {
            moveCardToInbox();
          }
        },
        child: const Text('Drag me'),
      ),
      DndDroppable(
        id: const DndId('inbox'),
        child: const Text('Inbox'),
      ),
    ],
  ),
)''';

const _togetherJaspr = '''DndScope(
  child: div([
    DndDraggable(
      id: const DndId('card'),
      onDragEnd: (event) {
        if (event.overId == const DndId('inbox')) {
          moveCardToInbox();
        }
      },
      child: div([.text('Drag me')]),
    ),
    DndDroppable(
      id: const DndId('inbox'),
      child: div([.text('Inbox')]),
    ),
  ]),
)''';
