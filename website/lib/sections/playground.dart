import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../drag/drag_bus.dart';
import '../drag/sortable_offsets.dart';

/// A sandbox on the multi-container sortable surface: drag tokens from the pool
/// into any bucket. The zones open a gap where the token will land; the app
/// owns the state.
@client
class Playground extends StatefulComponent {
  const Playground({super.key});

  @override
  State<Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> {
  late final DndController _controller = DndController()
    ..addListener(_onChanged);

  static const _allTokens = <DndId>[
    DndId('t-1'),
    DndId('t-2'),
    DndId('t-3'),
    DndId('t-4'),
    DndId('t-5'),
    DndId('t-6'),
  ];

  Map<String, List<DndId>> _zones = _initialZones();

  static Map<String, List<DndId>> _initialZones() {
    return {
      'pool': List<DndId>.of(_allTokens),
      'bucket-a': [],
      'bucket-b': [],
      'bucket-c': [],
    };
  }

  void _onChanged() {
    dragBus.report(_controller, source: 'playground');
    if (mounted) setState(() {});
  }

  void _handleMove(SortableMoveDetails move) {
    final fromId = move.fromContainerId?.value;
    final toId = move.toContainerId?.value;
    if (fromId == null || toId == null) return;

    final next = <String, List<DndId>>{
      for (final entry in _zones.entries)
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
    setState(() => _zones = next);
  }

  void _reset() {
    setState(() => _zones = _initialZones());
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
        for (final entry in _zones.entries)
          SortableContainer(id: DndId(entry.key), itemIds: entry.value),
      ],
      // Every token is the same box in a wrapped row, so a displaced token
      // moves exactly one slot along the flow, wrapping included.
      offsetResolver: flowOffsets,
      onMove: _handleMove,
      child: div(classes: 'flex flex-col gap-5', [
        _pool(),
        div(classes: 'grid grid-cols-1 gap-4 sm:grid-cols-3', [
          _bucket('bucket-a', 'Bucket A'),
          _bucket('bucket-b', 'Bucket B'),
          _bucket('bucket-c', 'Bucket C'),
        ]),
        div(classes: 'flex justify-end', [
          button(
            classes:
                'rounded-full bg-surface px-5 py-2 text-sm font-semibold '
                'text-muted shadow-lift transition-colors duration-200 '
                'hover:text-accent',
            attributes: const {'type': 'button'},
            onClick: _reset,
            const [.text('Reset')],
          ),
        ]),
        DndDragOverlay(
          controller: _controller,
          builder: (context, overlay) => _tokenFace(overlay.activeId, true),
        ),
        const DndLiveRegion(),
      ]),
    );
  }

  Component _pool() {
    final tokens = _zones['pool']!;
    return SortableMultiContainerArea(
      id: const DndId('pool'),
      itemIds: tokens,
      builder: (context, dropState, child) => div(
        classes:
            'drop-zone flex min-h-[92px] flex-wrap content-start gap-2 p-3',
        attributes: {'data-over': dropState.isOver.toString()},
        [child],
      ),
      child: .fragment([
        span(
          classes:
              'w-full font-mono text-[10px] uppercase tracking-wider '
              'text-muted',
          const [.text('pool · drag into a bucket')],
        ),
        for (final id in tokens) _token(id),
      ]),
    );
  }

  Component _bucket(String id, String title) {
    final tokens = _zones[id]!;
    return SortableMultiContainerArea(
      id: DndId(id),
      itemIds: tokens,
      // Fixed height, so opening a gap never resizes the row of buckets.
      builder: (context, dropState, child) => div(
        classes: 'drop-zone flex h-[9.5rem] flex-col gap-2 p-3',
        attributes: {'data-over': dropState.isOver.toString()},
        [child],
      ),
      child: .fragment([
        div(
          classes:
              'flex items-center justify-between font-mono text-[10px] '
              'uppercase tracking-wider text-muted',
          [
            span([.text(title)]),
            span(classes: 'text-accent', [.text('${tokens.length}')]),
          ],
        ),
        // `min-h-0` lets this flex child shrink below its content, which is
        // what makes the overflow scroll inside the fixed bucket.
        div(
          classes:
              'flex min-h-0 flex-1 flex-wrap content-start gap-2 overflow-y-auto',
          [for (final id in tokens) _token(id)],
        ),
      ]),
    );
  }

  Component _token(DndId id) {
    return SortableMultiItem(
      id: id,
      constraint: const DndSensorActivationConstraint(distance: 4),
      label: 'Drag token ${id.value}',
      description:
          'Press space to pick up, arrow keys to move between tokens and zones, '
          'space to drop, escape to cancel.',
      builder: (context, itemState, child) =>
          div(styles: slotStyles(itemState), [child]),
      child: _tokenFace(id, false),
    );
  }

  Component _tokenFace(DndId id, bool dragging) {
    final n = id.value.split('-').last;
    return span(
      classes:
          'inline-grid h-10 w-10 cursor-grab select-none place-items-center '
          'rounded-2xl squircle bg-surface font-mono text-sm font-bold text-ink '
          'active:cursor-grabbing '
          '${dragging ? 'rotate-6 shadow-lift-hi' : 'shadow-lift'}',
      [.text(n)],
    );
  }
}
