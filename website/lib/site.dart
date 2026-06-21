import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'components/ui.dart';
import 'drag/telemetry_hud.dart';
import 'layout/footer.dart';
import 'layout/nav_bar.dart';
import 'sections/code_sample.dart';
import 'sections/features.dart';
import 'sections/hero.dart';
import 'sections/kanban_showcase.dart';
import 'sections/packages.dart';
import 'sections/playground.dart';

/// The full page body: static sections with hydrated drag islands woven in.
class Site extends StatelessComponent {
  const Site({super.key});

  @override
  Component build(BuildContext context) {
    return .fragment([
      div(id: 'top', const []),
      const NavBar(),
      Component.element(
        tag: 'main',
        children: [
          const Hero(),
          _section(
            id: 'showcase',
            tag: 'Showcase',
            title: 'A board you can actually move',
            desc:
                'A cross-column Kanban built on the generic draggable layer. Drag '
                'a card by its handle within a column or across to another — the '
                'engine reports intent, the board owns the data.',
            child: const KanbanShowcase(),
          ),
          _section(
            id: 'code',
            tag: 'Code',
            title: 'Drag and drop in three steps',
            desc:
                'Wrap an area in a DndScope, mark a draggable and a drop target, '
                'then react when they meet. You own the data; dnd_kit reports the '
                'move — the same API on Flutter and the web.',
            child: const CodeSample(),
          ),
          _section(
            id: 'features',
            tag: 'Capabilities',
            title: 'Everything you need to drag',
            desc:
                'Six things the library ships. Grab any card by its handle and '
                'reorder the grid — this section runs on the sortable preset.',
            child: const Features(),
          ),
          _section(
            id: 'packages',
            tag: 'Packages',
            title: 'One engine, two adapters',
            desc:
                'dnd_kit is the framework-neutral core. dnd_kit_flutter and '
                'dnd_kit_jaspr are peer adapters over it — the same drag logic on '
                'Flutter and the web.',
            child: const Packages(),
          ),
          _section(
            id: 'playground',
            tag: 'Playground',
            title: 'Try it yourself',
            desc:
                'Drag the tokens from the pool into any bucket. Pure generic '
                'droppables with live collision feedback.',
            child: const Playground(),
          ),
        ],
      ),
      const Footer(),
      const TelemetryHud(),
      .element(tag: 'script', children: const [RawText(revealScript)]),
    ]);
  }

  Component _section({
    required String id,
    required String tag,
    required String title,
    required String desc,
    required Component child,
  }) {
    return section(id: id, classes: 'scroll-mt-20', [
      div(classes: 'mx-auto max-w-6xl px-6 py-20', [
        Reveal(
          child: div(classes: 'mb-10 flex flex-col gap-3', [
            eyebrow(tag),
            h2(classes: 'max-w-2xl font-serif text-3xl text-ink sm:text-4xl', [
              .text(title),
            ]),
            p(classes: 'max-w-2xl leading-relaxed text-muted', [.text(desc)]),
          ]),
        ),
        Reveal(delayMs: 80, child: child),
      ]),
    ]);
  }
}
