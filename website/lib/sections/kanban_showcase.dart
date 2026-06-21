import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../drag/drag_bus.dart';
import '../drag/grip.dart';

/// The centerpiece: an interactive multi-column board.
///
/// The Jaspr adapter ships a single-container sortable preset only, so this
/// cross-column board is built on the generic [DndDraggable] / [DndDroppable]
/// primitives with app-owned move logic — which is exactly what shows off the
/// library's lower layer. Each card is both a draggable and a droppable under
/// the same id (the dnd-kit sortable pattern), columns are droppables, and the
/// board recomputes order on drop.
@client
class KanbanShowcase extends StatefulComponent {
  const KanbanShowcase({super.key});

  @override
  State<KanbanShowcase> createState() => _KanbanShowcaseState();
}

class _KanbanShowcaseState extends State<KanbanShowcase> {
  late final DndController _controller = DndController()
    ..addListener(_onControllerChanged);

  final Map<String, List<DndId>> _board = {
    'col-backlog': [
      const DndId('card-axis'),
      const DndId('card-grid'),
      const DndId('card-rtl'),
      const DndId('card-pointer'),
      const DndId('card-collision'),
      const DndId('card-modifiers'),
      const DndId('card-measure'),
    ],
    'col-progress': [const DndId('card-overlay'), const DndId('card-keyboard')],
    'col-review': [const DndId('card-scroll')],
    'col-done': [const DndId('card-engine'), const DndId('card-ssr')],
  };

  int _moves = 0;

  void _onControllerChanged() {
    dragBus.report(_controller, source: 'kanban');
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  // --- move logic ----------------------------------------------------------

  bool _isColumn(DndId id) => _board.containsKey(id.value);

  String? _columnOf(DndId card) {
    for (final entry in _board.entries) {
      if (entry.value.contains(card)) return entry.key;
    }
    return null;
  }

  void _handleDrop(DndDragEndEvent event) {
    final active = event.activeId;
    final over = event.overId;
    if (over == null || over == active) return;

    final fromCol = _columnOf(active);
    if (fromCol == null) return;

    final String toCol;
    var toIndex = 0;
    if (_isColumn(over)) {
      toCol = over.value;
      toIndex = _board[toCol]!.length;
    } else {
      final overCol = _columnOf(over);
      if (overCol == null) return;
      toCol = overCol;
      toIndex = _board[toCol]!.indexOf(over);
    }

    final fromList = _board[fromCol]!;
    final fromIndex = fromList.indexOf(active);
    if (fromCol == toCol && fromIndex == toIndex) return;

    fromList.removeAt(fromIndex);
    if (fromCol == toCol && fromIndex < toIndex) toIndex -= 1;
    final toList = _board[toCol]!;
    toList.insert(toIndex.clamp(0, toList.length), active);

    setState(() => _moves += 1);
  }

  // --- rendering -----------------------------------------------------------

  DndId? get _overColumn {
    final over = _controller.overId;
    if (over == null) return null;
    if (_isColumn(over)) return over;
    final col = _columnOf(over);
    return col == null ? null : DndId(col);
  }

  @override
  Component build(BuildContext context) {
    return DndScope(
      controller: _controller,
      // The board's stacked rows: status bar, the horizontal column rail, the
      // drag overlay and the a11y live region. (How the rail is kept from
      // widening the page on mobile is explained on the wrapper below.)
      child: div(classes: 'space-y-6', [
        _statusBar(),
        // Keep the page width locked to the viewport on mobile by separating
        // the clip boundary from the actual horizontal scroller. Mobile
        // browsers can still let wide drag columns expand the page when the
        // scrollable element is also the direct parent of those columns.
        div(classes: 'max-w-full overflow-hidden', [
          // Columns stay side by side and scroll horizontally; the board
          // auto-scrolls horizontally while a card is dragged near an edge.
          DndAutoScroll(
            axis: DndScrollAxis.horizontal,
            controller: _controller,
            classes:
                'block w-full max-w-full overflow-x-auto overflow-y-hidden '
                'pb-2 [-webkit-overflow-scrolling:touch]',
            styles: Styles(raw: {'contain': 'layout paint'}),
            child: div(
              classes:
                  'inline-flex min-w-full items-start gap-4 pr-4 '
                  'sm:flex sm:pr-0',
              [for (final col in _kanbanColumns) _column(col)],
            ),
          ),
        ]),
        DndDragOverlay(
          controller: _controller,
          builder: (context, overlay) {
            final card = _cardData[overlay.activeId.value];
            if (card == null) return div(const []);
            return _cardFace(card, dragging: true);
          },
        ),
        const DndLiveRegion(),
      ]),
    );
  }

  Component _statusBar() {
    final counts = _kanbanColumns.map(
      (c) => '${c.title} ${_board[c.id]!.length}',
    );
    return div(
      classes: 'flex flex-wrap items-center gap-2 font-mono text-xs text-muted',
      [
        for (final c in counts)
          span(classes: 'rounded-full border border-line bg-raised px-3 py-1', [
            .text(c),
          ]),
        span(
          classes:
              'rounded-full border border-accent/40 bg-accent/10 '
              'px-3 py-1 text-accent',
          [.text('moves $_moves')],
        ),
      ],
    );
  }

  Component _column(({String id, String title}) col) {
    final isOver = _overColumn?.value == col.id;
    final cards = _board[col.id]!;
    // The outer div owns the column width (DndDroppable renders an unstyled
    // wrapper, so sizing lives here). On mobile each column is a fixed-width
    // flex item in the horizontal rail; on >= sm the columns become equal
    // flex children that share the available width.
    return div(
      classes:
          'w-[17rem] min-w-0 shrink-0 flex-none sm:w-auto sm:flex-1 sm:basis-0',
      [
        DndDroppable(
          id: DndId(col.id),
          child: div(
            classes:
                'flex w-full flex-col gap-3 rounded-2xl border bg-raised/60 p-3 '
                'transition-colors duration-200 '
                '${isOver ? 'border-accent bg-accent/10' : 'border-line'}',
            attributes: {'data-over': isOver.toString()},
            [
              div(
                classes:
                    'flex items-center justify-between px-1 font-mono text-xs '
                    'uppercase tracking-wider text-muted',
                [
                  span([.text(col.title)]),
                  span(classes: 'text-accent', [.text('${cards.length}')]),
                ],
              ),
              // Cards scroll vertically inside a bounded column; the column
              // auto-scrolls vertically while a card is dragged past its edge.
              DndAutoScroll(
                axis: DndScrollAxis.vertical,
                controller: _controller,
                classes:
                    'flex min-h-[120px] max-h-[55vh] flex-col gap-3 overflow-y-auto '
                    'pr-0.5',
                child: .fragment([
                  if (cards.isEmpty)
                    div(
                      classes:
                          'flex flex-1 items-center justify-center rounded-xl '
                          'border border-dashed border-line py-6 text-xs text-muted',
                      const [.text('drop here')],
                    ),
                  for (final id in cards) _card(id),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Component _card(DndId id) {
    final card = _cardData[id.value]!;
    final isActive = _controller.activeId == id;
    final isOver = _controller.overId == id;
    final stateClasses = isActive
        ? 'opacity-40'
        : isOver
        ? 'ring-2 ring-accent ring-offset-2 ring-offset-raised'
        : '';
    return DndDroppable(
      id: id,
      child: DndDraggable(
        id: id,
        constraint: const DndSensorActivationConstraint(distance: 8),
        label: 'Card ${card.title}',
        description:
            'Press space to pick up, arrow keys to move between cards, '
            'space to drop, escape to cancel.',
        onDragEnd: _handleDrop,
        child: div(
          classes: 'transition-[opacity,box-shadow] duration-150 $stateClasses',
          [_cardFace(card)],
        ),
      ),
    );
  }

  Component _cardFace(_Card card, {bool dragging = false}) {
    return div(
      classes:
          'flex items-start gap-2 rounded-xl border border-line bg-surface p-3 '
          '${dragging ? 'rotate-2 shadow-lift-accent' : 'shadow-sm'}',
      [
        Grip(label: 'Reorder ${card.title}'),
        div(classes: 'flex flex-1 flex-col gap-1', [
          span(classes: 'text-sm font-medium text-ink', [.text(card.title)]),
          span(
            classes:
                'inline-flex w-fit rounded-full bg-accent/10 px-2 py-0.5 '
                'font-mono text-[10px] uppercase tracking-wider text-accent',
            [.text(card.tag)],
          ),
        ]),
      ],
    );
  }
}

class _Card {
  const _Card(this.title, this.tag);
  final String title;
  final String tag;
}

const _kanbanColumns = <({String id, String title})>[
  (id: 'col-backlog', title: 'Backlog'),
  (id: 'col-progress', title: 'In progress'),
  (id: 'col-review', title: 'Review'),
  (id: 'col-done', title: 'Done'),
];

const _cardData = <String, _Card>{
  'card-axis': _Card('Axis-locked drag', 'modifier'),
  'card-grid': _Card('Snap to grid', 'modifier'),
  'card-rtl': _Card('RTL reordering', 'sortable'),
  'card-pointer': _Card('Pointer sensor', 'sensor'),
  'card-collision': _Card('Collision detection', 'core'),
  'card-modifiers': _Card('Restrict to axis', 'modifier'),
  'card-measure': _Card('Measuring registry', 'core'),
  'card-overlay': _Card('Drag overlay portal', 'overlay'),
  'card-keyboard': _Card('Keyboard sensor', 'a11y'),
  'card-scroll': _Card('Edge auto-scroll', 'scroll'),
  'card-engine': _Card('Shared engine', 'core'),
  'card-ssr': _Card('SSR hydration', 'jaspr'),
};
