import 'package:jaspr/jaspr.dart';

import '../../data/site_data.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs` — the documentation landing page.
class OverviewPage extends StatelessComponent {
  const OverviewPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: '',
      toc: const [
        (id: 'features', label: 'Key features'),
        (id: 'packages', label: 'Choose a package'),
        (id: 'concepts', label: 'Core concepts'),
      ],
      body: [
        docLead(
          'dnd_kit is one drag-and-drop engine for Flutter and the web. A '
          'framework-neutral core does the drag math; thin adapters render it '
          'on each platform — so the same API moves cards on Flutter and in '
          'the browser.',
        ),
        docSection(
          id: 'features',
          title: 'Key features',
          children: [
            docBullets(const [
              'One engine, two adapters — identical collision, modifier, and '
                  'sortable math on Flutter and the web.',
              'Batteries included — draggable, droppable, drag overlay, '
                  'sortable lists, and multi-container Kanban presets.',
              'Accessible by default — keyboard dragging and live-region '
                  'announcements are built in, not bolted on.',
              'SSR-safe on the web — components pre-render on the server and '
                  'hydrate without DOM access at import time.',
            ]),
          ],
        ),
        docSection(
          id: 'packages',
          title: 'Choose a package',
          children: [
            docProse('Pick the package for your platform, then read on:'),
            nextSteps([
              NextStep(
                label: 'dnd_kit_flutter',
                desc: 'Flutter apps — widgets, sensors, overlays, sortable.',
                href: SiteLinks.pubFlutter,
                external: true,
              ),
              NextStep(
                label: 'dnd_kit_jaspr',
                desc:
                    'Jaspr (Dart web) apps — the web adapter, no Flutter SDK.',
                href: SiteLinks.pubJaspr,
                external: true,
              ),
              NextStep(
                label: 'dnd_kit',
                desc: 'The shared engine — custom adapters and drag math.',
                href: SiteLinks.pubKit,
                external: true,
              ),
              NextStep(
                label: 'Installation',
                desc: 'Add a package and start dragging.',
                href: docHref('install'),
              ),
            ]),
          ],
        ),
        docSection(
          id: 'concepts',
          title: 'Core concepts',
          children: [
            docProse('The essential building blocks, smallest first:'),
            nextSteps([
              NextStep(
                label: 'Quickstart',
                desc: 'Wire a draggable and a droppable in three steps.',
                href: docHref('quickstart'),
              ),
              NextStep(
                label: 'Draggable',
                desc: 'Make any widget or element pick-up-able.',
                href: docHref('draggable'),
              ),
              NextStep(
                label: 'Droppable',
                desc: 'Define the targets a draggable can land on.',
                href: docHref('droppable'),
              ),
              NextStep(
                label: 'Sortable lists',
                desc: 'Reorder a list with the sortable preset.',
                href: docHref('sortable'),
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
