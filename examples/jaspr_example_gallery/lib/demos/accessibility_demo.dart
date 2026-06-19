import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../ui.dart';

/// Keyboard + accessibility: keyboard dragging, `aria` metadata, a
/// [DndLiveRegion], and custom [DndAnnouncements] mirrored on screen.
class AccessibilityDemo extends StatefulComponent {
  const AccessibilityDemo({super.key});

  @override
  State<AccessibilityDemo> createState() => _AccessibilityDemoState();
}

class _AccessibilityDemoState extends State<AccessibilityDemo> {
  late final DndController _controller = DndController()
    ..addListener(_handleControllerChanged);

  late final DndAnnouncements _announcements = DndAnnouncements(
    onDragStart: (active) => 'Picked up ${_label(active)}.',
    onDragOver: (active, over) => over == null
        ? '${_label(active)} is between columns.'
        : '${_label(active)} is over ${_label(over)}.',
    onDragEnd: (active, over) => over == null
        ? '${_label(active)} was dropped in place.'
        : '${_label(active)} was moved to ${_label(over)}.',
    onDragCancel: (active) => 'Move of ${_label(active)} was cancelled.',
  );

  // App-owned card placement: card id -> column id.
  final Map<DndId, DndId> _placement = <DndId, DndId>{
    const DndId('card-spec'): const DndId('col-todo'),
    const DndId('card-review'): const DndId('col-doing'),
    const DndId('card-release'): const DndId('col-todo'),
  };

  final List<String> _log = <String>[];

  // Mirror of DndLiveRegion transition tracking, so the visible panel shows
  // exactly what the live region announces.
  String? _lastStateLabel;
  DndId? _lastOverId;
  DndId? _activeId;

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    _syncAnnouncementMirror();
    setState(() {});
  }

  void _syncAnnouncementMirror() {
    final state = _controller.state;
    final label = state.runtimeType.toString();
    String? message;

    if (state is DndDragging) {
      _activeId = state.session.activeId;
      if (_lastStateLabel != 'DndDragging') {
        message = _announcements.onDragStart(state.session.activeId);
        _lastOverId = _controller.overId;
      } else if (_controller.overId != _lastOverId) {
        message = _announcements.onDragOver(
          state.session.activeId,
          _controller.overId,
        );
        _lastOverId = _controller.overId;
      }
    } else if (state is DndDropping && _lastStateLabel != 'DndDropping') {
      final active = _controller.activeId ?? _activeId;
      if (active != null) {
        message = _announcements.onDragEnd(active, _controller.overId);
      }
    } else if (state is DndCancelled && _lastStateLabel != 'DndCancelled') {
      final active = _controller.activeId ?? _activeId;
      if (active != null) {
        message = _announcements.onDragCancel(active);
      }
    } else if (state is DndIdle) {
      _activeId = null;
      _lastOverId = null;
    }

    _lastStateLabel = label;
    if (message != null && (_log.isEmpty || _log.last != message)) {
      _log.add(message);
    }
  }

  void _handleDragEnd(DndDragEndEvent event) {
    final overId = event.overId;
    if (overId != null && _columns.any((column) => column.id == overId)) {
      setState(() => _placement[event.activeId] = overId);
    }
  }

  String _label(DndId id) {
    final card = _cards.where((card) => card.id == id);
    if (card.isNotEmpty) {
      return card.first.title;
    }
    final column = _columns.where((column) => column.id == id);
    if (column.isNotEmpty) {
      return '${column.first.title} column';
    }
    return id.value;
  }

  @override
  Component build(BuildContext context) {
    return DndScope(
      controller: _controller,
      announcements: _announcements,
      child: DemoPanel(
        children: [
          const DemoIntro(
            title: 'Keyboard and accessibility',
            description:
                'Every draggable is a focusable button with an aria-label and '
                'keyboard instructions. Tab to a card, press space or enter to '
                'pick it up, arrow keys to move it over a column, space to drop, '
                'and escape to cancel. A visually-hidden DndLiveRegion announces '
                'each step; the panel below mirrors exactly what it says.',
          ),
          div(
            styles: Styles(
              display: .flex,
              flexWrap: .wrap,
              alignItems: .stretch,
              gap: .all(20.px),
            ),
            [
              for (final column in _columns)
                _Column(
                  column: column,
                  cards: _cards
                      .where((card) => _placement[card.id] == column.id)
                      .toList(),
                  onDragEnd: _handleDragEnd,
                ),
            ],
          ),
          _AnnouncementLog(messages: _log),
          DndDragOverlay(
            builder: (context, overlayDetails) {
              final card = _cards.firstWhere(
                (card) => card.id == overlayDetails.activeId,
              );
              return _CardChrome(card: card, dragging: true);
            },
          ),
          const DndLiveRegion(),
        ],
      ),
    );
  }
}

class _Column extends StatelessComponent {
  const _Column({
    required this.column,
    required this.cards,
    required this.onDragEnd,
  });

  final _ColumnModel column;
  final List<_CardModel> cards;
  final void Function(DndDragEndEvent event) onDragEnd;

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(
        minWidth: 240.px,
        flex: Flex(grow: 1, shrink: 1, basis: 240.px),
      ),
      [
        DndDroppable(
          id: column.id,
          builder: (context, dragState, child) {
            final over = dragState.isOver;
            return section(
              styles: Styles(
                display: .flex,
                minHeight: 220.px,
                padding: .all(18.px),
                border: .all(
                  color: over ? cAccentBright : cBorder,
                  width: over ? 2.px : 1.px,
                ),
                radius: .circular(24.px),
                flexDirection: .column,
                gap: .all(14.px),
                backgroundColor: over ? cAccentSoft : cPanelAlt,
              ),
              [
                div(
                  styles: Styles(
                    display: .flex,
                    justifyContent: .spaceBetween,
                    alignItems: .center,
                    gap: .all(12.px),
                  ),
                  [
                    strong(
                      styles: Styles(fontSize: 18.px),
                      [.text(column.title)],
                    ),
                    Tag(
                      label: over ? 'Drop here' : '${cards.length}',
                      active: over,
                    ),
                  ],
                ),
                child,
              ],
            );
          },
          child: div(
            styles: Styles(
              display: .flex,
              flexDirection: .column,
              gap: .all(10.px),
            ),
            [
              if (cards.isEmpty)
                span(
                  styles: Styles(
                    color: cEmptyText,
                    fontSize: 14.px,
                    lineHeight: 1.5.em,
                  ),
                  const [.text('No cards in this column.')],
                )
              else
                for (final card in cards)
                  DndDraggable(
                    id: card.id,
                    label: '${card.title}, in ${column.title}',
                    description:
                        'Press space or enter to pick up, arrow keys to move '
                        'over a column, space to drop, escape to cancel.',
                    onDragEnd: onDragEnd,
                    child: _CardChrome(card: card),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardChrome extends StatelessComponent {
  const _CardChrome({required this.card, this.dragging = false});

  final _CardModel card;
  final bool dragging;

  @override
  Component build(BuildContext context) {
    return article(
      styles: Styles(
        display: .flex,
        padding: .symmetric(vertical: 14.px, horizontal: 16.px),
        border: .all(color: cCardBorder, width: 1.px),
        radius: .circular(16.px),
        shadow: dragging
            ? BoxShadow(
                offsetX: 0.px,
                offsetY: 16.px,
                blur: 30.px,
                color: .rgba(154, 52, 18, 0.24),
              )
            : .none,
        cursor: dragging ? .grabbing : .grab,
        flexDirection: .column,
        gap: .all(6.px),
        backgroundColor: cCardBg,
      ),
      [
        strong(
          styles: Styles(fontSize: 15.px),
          [.text(card.title)],
        ),
        span(
          styles: Styles(fontSize: 13.px, color: cMuted),
          [.text(card.note)],
        ),
      ],
    );
  }
}

class _AnnouncementLog extends StatelessComponent {
  const _AnnouncementLog({required this.messages});

  final List<String> messages;

  @override
  Component build(BuildContext context) {
    final recent =
        messages.length > 6 ? messages.sublist(messages.length - 6) : messages;
    return div(
      styles: Styles(
        display: .flex,
        padding: .symmetric(vertical: 16.px, horizontal: 18.px),
        border: .all(style: .dashed, color: cBorder, width: 1.px),
        radius: .circular(18.px),
        flexDirection: .column,
        gap: .all(8.px),
        backgroundColor: cPillBg,
      ),
      [
        span(
          styles: Styles(
            fontSize: 12.px,
            textTransform: .upperCase,
            letterSpacing: 1.1.px,
            color: cLabel,
          ),
          const [.text('What screen readers hear')],
        ),
        if (recent.isEmpty)
          span(
            styles: Styles(fontSize: 14.px, color: cMuted),
            const [.text('Start a drag to hear announcements.')],
          )
        else
          for (final message in recent)
            span(
              styles: Styles(fontSize: 14.px, color: cText, lineHeight: 1.5.em),
              [.text('• $message')],
            ),
      ],
    );
  }
}

class _ColumnModel {
  const _ColumnModel({required this.id, required this.title});

  final DndId id;
  final String title;
}

class _CardModel {
  const _CardModel({required this.id, required this.title, required this.note});

  final DndId id;
  final String title;
  final String note;
}

const _columns = <_ColumnModel>[
  _ColumnModel(id: DndId('col-todo'), title: 'To do'),
  _ColumnModel(id: DndId('col-doing'), title: 'In progress'),
  _ColumnModel(id: DndId('col-done'), title: 'Done'),
];

const _cards = <_CardModel>[
  _CardModel(
    id: DndId('card-spec'),
    title: 'Write the spec',
    note: 'Outline the adapter surface.',
  ),
  _CardModel(
    id: DndId('card-review'),
    title: 'Review the API',
    note: 'Check parity with Flutter.',
  ),
  _CardModel(
    id: DndId('card-release'),
    title: 'Cut the release',
    note: 'Tag and publish the dev line.',
  ),
];
