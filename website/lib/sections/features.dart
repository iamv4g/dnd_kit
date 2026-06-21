import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/site_data.dart';
import '../drag/drag_bus.dart';
import '../drag/grip.dart';

/// The feature grid — itself reorderable. The marketing cards are wired through
/// the single-container [SortableScope] preset, so the page proves the sortable
/// API on its own content.
@client
class Features extends StatefulComponent {
  const Features({super.key});

  @override
  State<Features> createState() => _FeaturesState();
}

class _FeaturesState extends State<Features> {
  late final DndController _controller = DndController()
    ..addListener(_onChanged);

  late List<DndId> _order = [
    for (var i = 0; i < features.length; i++) DndId('feat-$i'),
  ];

  Feature _featureFor(DndId id) =>
      features[int.parse(id.value.split('-').last)];

  void _onChanged() {
    dragBus.report(_controller, source: 'features');
    if (mounted) setState(() {});
  }

  void _onMove(SortableMoveDetails details) {
    setState(() {
      final next = List<DndId>.of(_order);
      next.insert(details.toIndex, next.removeAt(details.fromIndex));
      _order = next;
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
    return SortableScope(
      controller: _controller,
      strategy: SortableStrategies.grid,
      itemIds: _order,
      onMove: _onMove,
      child: div([
        div(classes: 'grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3', [
          for (final id in _order)
            SortableItem(
              id: id,
              constraint: const DndSensorActivationConstraint(distance: 8),
              label: 'Reorder ${_featureFor(id).title}',
              builder: (context, itemState, child) {
                final lifted = itemState.isActive || itemState.isDragging;
                final over = itemState.isOver;
                return div(
                  classes:
                      'h-full transition-[opacity,transform] duration-150 '
                      '${lifted ? 'opacity-40' : ''} '
                      '${over ? 'scale-[1.02]' : ''}',
                  [child],
                );
              },
              child: _featureCard(_featureFor(id)),
            ),
        ]),
        DndDragOverlay(
          controller: _controller,
          builder: (context, overlay) => div(
            classes: 'rotate-2 shadow-lift-accent',
            [_featureCard(_featureFor(overlay.activeId))],
          ),
        ),
      ]),
    );
  }

  Component _featureCard(Feature feature) {
    return div(
      classes:
          'group flex h-full flex-col gap-3 rounded-2xl border border-line '
          'bg-surface p-5 transition-colors hover:border-accent/50',
      [
        div(classes: 'flex items-center justify-between', [
          span(
            classes:
                'inline-grid h-10 w-10 place-items-center rounded-xl '
                'bg-accent/10 text-lg text-accent',
            [.text(feature.glyph)],
          ),
          Grip(label: 'Reorder ${feature.title}'),
        ]),
        h3(classes: 'font-serif text-xl text-ink', [.text(feature.title)]),
        p(classes: 'text-sm leading-relaxed text-muted', [.text(feature.body)]),
      ],
    );
  }
}
