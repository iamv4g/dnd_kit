import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The basic usage, with a Jaspr / Flutter tab toggle so the same three steps
/// show on both adapters.
@client
class CodeSample extends StatefulComponent {
  const CodeSample({super.key});

  @override
  State<CodeSample> createState() => _CodeSampleState();
}

class _CodeSampleState extends State<CodeSample> {
  int _tab = 0; // 0 = Flutter, 1 = Jaspr (web)

  static const _tabs = ['Flutter', 'Jaspr'];

  String get _code => _tab == 0 ? _flutterCode : _jasprCode;

  @override
  Component build(BuildContext context) {
    return div(
      classes:
          'overflow-hidden rounded-2xl border border-line bg-surface shadow-lift',
      [
        div(
          classes:
              'flex items-center gap-3 border-b border-line bg-raised px-4 py-3',
          [
            div(classes: 'flex items-center gap-2', [
              span(classes: 'h-3 w-3 rounded-full bg-accent/70', const []),
              span(classes: 'h-3 w-3 rounded-full bg-muted/40', const []),
              span(classes: 'h-3 w-3 rounded-full bg-muted/40', const []),
            ]),
            div(
              classes: 'ml-1 flex items-center gap-1',
              attributes: const {'role': 'tablist'},
              [
                for (var i = 0; i < _tabs.length; i++)
                  button(
                    classes:
                        'rounded-full px-3 py-1 font-mono text-xs transition-colors '
                        '${i == _tab ? 'bg-accent text-white' : 'text-muted hover:text-ink'}',
                    attributes: {
                      'type': 'button',
                      'role': 'tab',
                      'aria-selected': (i == _tab).toString(),
                    },
                    onClick: () => setState(() => _tab = i),
                    [.text(_tabs[i])],
                  ),
              ],
            ),
            span(classes: 'ml-auto font-mono text-xs text-muted', const [
              .text('main.dart'),
            ]),
          ],
        ),
        Component.element(
          tag: 'pre',
          classes:
              'overflow-x-auto p-5 font-mono text-sm leading-relaxed text-ink',
          children: [.text(_code)],
        ),
      ],
    );
  }
}

const _jasprCode = '''import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';

// 1. Wrap the area in a DndScope.
DndScope(
  child: div([
    // 2. Make anything draggable.
    DndDraggable(
      id: const DndId('card'),
      onDragEnd: (event) {
        // 3. React when it lands on a target.
        if (event.overId == const DndId('inbox')) {
          moveCardToInbox();
        }
      },
      child: div([.text('Drag me')]),
    ),

    // ...and anything a drop target.
    DndDroppable(
      id: const DndId('inbox'),
      child: div([.text('Inbox')]),
    ),
  ]),
)''';

const _flutterCode = '''import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/widgets.dart';

// 1. Wrap the area in a DndScope.
DndScope(
  child: Column(
    children: [
      // 2. Make anything draggable.
      DndDraggable(
        id: const DndId('card'),
        onDragEnd: (event) {
          // 3. React when it lands on a target.
          if (event.overId == const DndId('inbox')) {
            moveCardToInbox();
          }
        },
        child: const Text('Drag me'),
      ),

      // ...and anything a drop target.
      DndDroppable(
        id: const DndId('inbox'),
        child: const Text('Inbox'),
      ),
    ],
  ),
)''';
