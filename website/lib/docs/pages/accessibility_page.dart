import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/accessibility`
class AccessibilityPage extends StatelessComponent {
  const AccessibilityPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'accessibility',
      toc: const [
        (id: 'keyboard', label: 'Keyboard'),
        (id: 'announcements', label: 'Announcements'),
        (id: 'handles', label: 'Handles & labels'),
      ],
      body: [
        docLead(
          'Accessibility is built in, not bolted on. Every draggable is '
          'operable from the keyboard, and a live region narrates the drag so '
          'screen-reader users follow the same interaction as everyone else.',
        ),
        youWillLearn(const [
          'How keyboard dragging works out of the box.',
          'How drag progress is announced.',
          'How to label drag handles for assistive tech.',
        ]),
        docSection(
          id: 'keyboard',
          title: 'Keyboard',
          children: [
            docProse(
              'Draggables are focusable and operable without a pointer. The '
              'keyboard sensor is active by default:',
            ),
            docBullets(const [
              'Space or Enter — pick up the focused item, and drop it.',
              'Arrow keys — move the lifted item between positions or targets.',
              'Escape — cancel the drag and return the item to its origin.',
            ]),
          ],
        ),
        docSection(
          id: 'announcements',
          title: 'Announcements',
          children: [
            docProseRich([
              docText(
                'Drag progress is announced through a polite live region. On '
                'Jaspr, mount a ',
              ),
              inlineCode('DndLiveRegion'),
              docText(
                ' inside the scope; on Flutter, the adapter emits semantics '
                'announcements. Both speak the same shared ',
              ),
              inlineCode('DndAnnouncements'),
              docText(' contract — pick up, move, drop, and cancel.'),
            ]),
            const CodeTabs(
              flutterFile: 'a11y.dart',
              jasprFile: 'a11y.dart',
              flutter: _flutter,
              jaspr: _jaspr,
            ),
          ],
        ),
        docSection(
          id: 'handles',
          title: 'Handles & labels',
          children: [
            docProseRich([
              docText('Give every '),
              inlineCode('DndDragHandle'),
              docText(' a descriptive '),
              inlineCode('label'),
              docText(
                ' so assistive technology announces what it moves — for '
                'example "Reorder card: Buy milk" rather than an unlabeled grip.',
              ),
            ]),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Sortable lists',
            desc: 'Keyboard-accessible reordering by default.',
            href: docHref('sortable'),
          ),
          NextStep(
            label: 'Overview',
            desc: 'Back to the documentation home.',
            href: docHref(''),
          ),
        ]),
      ],
    );
  }
}

const _flutter = '''DndScope(
  // Flutter: announcements are emitted as semantics events automatically.
  child: board,
)''';

const _jaspr = '''DndScope(
  child: div([
    board,
    const DndLiveRegion(), // polite live region for screen readers
  ]),
)''';
