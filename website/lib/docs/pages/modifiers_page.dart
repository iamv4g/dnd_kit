import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/modifiers`
class ModifiersPage extends StatelessComponent {
  const ModifiersPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'modifiers',
      toc: const [
        (id: 'what', label: 'What modifiers do'),
        (id: 'builtin', label: 'Built-in modifiers'),
        (id: 'applying', label: 'Applying them'),
      ],
      body: [
        docLead(
          'Modifiers adjust the active drag transform before it is applied — '
          'constrain movement to an axis, snap to a grid, or clamp within a '
          'boundary. Each is a pure function, so they compose cleanly.',
        ),
        youWillLearn(const [
          'What a modifier is.',
          'The built-in modifiers the engine ships.',
          'How to apply one or several at once.',
        ]),
        docSection(
          id: 'what',
          title: 'What modifiers do',
          children: [
            docProseRich([
              docText('A modifier is a function from a '),
              inlineCode('DndModifierInput'),
              docText(' to a '),
              inlineCode('DndTransform'),
              docText(
                '. The engine runs it on every frame of a drag, so the change '
                'is live and identical on both adapters.',
              ),
            ]),
          ],
        ),
        docSection(
          id: 'builtin',
          title: 'Built-in modifiers',
          children: [
            docProseRich([
              docText('They live on '),
              inlineCode('DndModifiers'),
              docText(':'),
            ]),
            docBullets(const [
              'restrictToHorizontalAxis — lock movement to the x axis.',
              'restrictToVerticalAxis — lock movement to the y axis.',
              'restrictToBoundary(rect) — clamp the element within a rectangle.',
              'snapToGrid(width: , height: ) — quantize movement to a grid.',
              'compose(modifiers) — apply several in order, first to last.',
            ]),
          ],
        ),
        docSection(
          id: 'applying',
          title: 'Applying them',
          children: [
            docProseRich([
              docText('Pass modifiers to the '),
              inlineCode('DndController'),
              docText(' on your scope:'),
            ]),
            const CodeTabs(
              flutterFile: 'scope.dart',
              jasprFile: 'scope.dart',
              flutter: _oneCode,
              jaspr: _oneCode,
            ),
            docProse('Combine several — snap to a grid and clamp to a box:'),
            const CodeTabs(
              flutterFile: 'scope.dart',
              jasprFile: 'scope.dart',
              flutter: _manyCode,
              jaspr: _manyCode,
            ),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Auto-scroll',
            desc: 'Scroll a container while dragging past its edge.',
            href: docHref('auto-scroll'),
          ),
          NextStep(
            label: 'Collision detection',
            desc: 'Decide which target a draggable lands on.',
            href: docHref('collision'),
          ),
        ]),
      ],
    );
  }
}

const _oneCode = '''DndScope(
  controller: DndController(
    modifiers: [DndModifiers.restrictToHorizontalAxis],
  ),
  child: board,
)''';

const _manyCode = '''DndController(
  modifiers: [
    DndModifiers.snapToGrid(width: 16, height: 16),
    DndModifiers.restrictToBoundary(boardRect),
  ],
)''';
