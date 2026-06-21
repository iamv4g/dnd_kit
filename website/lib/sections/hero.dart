import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/ui.dart';
import '../data/site_data.dart';
import '../drag/drag_bus.dart';

/// The hero: a thesis headline plus a live "drag me" moment so the very first
/// thing a visitor can do is grab something.
class Hero extends StatelessComponent {
  const Hero({super.key});

  @override
  Component build(BuildContext context) {
    return header(classes: 'relative overflow-hidden', [
      // Soft ambient backdrop.
      div(
        classes:
            'pointer-events-none absolute -top-32 right-0 h-[420px] w-[420px] '
            'rounded-full bg-accent/20 blur-3xl',
        const [],
      ),
      div(
        classes:
            'mx-auto grid max-w-6xl items-center gap-12 px-6 py-20 '
            'lg:grid-cols-[1.1fr_0.9fr] lg:py-28',
        [
          div(classes: 'flex flex-col items-start gap-6', [
            eyebrow('Drag-and-drop · Flutter & Web'),
            h1(
              classes:
                  'font-serif text-5xl leading-[1.05] text-ink sm:text-6xl',
              [
                .text('Pick up the '),
                span(classes: 'text-accent', [.text('whole page')]),
                .text('.'),
              ],
            ),
            p(classes: 'max-w-xl text-lg leading-relaxed text-muted', const [
              .text(
                'dnd_kit is one drag engine for Flutter and the browser. '
                'This page is built with it — every handle, card and chip '
                'you can grab below runs on the same runtime.',
              ),
            ]),
            div(classes: 'flex flex-wrap items-center gap-3', [
              ctaPrimary('View on GitHub', SiteLinks.github, external: true),
              ctaGhost('Read the docs', SiteLinks.docs),
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

  final List<DndId> _tray = [
    const DndId('chip-sortable'),
    const DndId('chip-keyboard'),
    const DndId('chip-modifiers'),
    const DndId('chip-scroll'),
    const DndId('chip-overlay'),
  ];
  final List<DndId> _stack = [];

  void _onChanged() {
    dragBus.report(_controller, source: 'hero');
    if (mounted) setState(() {});
  }

  void _handleEnd(DndDragEndEvent event) {
    final over = event.overId;
    if (over == null) return;
    final active = event.activeId;
    if (over.value == 'zone-stack') {
      _tray.remove(active);
      if (!_stack.contains(active)) _stack.add(active);
    } else if (over.value == 'zone-tray') {
      _stack.remove(active);
      if (!_tray.contains(active)) _tray.add(active);
    } else {
      return;
    }
    setState(() {});
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
    return DndScope(
      controller: _controller,
      child: div(classes: 'card flex flex-col gap-4 p-5 shadow-lift', [
        div(classes: 'flex items-center justify-between', [
          span(
            classes: 'font-mono text-xs uppercase tracking-wider text-muted',
            const [.text('drag a capability →')],
          ),
          span(classes: 'font-mono text-xs text-accent', [
            .text('${_stack.length} in stack'),
          ]),
        ]),
        _zone('zone-tray', _tray, 'Capabilities'),
        _zone('zone-stack', _stack, 'Your stack', emptyHint: 'drop here'),
        DndDragOverlay(
          controller: _controller,
          builder: (context, overlay) => _chipFace(overlay.activeId, true),
        ),
      ]),
    );
  }

  Component _zone(
    String zoneId,
    List<DndId> chips,
    String title, {
    String? emptyHint,
  }) {
    final isOver = _controller.overId?.value == zoneId;
    return DndDroppable(
      id: DndId(zoneId),
      child: div(
        classes:
            'drop-zone flex min-h-[72px] flex-wrap content-start gap-2 p-3',
        attributes: {'data-over': isOver.toString()},
        [
          span(
            classes:
                'w-full font-mono text-[10px] uppercase tracking-wider '
                'text-muted',
            [.text(title)],
          ),
          if (chips.isEmpty && emptyHint != null)
            span(classes: 'text-xs text-muted', [.text(emptyHint)]),
          for (final id in chips) _chip(id),
        ],
      ),
    );
  }

  Component _chip(DndId id) {
    final isActive = _controller.activeId == id;
    return DndDraggable(
      id: id,
      constraint: const DndSensorActivationConstraint(distance: 4),
      label: 'Drag ${_chipLabels[id.value]}',
      onDragEnd: _handleEnd,
      child: div(classes: isActive ? 'opacity-30' : '', [_chipFace(id, false)]),
    );
  }

  Component _chipFace(DndId id, bool dragging) {
    return span(
      classes:
          'inline-flex cursor-grab select-none items-center gap-1.5 rounded-full '
          'border bg-surface px-3 py-1.5 text-sm font-medium text-ink '
          'transition active:cursor-grabbing '
          '${dragging ? 'border-accent shadow-lift-accent rotate-2' : 'border-line hover:border-accent'}',
      [
        span(classes: 'text-accent', const [.text('⠿')]),
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
