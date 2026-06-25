import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/sortable`
class SortablePage extends StatelessComponent {
  const SortablePage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'sortable',
      toc: const [
        (id: 'usage', label: 'Usage'),
        (id: 'strategies', label: 'Strategies'),
        (id: 'state', label: 'Managing state'),
      ],
      body: [
        docLead(
          'The sortable preset turns a list into a reorderable one without '
          'wiring draggables and droppables by hand. Wrap the list in a '
          'SortableScope and each item in a SortableItem.',
        ),
        youWillLearn(const [
          'How to make a single list reorderable.',
          'Which layout strategy to pick for lists and grids.',
          'How to apply the reported move to your own state.',
        ]),
        docSection(
          id: 'usage',
          title: 'Usage',
          children: [
            docProseRich([
              docText('A '),
              inlineCode('SortableScope'),
              docText(' takes the ordered '),
              inlineCode('itemIds'),
              docText(' and an '),
              inlineCode('onMove'),
              docText(' callback; each child is a '),
              inlineCode('SortableItem'),
              docText(' with a matching id.'),
            ]),
            const CodeTabs(
              flutterFile: 'sortable.dart',
              jasprFile: 'sortable.dart',
              flutter: _usageFlutter,
              jaspr: _usageJaspr,
            ),
          ],
        ),
        docSection(
          id: 'strategies',
          title: 'Strategies',
          children: [
            docProseRich([
              docText('Pick a '),
              inlineCode('SortableStrategies'),
              docText(' to match your layout:'),
            ]),
            docBullets(const [
              'verticalList — a stacked column of items.',
              'horizontalList — a row of items, e.g. tabs or nav pills.',
              'grid — a wrapping grid that reflows in two dimensions.',
            ]),
          ],
        ),
        docSection(
          id: 'state',
          title: 'Managing state',
          children: [
            docProse(
              'dnd_kit reports a move as from/to indices — you own the list and '
              'apply it. Reordering is a remove-then-insert on your data:',
            ),
            const CodeTabs(
              flutterFile: 'on_move.dart',
              jasprFile: 'on_move.dart',
              flutter: _moveFlutter,
              jaspr: _moveJaspr,
            ),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Multi-container sortable',
            desc: 'Move items across lists — a Kanban board.',
            href: docHref('multi-container'),
          ),
          NextStep(
            label: 'Accessibility',
            desc: 'Keyboard reordering and announcements.',
            href: docHref('accessibility'),
          ),
        ]),
      ],
    );
  }
}

const _usageFlutter = '''SortableScope(
  controller: controller,
  strategy: SortableStrategies.verticalList,
  itemIds: order, // List<DndId>
  onMove: _onMove,
  child: Column(
    children: [
      for (final id in order) SortableItem(id: id, child: CardTile(id)),
    ],
  ),
)''';

const _usageJaspr = '''SortableScope(
  controller: controller,
  strategy: SortableStrategies.verticalList,
  itemIds: order, // List<DndId>
  onMove: _onMove,
  child: div([
    for (final id in order) SortableItem(id: id, child: cardTile(id)),
  ]),
)''';

const _moveFlutter = '''void _onMove(SortableMoveDetails details) {
  setState(() {
    final id = order.removeAt(details.fromIndex);
    order.insert(details.toIndex, id);
  });
}''';

const _moveJaspr = '''void _onMove(SortableMoveDetails details) {
  setState(() {
    final id = order.removeAt(details.fromIndex);
    order.insert(details.toIndex, id);
  });
}''';
