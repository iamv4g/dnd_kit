import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../ui.dart';

/// Generic drag and drop: [DndDraggable], [DndDroppable], [DndDragHandle], and
/// [DndDragOverlay] over the shared runtime, with app-owned lane state.
class BasicDemo extends StatefulComponent {
  const BasicDemo({super.key});

  @override
  State<BasicDemo> createState() => _BasicDemoState();
}

class _BasicDemoState extends State<BasicDemo> {
  late final DndController _controller = DndController()
    ..addListener(_handleControllerChanged);

  DndId _activeLaneId = _lanes.first.id;
  int _dragStartCount = 0;
  int _dragMoveCount = 0;
  int _dragEndCount = 0;
  int _dragCancelCount = 0;

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

  void _handleDragEnd(DndDragEndEvent event) {
    final overId = event.overId;
    if (overId != null &&
        _lanes.any((lane) => lane.id == overId) &&
        overId != _activeLaneId) {
      setState(() => _activeLaneId = overId);
    }
  }

  @override
  Component build(BuildContext context) {
    final session = _controller.activeSession;
    final isDragging = session != null;
    final activeLane = _lanes.firstWhere((lane) => lane.id == _activeLaneId);
    final overId = _controller.overId?.value ?? 'none';
    final delta = session?.delta ?? DndPoint.zero;
    final currentPointer = session?.currentPointer ?? DndPoint.zero;

    return DndScope(
      controller: _controller,
      child: DemoPanel(
        children: [
          const DemoIntro(
            title: 'Basic drag and drop',
            description:
                'Grab the handle and drag the card in any direction. The drag '
                'overlay follows the shared runtime, the over-target highlights, '
                'and dropping across lanes updates app-owned state — the library '
                'only reports intent.',
          ),
          StatusBar(
            children: [
              Pill(id: 'metric-lane', label: 'Lane', value: activeLane.label),
              Pill(id: 'metric-over', label: 'Over', value: overId),
              Pill(id: 'metric-delta', label: 'Delta', value: formatPoint(delta)),
              Pill(
                id: 'metric-pointer',
                label: 'Pointer',
                value: formatPoint(currentPointer),
              ),
              Pill(
                id: 'metric-state',
                label: 'State',
                value: _controller.state.runtimeType.toString(),
              ),
              Pill(
                id: 'metric-drag-events',
                label: 'Drag',
                value: 's:$_dragStartCount m:$_dragMoveCount '
                    'e:$_dragEndCount c:$_dragCancelCount',
              ),
            ],
          ),
          div(
            styles: Styles(
              display: .flex,
              flexWrap: .wrap,
              alignItems: .stretch,
              gap: .all(20.px),
            ),
            [
              for (final lane in _lanes)
                _Lane(
                  lane: lane,
                  isActiveLane: lane.id == _activeLaneId,
                  child: lane.id == _activeLaneId
                      ? _DraggableTask(
                          isDragging: isDragging,
                          onDragStart: (_) =>
                              setState(() => _dragStartCount += 1),
                          onDragMove: (_) =>
                              setState(() => _dragMoveCount += 1),
                          onDragEnd: (event) {
                            setState(() => _dragEndCount += 1);
                            _handleDragEnd(event);
                          },
                          onDragCancel: (_) =>
                              setState(() => _dragCancelCount += 1),
                        )
                      : const _EmptyLaneState(),
                ),
            ],
          ),
          DndDragOverlay(
            builder: (context, overlayDetails) {
              return _TaskCard(
                title: 'Design API review',
                subtitle:
                    'Overlay follows the shared runtime during free-form dragging.',
                chipLabel: overlayDetails.overId?.value ?? 'moving',
                isDragging: true,
                showHandle: false,
                attributes: const <String, String>{
                  'data-example-overlay': 'true',
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Lane extends StatelessComponent {
  const _Lane({
    required this.lane,
    required this.isActiveLane,
    required this.child,
  });

  final _LaneModel lane;
  final bool isActiveLane;
  final Component child;

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(
        minWidth: 220.px,
        flex: Flex(grow: 1, shrink: 1, basis: 220.px),
      ),
      [
        DndDroppable(
          id: lane.id,
          builder: (context, dropDetails, dropChild) {
            final over = dropDetails.isOver;
            return section(
              id: 'lane-${lane.id.value}',
              styles: Styles(
                display: .flex,
                minHeight: 250.px,
                padding: .all(18.px),
                border: .all(
                  color: over ? cAccentBright : cBorder,
                  width: over ? 2.px : 1.px,
                ),
                radius: .circular(24.px),
                flexDirection: .column,
                gap: .all(16.px),
                backgroundColor: over ? cAccentSoft : cPanelAlt,
              ),
              attributes: <String, String>{
                'data-lane-id': lane.id.value,
                'data-is-over': over.toString(),
              },
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
                      styles: Styles(fontSize: 20.px),
                      [.text(lane.label)],
                    ),
                    Tag(label: over ? 'Drop here' : lane.tone, active: over),
                  ],
                ),
                p(
                  styles: Styles(
                    margin: .zero,
                    color: cMuted,
                    lineHeight: 1.5.em,
                  ),
                  [.text(lane.description)],
                ),
                div(
                  styles: Styles(
                    display: .flex,
                    margin: .only(top: 8.px),
                    flexDirection: .column,
                    gap: .all(12.px),
                  ),
                  [
                    if (isActiveLane) dropChild else const _EmptyLaneState(),
                  ],
                ),
              ],
            );
          },
          child: child,
        ),
      ],
    );
  }
}

class _DraggableTask extends StatelessComponent {
  const _DraggableTask({
    required this.isDragging,
    required this.onDragStart,
    required this.onDragMove,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final bool isDragging;
  final void Function(DndDragStartEvent event) onDragStart;
  final void Function(DndDragMoveEvent event) onDragMove;
  final void Function(DndDragEndEvent event) onDragEnd;
  final void Function(DndDragCancelEvent event) onDragCancel;

  @override
  Component build(BuildContext context) {
    return DndDraggable(
      id: const DndId('task-api-review'),
      label: 'Design API review task',
      description:
          'Press space or enter to pick up, arrow keys to move, space to drop, '
          'escape to cancel.',
      onDragStart: onDragStart,
      onDragMove: onDragMove,
      onDragEnd: onDragEnd,
      onDragCancel: onDragCancel,
      child: _TaskCard(
        title: 'Design API review',
        subtitle:
            'Grab the handle, drag in any direction, and watch the live delta update.',
        chipLabel: 'active task',
        isDragging: isDragging,
        handleId: 'task-handle',
        attributes: const <String, String>{'data-draggable-card': 'true'},
      ),
    );
  }
}

class _TaskCard extends StatelessComponent {
  const _TaskCard({
    required this.title,
    required this.subtitle,
    required this.chipLabel,
    required this.isDragging,
    this.handleId,
    this.showHandle = true,
    this.attributes,
  });

  final String title;
  final String subtitle;
  final String chipLabel;
  final bool isDragging;
  final String? handleId;
  final bool showHandle;
  final Map<String, String>? attributes;

  @override
  Component build(BuildContext context) {
    return article(
      styles: Styles(
        display: .flex,
        padding: .all(18.px),
        border: .all(color: cCardBorder, width: 1.px),
        radius: .circular(22.px),
        cursor: isDragging ? .grabbing : .defaultCursor,
        flexDirection: .column,
        gap: .all(14.px),
        backgroundColor: cCardBg,
      ),
      attributes: attributes,
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
              [.text(title)],
            ),
            Tag(label: chipLabel),
          ],
        ),
        p(
          styles: Styles(margin: .zero, color: cMuted, lineHeight: 1.5.em),
          [.text(subtitle)],
        ),
        if (showHandle)
          div(
            styles: Styles(
              display: .flex,
              justifyContent: .spaceBetween,
              alignItems: .center,
              gap: .all(12.px),
            ),
            [
              DndDragHandle(
                label: 'Drag handle for Design API review',
                child: div(
                  id: handleId,
                  styles: Styles(
                    display: .inlineFlex,
                    padding: .symmetric(vertical: 10.px, horizontal: 14.px),
                    radius: .circular(999.px),
                    cursor: isDragging ? .grabbing : .grab,
                    userSelect: .none,
                    justifyContent: .center,
                    alignItems: .center,
                    color: cWhiteWarm,
                    backgroundColor: cAccent,
                  ),
                  const [.text('Drag handle')],
                ),
              ),
              span(
                styles: Styles(fontSize: 13.px, color: cHint),
                const [.text('Free drag is active')],
              ),
            ],
          ),
      ],
    );
  }
}

class _EmptyLaneState extends StatelessComponent {
  const _EmptyLaneState();

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(
        display: .flex,
        minHeight: 132.px,
        padding: .all(16.px),
        border: .all(color: cBorderSoft, width: 1.px),
        radius: .circular(20.px),
        justifyContent: .center,
        alignItems: .center,
        color: cEmptyText,
        textAlign: .center,
        lineHeight: 1.5.em,
        backgroundColor: cEmptyBg,
      ),
      const [
        .text('Drop the task here to move app-owned state.'),
      ],
    );
  }
}

class _LaneModel {
  const _LaneModel({
    required this.id,
    required this.label,
    required this.tone,
    required this.description,
  });

  final DndId id;
  final String label;
  final String tone;
  final String description;
}

const _lanes = <_LaneModel>[
  _LaneModel(
    id: DndId('lane-brief'),
    label: 'Brief',
    tone: 'Start',
    description:
        'The task starts here so the example can show handle-only pickup.',
  ),
  _LaneModel(
    id: DndId('lane-build'),
    label: 'Build',
    tone: 'Transit',
    description:
        'Free movement keeps the example natural on desktop and mobile layouts.',
  ),
  _LaneModel(
    id: DndId('lane-ship'),
    label: 'Ship',
    tone: 'Finish',
    description:
        'Dropping here updates local app state, not library-owned state.',
  ),
];
