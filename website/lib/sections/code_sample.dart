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
      // On dark ground #0C1420 sits almost on top of the paper, so the slab
      // steps up to the raised surface instead and keeps its separation.
      classes:
          'overflow-hidden rounded-[2.5rem] squircle bg-[#0C1420] '
          'dark:bg-surface shadow-lift-hi',
      [
        div(classes: 'flex flex-wrap items-center gap-2 px-5 pt-5', [
          div(
            classes: 'flex items-center gap-1',
            attributes: const {'role': 'tablist'},
            [
              for (var i = 0; i < _tabs.length; i++)
                button(
                  classes:
                      'rounded-full px-4 py-2 font-mono text-xs font-bold '
                      'transition-colors duration-200 '
                      '${i == _tab ? 'bg-white/10 text-white' : 'text-[#8FA3BC] hover:text-white'}',
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
          span(classes: 'ml-auto font-mono text-xs text-[#5A6B84]', const [
            .text('main.dart'),
          ]),
        ]),
        Component.element(
          tag: 'pre',
          classes:
              'overflow-x-auto px-6 pb-7 pt-4 font-mono text-sm '
              'leading-relaxed text-[#D9E2EF]',
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
