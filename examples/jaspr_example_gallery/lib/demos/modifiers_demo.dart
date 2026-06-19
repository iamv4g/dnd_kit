import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../ui.dart';

/// Movement modifiers: [DndModifiers] reshape the active drag transform before
/// collision, so the overlay follows a constrained path. Modifiers are fixed
/// per controller, so switching one rebuilds the controller.
class ModifiersDemo extends StatefulComponent {
  const ModifiersDemo({super.key});

  @override
  State<ModifiersDemo> createState() => _ModifiersDemoState();
}

enum _Choice { none, vertical, horizontal, grid }

class _ModifiersDemoState extends State<ModifiersDemo> {
  _Choice _choice = _Choice.vertical;
  DndController? _controller;

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _controller
      ?..removeListener(_handleControllerChanged)
      ..dispose();
    _controller = null;
  }

  DndController get _activeController {
    return _controller ??= DndController(modifiers: _modifiersFor(_choice))
      ..addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _select(_Choice choice) {
    if (choice == _choice) {
      return;
    }
    setState(() {
      _choice = choice;
      _disposeController();
    });
  }

  List<DndModifier> _modifiersFor(_Choice choice) {
    return switch (choice) {
      _Choice.none => const <DndModifier>[],
      _Choice.vertical => <DndModifier>[DndModifiers.restrictToVerticalAxis],
      _Choice.horizontal => <DndModifier>[
        DndModifiers.restrictToHorizontalAxis,
      ],
      _Choice.grid => <DndModifier>[
        DndModifiers.snapToGrid(width: 40, height: 40),
      ],
    };
  }

  @override
  Component build(BuildContext context) {
    final controller = _activeController;
    final session = controller.activeSession;
    final transform = session?.transform ?? DndTransform.identity;
    final gridRaw = _choice == _Choice.grid
        ? const <String, String>{
            'background-image':
                'linear-gradient(#e7d8bf 1px, transparent 1px), '
                'linear-gradient(90deg, #e7d8bf 1px, transparent 1px)',
            'background-size': '40px 40px',
          }
        : null;

    return DndScope(
      key: ValueKey<_Choice>(_choice),
      controller: controller,
      child: DemoPanel(
        children: [
          const DemoIntro(
            title: 'Movement modifiers',
            description:
                'Modifiers reshape the drag transform in the shared runtime '
                'before collision. Pick one and drag the card: the overlay '
                'follows the constrained path while the modifier math runs in '
                'dnd_kit, not in the example.',
          ),
          div(
            styles: Styles(display: .flex, flexWrap: .wrap, gap: .all(10.px)),
            [
              _choiceButton(_Choice.none, 'None'),
              _choiceButton(_Choice.vertical, 'Vertical axis'),
              _choiceButton(_Choice.horizontal, 'Horizontal axis'),
              _choiceButton(_Choice.grid, 'Snap to 40px grid'),
            ],
          ),
          StatusBar(
            children: [
              Pill(label: 'Modifier', value: _choiceLabel(_choice)),
              Pill(
                label: 'Transform',
                value:
                    '${transform.x.toStringAsFixed(0)}, '
                    '${transform.y.toStringAsFixed(0)}',
              ),
              Pill(
                label: 'State',
                value: controller.state.runtimeType.toString(),
              ),
            ],
          ),
          div(
            styles: Styles(
              display: .flex,
              position: .relative(),
              height: 320.px,
              border: .all(color: cBorder, width: 1.px),
              radius: .circular(22.px),
              justifyContent: .center,
              alignItems: .center,
              backgroundColor: cPanelBg,
              raw: gridRaw,
            ),
            [
              DndDraggable(
                id: const DndId('modifier-card'),
                label: 'Constrained drag card',
                description:
                    'Press space to pick up, arrow keys to move, space to drop, '
                    'escape to cancel.',
                child: div(
                  styles: Styles(
                    maxWidth: 220.px,
                    padding: .symmetric(vertical: 18.px, horizontal: 22.px),
                    border: .all(color: cCardBorder, width: 1.px),
                    radius: .circular(18.px),
                    cursor: .grab,
                    userSelect: .none,
                    textAlign: .center,
                    backgroundColor: cCardBg,
                  ),
                  [
                    strong(const [.text('Drag me')]),
                    p(
                      styles: Styles(
                        margin: .only(top: 6.px),
                        color: cMuted,
                        fontSize: 13.px,
                      ),
                      [.text(_choiceHint(_choice))],
                    ),
                  ],
                ),
              ),
              DndDragOverlay(
                builder: (context, overlayDetails) {
                  return div(
                    styles: Styles(
                      maxWidth: 220.px,
                      padding: .symmetric(vertical: 18.px, horizontal: 22.px),
                      radius: .circular(18.px),
                      shadow: BoxShadow(
                        offsetX: 0.px,
                        offsetY: 18.px,
                        blur: 36.px,
                        color: .rgba(154, 52, 18, 0.3),
                      ),
                      color: cWhiteWarm,
                      fontWeight: .w600,
                      textAlign: .center,
                      backgroundColor: cAccent,
                    ),
                    const [.text('Following the modifier')],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Component _choiceButton(_Choice choice, String label) {
    final active = choice == _choice;
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
      onClick: () => _select(choice),
      [.text(label)],
    );
  }

  String _choiceLabel(_Choice choice) {
    return switch (choice) {
      _Choice.none => 'none',
      _Choice.vertical => 'restrictToVerticalAxis',
      _Choice.horizontal => 'restrictToHorizontalAxis',
      _Choice.grid => 'snapToGrid(40, 40)',
    };
  }

  String _choiceHint(_Choice choice) {
    return switch (choice) {
      _Choice.none => 'Free movement in any direction.',
      _Choice.vertical => 'Moves up and down only.',
      _Choice.horizontal => 'Moves left and right only.',
      _Choice.grid => 'Snaps translation to a 40px grid.',
    };
  }
}
