import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../ui.dart';

/// Sortable preset: [SortableScope] + [SortableItem] reorder a vertical list
/// through the shared engine strategy, with keyboard support and a live region.
class SortableDemo extends StatefulComponent {
  const SortableDemo({super.key});

  @override
  State<SortableDemo> createState() => _SortableDemoState();
}

class _SortableDemoState extends State<SortableDemo> {
  late final DndController _controller = DndController()
    ..addListener(_handleControllerChanged);

  List<_Track> _tracks = List<_Track>.of(_initialTracks);
  int _moveCount = 0;

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMove(SortableMoveDetails details) {
    setState(() {
      final tracks = List<_Track>.of(_tracks);
      final moved = tracks.removeAt(details.fromIndex);
      tracks.insert(details.toIndex, moved);
      _tracks = tracks;
      _moveCount += 1;
    });
  }

  _Track _trackFor(DndId id) => _tracks.firstWhere((track) => track.id == id);

  @override
  Component build(BuildContext context) {
    final activeId = _controller.activeId;

    return SortableScope(
      controller: _controller,
      strategy: SortableStrategies.verticalList,
      itemIds: _tracks.map((track) => track.id),
      onMove: _handleMove,
      child: DemoPanel(
        children: [
          const DemoIntro(
            title: 'Sortable list',
            description:
                'Drag a row by its handle to reorder the playlist. Reorder intent '
                'comes from the shared engine strategy, so the same math drives '
                'Flutter and Jaspr. Keyboard works too: focus a handle, press '
                'space to pick up, arrow up/down to move, space to drop.',
          ),
          StatusBar(
            children: [
              Pill(
                label: 'Order',
                value: _tracks.map((track) => track.position).join(' · '),
              ),
              Pill(label: 'Moves', value: '$_moveCount'),
              Pill(
                label: 'State',
                value: _controller.state.runtimeType.toString(),
              ),
              Pill(label: 'Active', value: activeId?.value ?? 'none'),
            ],
          ),
          div(
            styles: Styles(
              display: .flex,
              flexDirection: .column,
              gap: .all(12.px),
            ),
            [
              for (final track in _tracks)
                SortableItem(
                  id: track.id,
                  label: '${track.title} by ${track.artist}',
                  description:
                      'Press space to pick up, arrow up or down to move, space '
                      'to drop, escape to cancel.',
                  builder: (context, itemState, child) {
                    return _trackRow(track, itemState, child);
                  },
                  child: _TrackContent(track: track),
                ),
            ],
          ),
          DndDragOverlay(
            builder: (context, overlayDetails) {
              final track = _trackFor(overlayDetails.activeId);
              return div(
                styles: Styles(
                  display: .flex,
                  padding: .symmetric(vertical: 14.px, horizontal: 18.px),
                  border: .all(color: cAccentBright, width: 2.px),
                  radius: .circular(18.px),
                  shadow: BoxShadow(
                    offsetX: 0.px,
                    offsetY: 18.px,
                    blur: 36.px,
                    color: .rgba(154, 52, 18, 0.22),
                  ),
                  alignItems: .center,
                  gap: .all(14.px),
                  backgroundColor: cCardBg,
                ),
                [_TrackContent(track: track, dragging: true)],
              );
            },
          ),
          const DndLiveRegion(),
        ],
      ),
    );
  }

  Component _trackRow(
    _Track track,
    SortableItemDetails itemState,
    Component child,
  ) {
    final isActive = itemState.isActive || itemState.isDragging;
    final over = itemState.isOver;
    final background = isActive
        ? cActiveRow
        : over
            ? cAccentSoft
            : cCardBg;
    return div(
      styles: Styles(
        border: .all(
          color: over ? cAccentBright : cBorder,
          width: over ? 2.px : 1.px,
        ),
        radius: .circular(18.px),
        opacity: isActive ? 0.55 : 1,
        backgroundColor: background,
        raw: const {'transition': 'background 120ms ease'},
      ),
      attributes: <String, String>{
        'data-track-id': track.id.value,
        'data-is-over': over.toString(),
      },
      [child],
    );
  }
}

class _TrackContent extends StatelessComponent {
  const _TrackContent({required this.track, this.dragging = false});

  final _Track track;
  final bool dragging;

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(
        display: .flex,
        padding: .symmetric(vertical: 14.px, horizontal: 18.px),
        alignItems: .center,
        gap: .all(16.px),
      ),
      [
        DndDragHandle(
          label: 'Reorder ${track.title}',
          child: div(
            styles: Styles(
              display: .inlineFlex,
              width: 34.px,
              height: 34.px,
              radius: .circular(10.px),
              cursor: dragging ? .grabbing : .grab,
              userSelect: .none,
              justifyContent: .center,
              alignItems: .center,
              color: cAccent,
              fontSize: 18.px,
              backgroundColor: cHandleBg,
            ),
            const [.text('⠿')],
          ),
        ),
        div(
          styles: Styles(
            display: .flex,
            flexDirection: .column,
            gap: .all(2.px),
            flex: Flex(grow: 1, shrink: 1, basis: .auto),
          ),
          [
            strong(
              styles: Styles(fontSize: 16.px),
              [.text(track.title)],
            ),
            span(
              styles: Styles(fontSize: 13.px, color: cMuted),
              [.text(track.artist)],
            ),
          ],
        ),
        span(
          styles: Styles(
            color: cLabel,
            fontSize: 14.px,
            raw: const {'font-variant-numeric': 'tabular-nums'},
          ),
          [.text(track.duration)],
        ),
      ],
    );
  }
}

class _Track {
  const _Track({
    required this.id,
    required this.position,
    required this.title,
    required this.artist,
    required this.duration,
  });

  final DndId id;
  final String position;
  final String title;
  final String artist;
  final String duration;
}

const _initialTracks = <_Track>[
  _Track(
    id: DndId('track-aurora'),
    position: 'Aurora',
    title: 'Aurora Lines',
    artist: 'Hollow Coast',
    duration: '3:42',
  ),
  _Track(
    id: DndId('track-ember'),
    position: 'Ember',
    title: 'Ember Drift',
    artist: 'North Atlas',
    duration: '4:08',
  ),
  _Track(
    id: DndId('track-quartz'),
    position: 'Quartz',
    title: 'Quartz Bloom',
    artist: 'Field Notes',
    duration: '2:57',
  ),
  _Track(
    id: DndId('track-signal'),
    position: 'Signal',
    title: 'Signal Hour',
    artist: 'Paper Kites',
    duration: '3:21',
  ),
  _Track(
    id: DndId('track-tundra'),
    position: 'Tundra',
    title: 'Tundra Glass',
    artist: 'Low Country',
    duration: '5:14',
  ),
];
