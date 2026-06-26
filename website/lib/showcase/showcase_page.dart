import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/ui.dart';
import '../data/site_data.dart';
import '../layout/footer.dart';
import '../layout/nav_bar.dart';
import '../sections/kanban_showcase.dart';
import '../sections/playground.dart';

/// `/showcase` — a dedicated page that runs dnd_kit live in the browser (Jaspr)
/// and embeds the Flutter example gallery, so the same drag-and-drop shows on
/// both adapters.
class ShowcasePage extends StatelessComponent {
  const ShowcasePage({super.key});

  @override
  Component build(BuildContext context) {
    return .fragment([
      div(id: 'top', const []),
      const NavBar(activeShowcase: true),
      Component.element(
        tag: 'main',
        children: [
          _header(),
          _section(
            eyebrow: 'Live · Jaspr',
            title: 'A board you can actually move',
            desc:
                'A cross-column Kanban on the supported multi-container surface, '
                'running right here on dnd_kit_jaspr. Drag a card by its handle '
                'within a column or across to another — the engine resolves move '
                'intent, the board owns the data.',
            child: const KanbanShowcase(),
          ),
          _section(
            eyebrow: 'Live · Jaspr',
            title: 'Drop zones with live collision',
            desc:
                'Drag the tokens from the pool into any bucket. Pure generic '
                'droppables with live collision feedback — the same engine, a '
                'different shape.',
            child: const Playground(),
          ),
          _flutterSection(),
        ],
      ),
      const Footer(),
    ]);
  }

  Component _header() {
    return section(classes: 'border-b border-line', [
      div(classes: 'mx-auto max-w-6xl px-6 py-16', [
        eyebrow('Showcase'),
        h1(classes: 'mt-3 max-w-3xl font-serif text-4xl text-ink sm:text-5xl', [
          .text('See it run — on Flutter and the web'),
        ]),
        p(classes: 'mt-4 max-w-2xl text-lg leading-relaxed text-muted', const [
          .text(
            'One drag-and-drop engine, two adapters. The demos below run live '
            'in your browser on dnd_kit_jaspr; the same gallery, built with '
            'dnd_kit_flutter, is embedded further down running as a real '
            'Flutter web app.',
          ),
        ]),
      ]),
    ]);
  }

  Component _section({
    required String eyebrow,
    required String title,
    required String desc,
    required Component child,
  }) {
    return section(classes: 'border-b border-line', [
      div(classes: 'mx-auto max-w-6xl px-6 py-16', [
        div(classes: 'mb-10 flex flex-col gap-3', [
          span(
            classes:
                'font-mono text-xs uppercase tracking-[0.22em] text-accent',
            [.text(eyebrow)],
          ),
          h2(classes: 'max-w-2xl font-serif text-3xl text-ink sm:text-4xl', [
            .text(title),
          ]),
          p(classes: 'max-w-2xl leading-relaxed text-muted', [.text(desc)]),
        ]),
        child,
      ]),
    ]);
  }

  Component _flutterSection() {
    return section(classes: 'border-b border-line', [
      div(classes: 'mx-auto max-w-6xl px-6 py-16', [
        div(classes: 'mb-8 flex flex-col gap-3', [
          span(
            classes:
                'font-mono text-xs uppercase tracking-[0.22em] text-accent',
            const [.text('Live · Flutter')],
          ),
          h2(classes: 'max-w-2xl font-serif text-3xl text-ink sm:text-4xl', [
            .text('The same demos, on Flutter'),
          ]),
          p(classes: 'max-w-2xl leading-relaxed text-muted', const [
            .text(
              'This is the dnd_kit_flutter example gallery compiled to the web '
              'and embedded below. Same catalog, same drag engine — running on '
              'Flutter instead of Jaspr.',
            ),
          ]),
        ]),
        div(
          classes:
              'overflow-hidden rounded-2xl border border-line bg-surface '
              'shadow-lift',
          [
            Component.element(
              tag: 'iframe',
              classes: 'h-[680px] w-full',
              attributes: {
                'src': SiteLinks.flutterGallery,
                'title': 'dnd_kit Flutter example gallery',
                'loading': 'lazy',
              },
              children: const [],
            ),
          ],
        ),
        div(classes: 'mt-4', [
          ctaGhost(
            'Open the Flutter gallery in a new tab',
            SiteLinks.flutterGallery,
            external: true,
          ),
        ]),
      ]),
    ]);
  }
}
