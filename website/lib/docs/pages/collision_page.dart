import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/collision`
class CollisionPage extends StatelessComponent {
  const CollisionPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'collision',
      toc: const [
        (id: 'detectors', label: 'Built-in detectors'),
        (id: 'setting', label: 'Setting a detector'),
        (id: 'composing', label: 'Composing'),
      ],
      body: [
        docLead(
          'When a draggable overlaps several droppables, a collision detector '
          'decides which one wins. Detection is shared math in the engine, so '
          'Flutter and Jaspr resolve the same target from the same input.',
        ),
        youWillLearn(const [
          'The built-in collision detectors and when to use each.',
          'How to set a detector on a scope.',
          'How to combine detectors into a fallback chain.',
        ]),
        docSection(
          id: 'detectors',
          title: 'Built-in detectors',
          children: [
            docProseRich([
              docText('All detectors live on '),
              inlineCode('DndCollisionDetectors'),
              docText(':'),
            ]),
            docBullets(const [
              'closestCenter — the target whose center is nearest the pointer. '
                  'A solid default for grids and free layouts.',
              'closestCorners — compares corners instead of centers; steadier '
                  'when targets vary a lot in size.',
              'rectIntersection — the target the dragged rect overlaps most. '
                  'Natural for list and Kanban reordering.',
              'pointerWithin — only targets the pointer is literally inside. '
                  'Precise, but needs a pointer (not keyboard) drag.',
            ]),
          ],
        ),
        docSection(
          id: 'setting',
          title: 'Setting a detector',
          children: [
            docProseRich([
              docText('Pass a detector to the '),
              inlineCode('DndController'),
              docText(' on your '),
              inlineCode('DndScope'),
              docText('. The default is '),
              inlineCode('closestCenter'),
              docText('.'),
            ]),
            const CodeTabs(
              flutterFile: 'scope.dart',
              jasprFile: 'scope.dart',
              flutter: _setCode,
              jaspr: _setCode,
            ),
          ],
        ),
        docSection(
          id: 'composing',
          title: 'Composing',
          children: [
            docProseRich([
              docText('Use '),
              inlineCode('compose'),
              docText(
                ' to try detectors in order and take the first that finds a '
                'target — for example, prefer a precise pointer hit, then fall '
                'back to overlap.',
              ),
            ]),
            const CodeTabs(
              flutterFile: 'scope.dart',
              jasprFile: 'scope.dart',
              flutter: _composeCode,
              jaspr: _composeCode,
            ),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Sensors & activation',
            desc: 'Choose input methods and require intent.',
            href: docHref('sensors'),
          ),
          NextStep(
            label: 'Modifiers',
            desc: 'Constrain the drag transform.',
            href: docHref('modifiers'),
          ),
        ]),
      ],
    );
  }
}

const _setCode = '''DndScope(
  controller: DndController(
    collisionDetector: DndCollisionDetectors.closestCenter,
  ),
  child: board,
)''';

const _composeCode = '''DndController(
  collisionDetector: DndCollisionDetectors.compose([
    DndCollisionDetectors.pointerWithin,
    DndCollisionDetectors.rectIntersection,
  ]),
)''';
