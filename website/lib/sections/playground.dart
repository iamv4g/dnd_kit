import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../drag/drag_bus.dart';

/// A free-form sandbox: drag tokens from the pool into any bucket. Pure generic
/// droppables + collision, app-owned state — a quick "try it yourself".
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

  Map<String, List<DndId>> _zones = {
    'pool': List<DndId>.of(_allTokens),
    'bucket-a': [],
    'bucket-b': [],
    'bucket-c': [],
  };

  void _onChanged() {
    dragBus.report(_controller, source: 'playground');
    if (mounted) setState(() {});
  }

  void _handleEnd(DndDragEndEvent event) {
    final over = event.overId;
    if (over == null || !_zones.containsKey(over.value)) return;
    final active = event.activeId;
    setState(() {
      for (final list in _zones.values) {
        list.remove(active);
      }
      _zones[over.value]!.add(active);
    });
  }

  void _reset() {
    setState(() {
      _zones = {
        'pool': List<DndId>.of(_allTokens),
        'bucket-a': [],
        'bucket-b': [],
        'bucket-c': [],
      };
    });
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
                'rounded-full border border-line px-4 py-1.5 text-sm '
                'font-medium text-muted transition-colors hover:border-accent '
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
      ]),
    );
  }

  Component _pool() {
    final isOver = _controller.overId?.value == 'pool';
    return DndDroppable(
      id: const DndId('pool'),
      child: div(
        classes: 'drop-zone flex min-h-[64px] flex-wrap items-center gap-2 p-3',
        attributes: {'data-over': isOver.toString()},
        [
          span(
            classes:
                'w-full font-mono text-[10px] uppercase tracking-wider '
                'text-muted',
            const [.text('pool · drag into a bucket')],
          ),
          for (final id in _zones['pool']!) _token(id),
        ],
      ),
    );
  }

  Component _bucket(String id, String title) {
    final isOver = _controller.overId?.value == id;
    final tokens = _zones[id]!;
    return DndDroppable(
      id: DndId(id),
      child: div(
        classes: 'drop-zone flex min-h-[120px] flex-col gap-2 p-3',
        attributes: {'data-over': isOver.toString()},
        [
          div(
            classes:
                'flex items-center justify-between font-mono text-[10px] '
                'uppercase tracking-wider text-muted',
            [
              span([.text(title)]),
              span(classes: 'text-accent', [.text('${tokens.length}')]),
            ],
          ),
          div(classes: 'flex flex-wrap gap-2', [
            for (final id in tokens) _token(id),
          ]),
        ],
      ),
    );
  }

  Component _token(DndId id) {
    final isActive = _controller.activeId == id;
    return DndDraggable(
      id: id,
      constraint: const DndSensorActivationConstraint(distance: 4),
      label: 'Drag token ${id.value}',
      onDragEnd: _handleEnd,
      child: div(classes: isActive ? 'opacity-30' : '', [
        _tokenFace(id, false),
      ]),
    );
  }

  Component _tokenFace(DndId id, bool dragging) {
    final n = id.value.split('-').last;
    return span(
      classes:
          'inline-grid h-10 w-10 cursor-grab select-none place-items-center '
          'rounded-xl border bg-surface font-mono text-sm text-ink '
          'transition active:cursor-grabbing '
          '${dragging ? 'border-accent shadow-lift-accent rotate-6' : 'border-line hover:border-accent'}',
      [.text(n)],
    );
  }
}
