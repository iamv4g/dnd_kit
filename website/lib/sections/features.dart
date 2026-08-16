import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/site_data.dart';
import '../drag/drag_bus.dart';
import '../drag/grip.dart';
import '../drag/sortable_offsets.dart';

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
      // dropOnOver lands the move where the gap is; the geometric strategies
      // resolve from the dragged rect center and can disagree with it.
      strategy: SortableStrategies.dropOnOver,
      offsetResolver: gridOffsets,
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
                return div(classes: 'h-full', styles: slotStyles(itemState), [
                  child,
                ]);
              },
              child: _featureCard(_featureFor(id)),
            ),
        ]),
        DndDragOverlay(
          controller: _controller,
          builder: (context, overlay) => div(classes: 'rotate-2', [
            _featureCard(_featureFor(overlay.activeId), lifted: true),
          ]),
        ),
      ]),
    );
  }

  Component _featureCard(Feature feature, {bool lifted = false}) {
    const orbs = <String>[
      'from-accent-deep to-accent',
      'from-accent to-sky',
      'from-sky to-mint',
      'from-mint to-apricot',
      'from-apricot to-accent',
      'from-accent to-accent-deep',
    ];
    final orb = orbs[features.indexOf(feature) % orbs.length];
    return div(
      classes:
          'card card-hover group flex h-full flex-col gap-4 p-6 '
          '${lifted ? 'shadow-lift-hi' : ''}',
      [
        div(classes: 'flex items-center justify-between', [
          span(
            classes:
                'inline-grid h-11 w-11 place-items-center rounded-2xl '
                'squircle bg-gradient-to-br $orb text-lg text-white',
            [.text(feature.glyph)],
          ),
          Grip(label: 'Reorder ${feature.title}'),
        ]),
        h3(
          classes: 'font-display text-xl font-bold tracking-[-0.02em] text-ink',
          [.text(feature.title)],
        ),
        p(classes: 'text-sm leading-relaxed text-muted', [.text(feature.body)]),
      ],
    );
  }
}
