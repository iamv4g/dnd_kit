import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/multi-container`
class MultiContainerPage extends StatelessComponent {
  const MultiContainerPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'multi-container',
      toc: const [
        (id: 'anatomy', label: 'Anatomy'),
        (id: 'usage', label: 'Usage'),
        (id: 'state', label: 'Applying moves'),
      ],
      body: [
        docLead(
          'Multi-container sortable moves items within and across lists — the '
          'shape of a Kanban board. It is a supported preset over the shared '
          'engine, so the same code drives Flutter and the web.',
        ),
        youWillLearn(const [
          'The three components that make a multi-list board.',
          'How to wire columns and cards.',
          'How to apply a cross-list move to your own state.',
        ]),
        docSection(
          id: 'anatomy',
          title: 'Anatomy',
          children: [
            docBullets(const [
              'SortableMultiScope — owns the whole board and the move policy '
                  'across all columns.',
              'SortableMultiContainerArea — one column; a drop region that '
                  'holds an ordered list of items.',
              'SortableMultiItem — one card; draggable within and between '
                  'columns.',
            ]),
          ],
        ),
        docSection(
          id: 'usage',
          title: 'Usage',
          children: [
            docProse(
              'Nest the three components and feed them your board model — a map '
              'of column id to the ordered card ids in that column.',
            ),
            const CodeTabs(
              flutterFile: 'board.dart',
              jasprFile: 'board.dart',
              flutter: _usageFlutter,
              jaspr: _usageJaspr,
            ),
          ],
        ),
        docSection(
          id: 'state',
          title: 'Applying moves',
          children: [
            docProse(
              'A move reports the source and target column plus the indices. '
              'You remove the card from its old column and insert it into the '
              'new one — the board owns its data, the engine only resolves '
              'intent. The Kanban showcase on the home page is built on exactly '
              'this preset.',
            ),
            const CodeTabs(
              flutterFile: 'on_move.dart',
              jasprFile: 'on_move.dart',
              flutter: _moveCode,
              jaspr: _moveCode,
            ),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Sortable lists',
            desc: 'The single-list preset this builds on.',
            href: docHref('sortable'),
          ),
          NextStep(
            label: 'Accessibility',
            desc: 'Keyboard moves across columns, announced.',
            href: docHref('accessibility'),
          ),
        ]),
      ],
    );
  }
}

const _usageFlutter = '''SortableMultiScope(
  controller: controller,
  columnIds: columns, // List<DndId>
  onMove: _onMove,
  child: Row(
    children: [
      for (final columnId in columns)
        SortableMultiContainerArea(
          id: columnId,
          itemIds: board[columnId]!,
          child: Column(
            children: [
              for (final cardId in board[columnId]!)
                SortableMultiItem(id: cardId, child: CardTile(cardId)),
            ],
          ),
        ),
    ],
  ),
)''';

const _usageJaspr = '''SortableMultiScope(
  controller: controller,
  columnIds: columns, // List<DndId>
  onMove: _onMove,
  child: div([
    for (final columnId in columns)
      SortableMultiContainerArea(
        id: columnId,
        itemIds: board[columnId]!,
        child: div([
          for (final cardId in board[columnId]!)
            SortableMultiItem(id: cardId, child: cardTile(cardId)),
        ]),
      ),
  ]),
)''';

const _moveCode = '''void _onMove(SortableMultiMoveDetails details) {
  setState(() {
    final card = board[details.fromColumn]!.removeAt(details.fromIndex);
    board[details.toColumn]!.insert(details.toIndex, card);
  });
}''';
