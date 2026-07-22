import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

/// The `sortable` catalog demo: SortableScope + SortableItem turn a list into a
/// reorderable one. dnd_kit reports from/to indices; the list owns its order.
///
/// The live-gap toggle shows the offset plug-in: with a resolver configured,
/// each item builder receives an `offset` and this demo animates it, so a gap
/// opens where the row will land. dnd_kit computes the geometry and never
/// animates — the `AnimatedSlide` below is the demo's own choice.
class SortableDemo extends StatefulWidget {
  const SortableDemo({super.key});

  @override
  State<SortableDemo> createState() => _SortableDemoState();
}

class _SortableDemoState extends State<SortableDemo> {
  final List<_Track> _tracks = <_Track>[
    const _Track('track-1', 'Write the launch brief'),
    const _Track('track-2', 'Design the board UI'),
    const _Track('track-3', 'Wire the drag engine'),
    const _Track('track-4', 'Add keyboard support'),
    const _Track('track-5', 'Ship the release'),
  ];

  static const double _rowExtent = 62;

  bool _liveGap = true;

  void _handleMove(SortableMoveDetails details) {
    setState(() {
      final track = _tracks.removeAt(details.fromIndex);
      _tracks.insert(details.toIndex, track);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sortable list')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Drag a row to reorder it, or focus one and use the keyboard. '
              'dnd_kit reports the move as from/to indices; the list owns its '
              'order.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _liveGap,
              onChanged: (value) => setState(() => _liveGap = value),
              title: const Text('Open a gap while dragging'),
              subtitle: const Text(
                'Uses SortableOffsets.verticalList and drops where the '
                'highlight is.',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SortableScope(
                // dropOnOver keeps the committed move in step with the gap the
                // offsets open; the geometric strategies resolve from the
                // dragged rect center instead and would disagree with it.
                strategy: _liveGap
                    ? SortableStrategies.dropOnOver
                    : SortableStrategies.verticalList,
                offsetResolver: _liveGap
                    ? SortableOffsets.verticalList
                    : SortableOffsets.none,
                itemIds: <DndId>[for (final track in _tracks) DndId(track.id)],
                onMove: _handleMove,
                child: ListView(
                  children: <Widget>[
                    for (final track in _tracks)
                      Padding(
                        key: ValueKey<String>(track.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SortableItem(
                          id: DndId(track.id),
                          builder: (context, details, child) {
                            // Applied inside the builder so the shift stays
                            // below the measured box and cannot feed back into
                            // collision detection.
                            return AnimatedSlide(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              offset: Offset(0, details.offset.y / _rowExtent),
                              child: Opacity(
                                opacity: details.isDragging ? 0.4 : 1,
                                child: child,
                              ),
                            );
                          },
                          child: _TrackRow(label: track.label),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Track {
  const _Track(this.id, this.label);

  final String id;
  final String label;
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.drag_indicator, color: colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
