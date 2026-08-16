import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/ui.dart';
import '../data/site_data.dart';
import '../drag/drag_bus.dart';
import '../drag/sortable_offsets.dart';
import 'install_pill.dart';

/// The hero: a thesis headline plus a live "drag me" moment so the very first
/// thing a visitor can do is grab something.
class Hero extends StatelessComponent {
  const Hero({super.key});

  @override
  Component build(BuildContext context) {
    return header(classes: 'relative overflow-hidden', [
      div(
        classes:
            'sweep pointer-events-none absolute -left-[12%] -right-[12%] '
            '-top-[30%] h-[132%]',
        const [],
      ),
      div(
        classes:
            'hero-close pointer-events-none absolute -left-[6%] -right-[6%] '
            'bottom-0 h-[120px]',
        const [],
      ),
      div(
        classes:
            // pt clears the overlaid nav capsule (see NavBar's negative margin).
            'relative mx-auto grid max-w-6xl items-center gap-12 px-6 pb-32 '
            'pt-36 lg:grid-cols-[1.1fr_0.9fr] lg:pb-40 lg:pt-44',
        [
          div(classes: 'flex flex-col items-start gap-6', [
            eyebrow('Stable 0.4.0 · one engine, two adapters'),
            h1(
              classes:
                  'max-w-[15ch] font-display text-5xl font-extrabold '
                  'leading-[1.02] tracking-[-0.045em] text-ink sm:text-6xl',
              [
                .text('Drag is a '),
                span(classes: 'ink-sweep', [.text('continuous')]),
                .text(' thing. So is this engine.'),
              ],
            ),
            p(classes: 'max-w-xl text-lg leading-relaxed text-muted', [
              .text(
                'dnd_kit keeps the whole gesture in one pure-Dart runtime '
                '— activation, geometry, collision, modifiers, sortable math '
                '— and lets ',
              ),
              strong(classes: 'font-semibold text-ink', const [
                .text('Flutter'),
              ]),
              .text(' and '),
              strong(classes: 'font-semibold text-ink', const [.text('Jaspr')]),
              const .text(' render it. Same curve, same answer, both sides.'),
            ]),
            div(classes: 'flex flex-col items-start gap-4', [
              div(classes: 'flex flex-wrap items-center gap-3', [
                ctaPrimary('View the source', SiteLinks.github, external: true),
                ctaGhost('Read the docs', SiteLinks.docs),
              ]),
              const InstallPill(),
            ]),
          ]),
          // The entrance animation lives on this static wrapper, not inside
          // the @client island — hydration re-mounts the island subtree, so a
          // mount animation placed there would replay and flicker.
          div(classes: 'animate-fade-in', const [HeroStack()]),
        ],
      ),
    ]);
  }
}

/// Drag capability chips between the tray and "your stack" drop zone.
@client
class HeroStack extends StatefulComponent {
  const HeroStack({super.key});

  @override
  State<HeroStack> createState() => _HeroStackState();
}

class _HeroStackState extends State<HeroStack> {
  late final DndController _controller = DndController()
    ..addListener(_onChanged);

  Map<String, List<DndId>> _board = {
    'zone-tray': [
      const DndId('chip-sortable'),
      const DndId('chip-keyboard'),
      const DndId('chip-modifiers'),
      const DndId('chip-scroll'),
      const DndId('chip-overlay'),
    ],
    'zone-stack': [],
  };

  void _onChanged() {
    dragBus.report(_controller, source: 'hero');
    if (mounted) setState(() {});
  }

  void _handleMove(SortableMoveDetails move) {
    final fromId = move.fromContainerId?.value;
    final toId = move.toContainerId?.value;
    if (fromId == null || toId == null) return;

    final next = <String, List<DndId>>{
      for (final entry in _board.entries)
        entry.key: List<DndId>.of(entry.value),
    };
    final from = next[fromId];
    final to = next[toId];
    if (from == null ||
        to == null ||
        move.fromIndex < 0 ||
        move.fromIndex >= from.length) {
      return;
    }

    from.removeAt(move.fromIndex);
    to.insert(move.toIndex.clamp(0, to.length), move.activeId);
    setState(() => _board = next);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return SortableMultiScope(
      controller: _controller,
      containers: [
        for (final entry in _board.entries)
          SortableContainer(id: DndId(entry.key), itemIds: entry.value),
      ],
      offsetResolver: flowOffsets,
      onMove: _handleMove,
      child: div(classes: 'card-lg flex flex-col gap-4 p-6', [
        div(classes: 'flex items-center justify-between', [
          span(
            classes: 'font-mono text-xs uppercase tracking-wider text-faint',
            const [.text('drag a capability \u2192')],
          ),
          span(
            classes:
                'rounded-full bg-accent/10 px-3 py-1 font-mono text-xs '
                'text-accent-deep dark:text-accent',
            [.text('${_board['zone-stack']!.length} in stack')],
          ),
        ]),
        _zone('zone-tray', 'Capabilities'),
        _zone('zone-stack', 'Your stack', emptyHint: 'drop here'),
        DndDragOverlay(
          controller: _controller,
          builder: (context, overlay) => _chipFace(overlay.activeId, true),
        ),
        const DndLiveRegion(),
      ]),
    );
  }

  Component _zone(String zoneId, String title, {String? emptyHint}) {
    final chips = _board[zoneId]!;
    return SortableMultiContainerArea(
      id: DndId(zoneId),
      itemIds: chips,
      // Sized for every chip in one zone, so the card never resizes and a
      // chip displaced on to a new line stays inside its zone.
      builder: (context, dropState, child) => div(
        classes: 'drop-zone flex h-[11.5rem] flex-wrap content-start gap-2 p-4',
        attributes: {'data-over': dropState.isOver.toString()},
        [child],
      ),
      child: .fragment([
        span(
          classes:
              'w-full font-mono text-[10px] uppercase tracking-wider '
              'text-faint',
          [.text(title)],
        ),
        if (chips.isEmpty && emptyHint != null)
          span(classes: 'text-xs text-faint', [.text(emptyHint)]),
        for (final id in chips) _chip(id),
      ]),
    );
  }

  Component _chip(DndId id) {
    return SortableMultiItem(
      id: id,
      constraint: const DndSensorActivationConstraint(distance: 4),
      label: 'Drag ${_chipLabels[id.value]}',
      description:
          'Press space to pick up, arrow keys to move between chips and zones, '
          'space to drop, escape to cancel.',
      builder: (context, itemState, child) =>
          div(styles: slotStyles(itemState), [child]),
      child: _chipFace(id, false),
    );
  }

  Component _chipFace(DndId id, bool dragging) {
    // One width for every chip, so a displaced chip lands exactly on its
    // neighbour's slot however the row wraps.
    return span(
      classes:
          'inline-flex w-[8.5rem] cursor-grab select-none items-center gap-2 '
          'rounded-full bg-surface px-4 py-2 text-sm font-semibold text-ink '
          'active:cursor-grabbing '
          '${dragging ? 'rotate-2 shadow-lift-hi' : 'shadow-lift'}',
      [
        span(
          classes:
              'h-2 w-2 shrink-0 rounded-full bg-gradient-to-br '
              'from-accent-deep to-sky',
          const [],
        ),
        .text(_chipLabels[id.value] ?? id.value),
      ],
    );
  }
}

const _chipLabels = <String, String>{
  'chip-sortable': 'Sortable',
  'chip-keyboard': 'Keyboard',
  'chip-modifiers': 'Modifiers',
  'chip-scroll': 'Auto-scroll',
  'chip-overlay': 'Overlay',
};
