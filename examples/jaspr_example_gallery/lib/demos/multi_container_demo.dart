import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../ui.dart';

/// Multi-container sortable: the supported [SortableMultiScope] /
/// [SortableMultiContainerArea] / [SortableMultiItem] surface moves cards within
/// and across columns (Kanban shape). The library resolves move intent; the
/// demo owns the board state.
class MultiContainerDemo extends StatefulComponent {
  const MultiContainerDemo({super.key});

  @override
  State<MultiContainerDemo> createState() => _MultiContainerDemoState();
}

class _MultiContainerDemoState extends State<MultiContainerDemo> {
  // A plain controller: SortableMultiScope installs its multi-container
  // collision detector on it, so no manual wiring is needed.
  late final DndController _controller = DndController()
    ..addListener(_handleChanged);

  Map<String, List<DndId>> _board = _initialBoard();
  int _moves = 0;

  static Map<String, List<DndId>> _initialBoard() {
    return <String, List<DndId>>{
      'todo': [const DndId('card-brief'), const DndId('card-design')],
      'doing': [const DndId('card-engine'), const DndId('card-keyboard')],
      'done': [const DndId('card-ship')],
    };
  }

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

  List<SortableContainer> get _containers {
    return <SortableContainer>[
      for (final column in _columns)
        SortableContainer(
          id: DndId(column.id),
          itemIds: _board[column.id] ?? const <DndId>[],
        ),
    ];
  }

  void _handleMove(SortableMoveDetails move) {
    final next = _applyMove(_board, move);
    if (!identical(next, _board)) {
      setState(() {
        _board = next;
        _moves += 1;
      });
    }
  }

  static Map<String, List<DndId>> _applyMove(
    Map<String, List<DndId>> board,
    SortableMoveDetails move,
  ) {
    final fromId = move.fromContainerId?.value;
    final toId = move.toContainerId?.value;
    if (fromId == null || toId == null) {
      return board;
    }

    final next = <String, List<DndId>>{
      for (final entry in board.entries)
        entry.key: List<DndId>.from(entry.value),
    };
    final fromItems = next[fromId];
    final toItems = next[toId];
    if (fromItems == null ||
        toItems == null ||
        move.fromIndex < 0 ||
        move.fromIndex >= fromItems.length) {
      return board;
    }

    fromItems.removeAt(move.fromIndex);
    final insertIndex = move.toIndex.clamp(0, toItems.length);
    toItems.insert(insertIndex, move.activeId);
    return next;
  }

  @override
  Component build(BuildContext context) {
    return SortableMultiScope(
      controller: _controller,
      containers: _containers,
      // Open a live gap within and across columns while dragging; the card
      // builder animates the reported per-card offset.
      offsetResolver: SortableMultiOffsets.verticalLists,
      onMove: _handleMove,
      child: DemoPanel(
        children: [
          const DemoIntro(
            title: 'Multi-container sortable',
            description:
                'Drag a card within a column or across to another. The shared '
                'engine resolves cross-column move intent on the supported '
                'multi-container surface; the demo owns the board data.',
          ),
          StatusBar(
            children: [
              for (final column in _columns)
                Pill(
                  label: column.title,
                  value: '${_board[column.id]!.length}',
                ),
              Pill(label: 'Moves', value: '$_moves'),
            ],
          ),
          div(styles: Styles(display: .flex, gap: .all(16.px)), [
            for (final column in _columns) _column(column),
          ]),
          DndDragOverlay(
            controller: _controller,
            builder: (context, overlay) {
              final card = _cardData[overlay.activeId.value];
              return card == null
                  ? div(const [])
                  : _cardFace(card, dragging: true);
            },
          ),
          const DndLiveRegion(),
        ],
      ),
    );
  }

  Component _column(({String id, String title}) column) {
    final cards = _board[column.id]!;
    return div(styles: Styles(flex: Flex(grow: 1, shrink: 1, basis: .auto)), [
      SortableMultiContainerArea(
        id: DndId(column.id),
        itemIds: cards,
        builder: (context, dropState, child) {
          final isOver = dropState.isOver;
          return div(
            styles: Styles(
              display: .flex,
              padding: .all(12.px),
              border: .all(color: isOver ? cAccent : cBorder, width: 1.px),
              radius: .circular(18.px),
              minHeight: 200.px,
              flexDirection: .column,
              gap: .all(10.px),
              backgroundColor: isOver ? cAccentSoft : cPanelAlt,
            ),
            [child],
          );
        },
        child: .fragment([
          div(
            styles: Styles(
              display: .flex,
              justifyContent: .spaceBetween,
              fontSize: 13.px,
              fontWeight: .w600,
              color: cLabel,
            ),
            [
              span([.text(column.title)]),
              span(styles: Styles(color: cAccent), [.text('${cards.length}')]),
            ],
          ),
          if (cards.isEmpty)
            div(
              styles: Styles(
                padding: .symmetric(vertical: 18.px, horizontal: 12.px),
                border: .all(color: cBorderSoft, width: 1.px),
                radius: .circular(12.px),
                textAlign: .center,
                color: cMuted,
                fontSize: 12.px,
              ),
              const [.text('drop here')],
            ),
          for (final id in cards) _card(id),
        ]),
      ),
    ]);
  }

  Component _card(DndId id) {
    final card = _cardData[id.value]!;
    return SortableMultiItem(
      id: id,
      constraint: const DndSensorActivationConstraint(distance: 8),
      label: 'Card ${card.title}',
      description:
          'Press space to pick up, arrow keys to move between cards or columns, '
          'space to drop, escape to cancel.',
      builder: (context, sortableState, child) {
        final offset = sortableState.offset;
        // Hide the dragged card (its floating copy is in the overlay) and slide
        // the rest via the reported offset. Applied inside the builder, the
        // transform stays below the measured element.
        return div(
          styles: Styles(
            opacity: sortableState.isActive ? 0 : 1,
            transform: offset == DndPoint.zero
                ? Transform.none
                : Transform.translate(x: offset.x.px, y: offset.y.px),
            raw: const {'transition': 'transform 150ms ease'},
          ),
          [child],
        );
      },
      child: _cardFace(card),
    );
  }

  Component _cardFace(_Card card, {bool dragging = false}) {
    return div(
      styles: Styles(
        display: .flex,
        padding: .symmetric(vertical: 12.px, horizontal: 14.px),
        border: .all(color: cCardBorder, width: 1.px),
        radius: .circular(14.px),
        cursor: .grab,
        userSelect: .none,
        flexDirection: .column,
        gap: .all(6.px),
        backgroundColor: cCardBg,
        shadow: dragging
            ? BoxShadow(
                offsetX: 0.px,
                offsetY: 16.px,
                blur: 30.px,
                color: .rgba(154, 52, 18, 0.3),
              )
            : null,
      ),
      [
        span(styles: Styles(fontSize: 14.px, fontWeight: .w600), [
          .text(card.title),
        ]),
        Tag(label: card.tag),
      ],
    );
  }
}

class _Card {
  const _Card(this.title, this.tag);

  final String title;
  final String tag;
}

const _columns = <({String id, String title})>[
  (id: 'todo', title: 'To do'),
  (id: 'doing', title: 'Doing'),
  (id: 'done', title: 'Done'),
];

const _cardData = <String, _Card>{
  'card-brief': _Card('Write the brief', 'docs'),
  'card-design': _Card('Design the board', 'ui'),
  'card-engine': _Card('Wire the engine', 'core'),
  'card-keyboard': _Card('Keyboard support', 'a11y'),
  'card-ship': _Card('Ship the release', 'done'),
};
