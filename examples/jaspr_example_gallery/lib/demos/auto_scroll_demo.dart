import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../ui.dart';

/// Drag-driven auto-scroll: [DndAutoScroll] scrolls a bounded viewport while a
/// drag pointer rests in its leading or trailing edge band, on either axis.
class AutoScrollDemo extends StatefulComponent {
  const AutoScrollDemo({super.key});

  @override
  State<AutoScrollDemo> createState() => _AutoScrollDemoState();
}

class _AutoScrollDemoState extends State<AutoScrollDemo> {
  static const int _slotCount = 16;

  late final DndController _controller = DndController()
    ..addListener(_handleControllerChanged);

  DndScrollAxis _axis = DndScrollAxis.vertical;
  int _tokenSlot = 1;
  bool _isDragging = false;

  bool get _horizontal => _axis == DndScrollAxis.horizontal;

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

  void _selectAxis(DndScrollAxis axis) {
    if (axis != _axis && _controller.isIdle) {
      setState(() => _axis = axis);
    }
  }

  void _handleDragEnd(DndDragEndEvent event) {
    final overId = event.overId;
    setState(() {
      _isDragging = false;
      if (overId != null && overId.value.startsWith('slot-')) {
        _tokenSlot = int.parse(overId.value.substring('slot-'.length));
      }
    });
  }

  @override
  Component build(BuildContext context) {
    final session = _controller.activeSession;
    final overId = _controller.overId?.value ?? 'none';
    final pointer = session?.currentPointer ?? DndPoint.zero;

    return DndScope(
      controller: _controller,
      child: DemoPanel(
        children: [
          const DemoIntro(
            title: 'Drag-driven auto-scroll',
            description:
                'Pick up the token and drag it toward an edge of the bounded '
                'viewport. DndAutoScroll scrolls while the pointer stays in the '
                'edge band — top/bottom on the vertical axis, left/right on the '
                'horizontal axis — reusing the same shared core velocity curve, '
                'so the token can reach an off-screen slot.',
          ),
          div(
            styles: Styles(display: .flex, flexWrap: .wrap, gap: .all(10.px)),
            [
              _axisButton(DndScrollAxis.vertical, 'Vertical axis'),
              _axisButton(DndScrollAxis.horizontal, 'Horizontal axis'),
            ],
          ),
          StatusBar(
            children: [
              Pill(label: 'Axis', value: _horizontal ? 'horizontal' : 'vertical'),
              Pill(label: 'Token slot', value: '#$_tokenSlot'),
              Pill(label: 'Over', value: overId),
              Pill(label: 'Pointer', value: formatPoint(pointer)),
              Pill(
                label: 'State',
                value: _controller.state.runtimeType.toString(),
              ),
            ],
          ),
          DndAutoScroll(
            axis: _axis,
            styles: _horizontal
                ? Styles(
                    height: 150.px,
                    border: .all(color: cBorder, width: 1.px),
                    radius: .circular(22.px),
                    overflow: .only(x: .auto, y: .hidden),
                    backgroundColor: cPanelAlt,
                  )
                : Styles(
                    height: 340.px,
                    border: .all(color: cBorder, width: 1.px),
                    radius: .circular(22.px),
                    overflow: .only(x: .hidden, y: .auto),
                    backgroundColor: cPanelAlt,
                  ),
            child: div(
              styles: Styles(
                display: .flex,
                padding: .all(12.px),
                flexDirection: _horizontal ? .row : .column,
                flexWrap: .nowrap,
                gap: .all(10.px),
              ),
              [
                for (var slot = 1; slot <= _slotCount; slot++)
                  _Slot(
                    slot: slot,
                    horizontal: _horizontal,
                    token: slot == _tokenSlot
                        ? _Token(
                            isDragging: _isDragging,
                            onDragStart: (_) =>
                                setState(() => _isDragging = true),
                            onDragEnd: _handleDragEnd,
                            onDragCancel: (_) =>
                                setState(() => _isDragging = false),
                          )
                        : null,
                  ),
              ],
            ),
          ),
          DndDragOverlay(
            builder: (context, overlayDetails) {
              return div(
                styles: Styles(
                  padding: .symmetric(vertical: 10.px, horizontal: 16.px),
                  radius: .circular(999.px),
                  shadow: BoxShadow(
                    offsetX: 0.px,
                    offsetY: 16.px,
                    blur: 30.px,
                    color: .rgba(154, 52, 18, 0.3),
                  ),
                  color: cWhiteWarm,
                  fontWeight: .w600,
                  backgroundColor: cAccent,
                ),
                const [.text('Token')],
              );
            },
          ),
        ],
      ),
    );
  }

  Component _axisButton(DndScrollAxis axis, String label) {
    final active = axis == _axis;
    return button(
      styles: Styles(
        padding: .symmetric(vertical: 10.px, horizontal: 16.px),
        border: .all(color: active ? cAccent : cBorder, width: 1.px),
        radius: .circular(999.px),
        cursor: .pointer,
        fontFamily: kFontFamily,
        fontSize: 14.px,
        color: active ? cWhiteWarm : cText,
        backgroundColor: active ? cAccent : cPillBg,
      ),
      onClick: () => _selectAxis(axis),
      [.text(label)],
    );
  }
}

class _Slot extends StatelessComponent {
  const _Slot({required this.slot, required this.horizontal, this.token});

  final int slot;
  final bool horizontal;
  final Component? token;

  @override
  Component build(BuildContext context) {
    final id = DndId('slot-$slot');
    return DndDroppable(
      id: id,
      builder: (context, dragState, child) {
        final over = dragState.isOver;
        final border = Border.all(
          color: over ? cAccentBright : cBorderSoft,
          width: over ? 2.px : 1.px,
        );
        final background = over ? cAccentSoft : cCardBg;
        return div(
          styles: horizontal
              ? Styles(
                  display: .flex,
                  minWidth: 150.px,
                  minHeight: 90.px,
                  padding: .symmetric(vertical: 12.px, horizontal: 14.px),
                  border: border,
                  radius: .circular(14.px),
                  flexDirection: .column,
                  justifyContent: .spaceBetween,
                  gap: .all(8.px),
                  flex: .none,
                  backgroundColor: background,
                )
              : Styles(
                  display: .flex,
                  minHeight: 54.px,
                  padding: .symmetric(vertical: 0.px, horizontal: 16.px),
                  border: border,
                  radius: .circular(14.px),
                  justifyContent: .spaceBetween,
                  alignItems: .center,
                  gap: .all(12.px),
                  backgroundColor: background,
                ),
          attributes: <String, String>{'data-slot-id': id.value},
          [
            span(
              styles: Styles(color: cLabel, fontSize: 14.px),
              [.text('Slot $slot')],
            ),
            child,
          ],
        );
      },
      child: token ??
          span(
            styles: Styles(fontSize: 13.px, color: const Color('#b3a489')),
            const [.text('empty')],
          ),
    );
  }
}

class _Token extends StatelessComponent {
  const _Token({
    required this.isDragging,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final bool isDragging;
  final void Function(DndDragStartEvent event) onDragStart;
  final void Function(DndDragEndEvent event) onDragEnd;
  final void Function(DndDragCancelEvent event) onDragCancel;

  @override
  Component build(BuildContext context) {
    return DndDraggable(
      id: const DndId('auto-scroll-token'),
      label: 'Auto-scroll token',
      description:
          'Press space to pick up, arrow keys to move, space to drop, escape to '
          'cancel.',
      onDragStart: onDragStart,
      onDragEnd: onDragEnd,
      onDragCancel: onDragCancel,
      child: div(
        styles: Styles(
          padding: .symmetric(vertical: 8.px, horizontal: 16.px),
          radius: .circular(999.px),
          cursor: isDragging ? .grabbing : .grab,
          userSelect: .none,
          color: cWhiteWarm,
          fontWeight: .w600,
          backgroundColor: cAccent,
        ),
        const [.text('Drag token')],
      ),
    );
  }
}
