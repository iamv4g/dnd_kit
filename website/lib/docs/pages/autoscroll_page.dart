import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/auto-scroll`
class AutoscrollPage extends StatelessComponent {
  const AutoscrollPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'auto-scroll',
      toc: const [
        (id: 'how', label: 'How it works'),
        (id: 'usage', label: 'Usage'),
        (id: 'options', label: 'Options'),
      ],
      body: [
        docLead(
          'When a drag reaches the edge of a scrollable region, auto-scroll '
          'moves the content to follow — so you can drag into parts of a list '
          'or board that are off-screen.',
        ),
        youWillLearn(const [
          'How edge auto-scroll is driven.',
          'How to wrap a scrollable region with DndAutoScroll.',
          'Which axis and options you can tune.',
        ]),
        docSection(
          id: 'how',
          title: 'How it works',
          children: [
            docProse(
              'The scroll velocity comes from the same DOM-free math on both '
              'adapters: the closer the pointer is to an edge, the faster the '
              'region scrolls. Only the execution differs — Flutter drives a '
              'Scrollable, Jaspr scrolls a DOM element.',
            ),
          ],
        ),
        docSection(
          id: 'usage',
          title: 'Usage',
          children: [
            docProseRich([
              docText('Wrap the scrollable area in a '),
              inlineCode('DndAutoScroll'),
              docText(' inside the scope. On Flutter it drives the nearest '),
              inlineCode('Scrollable'),
              docText('; on Jaspr you make the wrapper scroll with '),
              inlineCode('overflow'),
              docText(' styles or classes.'),
            ]),
            const CodeTabs(
              flutterFile: 'auto_scroll.dart',
              jasprFile: 'auto_scroll.dart',
              flutter: _flutterCode,
              jaspr: _jasprCode,
            ),
          ],
        ),
        docSection(
          id: 'options',
          title: 'Options',
          children: [
            docBullets(const [
              'axis — DndScrollAxis.vertical (default) or horizontal.',
              'enabled — turn auto-scroll off without unwrapping.',
              'options — a DndAutoScrollOptions to tune edge thresholds and '
                  'speed.',
            ]),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Sortable lists',
            desc: 'Reorder long lists that scroll while dragging.',
            href: docHref('sortable'),
          ),
          NextStep(
            label: 'Multi-container sortable',
            desc: 'Auto-scroll columns on a Kanban board.',
            href: docHref('multi-container'),
          ),
        ]),
      ],
    );
  }
}

const _flutterCode = '''DndScope(
  child: DndAutoScroll(
    axis: DndScrollAxis.vertical,
    child: ListView(children: cards),
  ),
)''';

const _jasprCode = '''DndScope(
  child: DndAutoScroll(
    axis: DndScrollAxis.vertical,
    classes: 'max-h-[480px] overflow-auto',
    child: div(cards),
  ),
)''';
