import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/overlay`
class OverlayPage extends StatelessComponent {
  const OverlayPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'overlay',
      toc: const [
        (id: 'why', label: 'Why an overlay'),
        (id: 'usage', label: 'Usage'),
      ],
      body: [
        docLead(
          'A drag overlay is a floating preview that follows the pointer while '
          'the original element keeps its place in the layout. It avoids '
          'clipping and reflow during a drag.',
        ),
        youWillLearn(const [
          'When a drag overlay helps over moving the element in place.',
          'How to render an overlay for the active draggable.',
        ]),
        docSection(
          id: 'why',
          title: 'Why an overlay',
          children: [
            docProse(
              'Moving the element itself works for simple cases, but a dragged '
              'element inside a scrollable or clipped container can be cut off, '
              'and reordering its siblings can cause layout jumps. An overlay '
              'renders the drag preview in a top layer instead, so it stays '
              'crisp above everything and never reflows the list underneath.',
            ),
          ],
        ),
        docSection(
          id: 'usage',
          title: 'Usage',
          children: [
            docProseRich([
              docText('Place a '),
              inlineCode('DndDragOverlay'),
              docText(
                ' inside the scope. It renders its builder only while a drag is '
                'active, positioned to follow the pointer.',
              ),
            ]),
            const CodeTabs(
              flutterFile: 'overlay.dart',
              jasprFile: 'overlay.dart',
              flutter: _usageFlutter,
              jaspr: _usageJaspr,
            ),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Sortable lists',
            desc: 'Reorder a list with the sortable preset.',
            href: docHref('sortable'),
          ),
          NextStep(
            label: 'Accessibility',
            desc: 'Keyboard dragging and screen-reader announcements.',
            href: docHref('accessibility'),
          ),
        ]),
      ],
    );
  }
}

const _usageFlutter = '''DndScope(
  child: Stack(
    children: [
      board,
      DndDragOverlay(
        builder: (context, activeId) => CardTile(cardFor(activeId)),
      ),
    ],
  ),
)''';

const _usageJaspr = '''DndScope(
  child: div([
    board,
    DndDragOverlay(
      builder: (context, activeId) => cardTile(cardFor(activeId)),
    ),
  ]),
)''';
