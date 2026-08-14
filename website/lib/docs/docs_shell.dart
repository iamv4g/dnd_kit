import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/ui.dart';
import '../layout/footer.dart';
import '../layout/nav_bar.dart';
import 'docs_nav.dart';

/// The shared documentation chrome: top nav, a grouped left sidebar, the page
/// body, a right-rail "On this page" table of contents, and a previous/next
/// pager. Every docs page wraps its content in this shell.
class DocsShell extends StatelessComponent {
  const DocsShell({
    required this.slug,
    required this.toc,
    required this.body,
    super.key,
  });

  /// The current page's slug (matches a [DocEntry.slug]).
  final String slug;

  /// Right-rail anchors for the sections on this page.
  final List<({String id, String label})> toc;

  /// The page body — lead, callout, and sections.
  final List<Component> body;

  DocEntry get _entry => docOrder.firstWhere((e) => e.slug == slug);

  @override
  Component build(BuildContext context) {
    final entry = _entry;
    return .fragment([
      div(id: 'top', const []),
      const NavBar(activeDocs: true),
      Component.element(
        tag: 'main',
        children: [
          div(
            classes:
                'mx-auto max-w-7xl gap-10 px-6 py-10 '
                'lg:grid lg:grid-cols-[14rem_minmax(0,1fr)] '
                'xl:grid-cols-[14rem_minmax(0,1fr)_13rem]',
            [_sidebar(), _content(entry), _tocRail()],
          ),
        ],
      ),
      const Footer(),
    ]);
  }

  Component _sidebar() {
    return Component.element(
      tag: 'aside',
      classes: 'hidden lg:block',
      children: [
        nav(
          classes: 'sticky top-24 flex flex-col gap-6',
          attributes: const {'aria-label': 'Documentation'},
          [
            for (final group in docGroups)
              div(classes: 'flex flex-col gap-1', [
                span(
                  classes:
                      'mb-1 font-mono text-xs uppercase tracking-[0.18em] '
                      'text-muted',
                  [.text(group.label)],
                ),
                for (final entry in group.entries) _sidebarLink(entry),
              ]),
          ],
        ),
      ],
    );
  }

  /// A sidebar capsule; the current page is marked by a tinted fill.
  Component _sidebarLink(DocEntry entry) {
    final active = entry.slug == slug;
    return a(
      href: entry.href,
      attributes: active ? const {'aria-current': 'page'} : null,
      classes:
          'rounded-full px-3.5 py-1.5 text-sm transition-colors duration-200 '
          '${active ? 'bg-accent/10 font-semibold text-accent' : 'text-muted hover:bg-accent/10 hover:text-accent'}',
      [.text(entry.navLabel)],
    );
  }

  /// A collapsible group menu shown below the `lg` breakpoint, where the
  /// fixed sidebar is hidden. Native `<details>`, so it needs no hydration.
  Component _mobileNav() {
    return Component.element(
      tag: 'details',
      classes:
          // Near-opaque on purpose: the panel scrolls over the dark code slabs,
          // and anything lighter lets them bleed through the list. `group` sits
          // here (not on the summary) because `group-open:` reads the `open`
          // attribute, which lives on the details element.
          'group sticky top-16 z-20 mb-8 rounded-3xl squircle bg-surface/95 '
          'shadow-lift backdrop-blur-xl lg:hidden',
      children: [
        Component.element(
          tag: 'summary',
          classes:
              'flex cursor-pointer select-none items-center gap-2 '
              'rounded-3xl px-5 py-3.5 text-sm font-semibold text-ink',
          children: [
            span(classes: 'flex-1', const [.text('Documentation menu')]),
            Component.element(
              tag: 'svg',
              classes:
                  'h-4 w-4 shrink-0 text-faint transition-transform '
                  'duration-200 group-open:rotate-180',
              attributes: const {
                'viewBox': '0 0 16 16',
                'fill': 'none',
                'stroke': 'currentColor',
                'stroke-width': '1.8',
                'stroke-linecap': 'round',
                'stroke-linejoin': 'round',
                'aria-hidden': 'true',
              },
              children: [
                Component.element(
                  tag: 'path',
                  attributes: const {'d': 'M4 6.5 8 10.5 12 6.5'},
                ),
              ],
            ),
          ],
        ),
        div(
          classes: 'flex max-h-[70vh] flex-col gap-5 overflow-auto px-4 pb-4',
          [
            for (final group in docGroups)
              div(classes: 'flex flex-col gap-1', [
                span(
                  classes:
                      'mb-1 font-mono text-xs uppercase tracking-[0.18em] '
                      'text-muted',
                  [.text(group.label)],
                ),
                for (final entry in group.entries) _sidebarLink(entry),
              ]),
          ],
        ),
      ],
    );
  }

  Component _content(DocEntry entry) {
    return div(classes: 'min-w-0', [
      _mobileNav(),
      eyebrow(entry.group),
      h1(
        classes:
            'mt-3 font-display text-4xl font-extrabold tracking-[-0.04em] '
            'text-ink sm:text-5xl',
        [.text(entry.title)],
      ),
      div(classes: 'mt-6 flex flex-col gap-10', body),
      _pager(),
    ]);
  }

  Component _tocRail() {
    if (toc.isEmpty) return Component.element(tag: 'div', children: const []);
    return Component.element(
      tag: 'aside',
      classes: 'hidden xl:block',
      children: [
        nav(
          classes: 'sticky top-24 flex flex-col gap-2',
          attributes: const {'aria-label': 'On this page'},
          [
            span(
              classes:
                  'font-mono text-xs uppercase tracking-[0.18em] text-muted',
              const [.text('On this page')],
            ),
            for (final item in toc)
              a(
                href: _entry.anchor(item.id),
                classes: 'text-sm text-muted transition-colors hover:text-ink',
                [.text(item.label)],
              ),
          ],
        ),
      ],
    );
  }

  Component _pager() {
    final prev = docPrev(slug);
    final next = docNext(slug);
    if (prev == null && next == null) {
      return Component.element(tag: 'div', children: const []);
    }
    return .fragment([
      div(
        classes:
            'mt-12 h-px bg-gradient-to-r from-transparent via-line '
            'to-transparent',
        const [],
      ),
      div(classes: 'mt-6 flex items-stretch justify-between gap-4', [
        if (prev != null) _pagerLink(prev, next: false) else div(const []),
        if (next != null) _pagerLink(next, next: true) else div(const []),
      ]),
    ]);
  }

  Component _pagerLink(DocEntry entry, {required bool next}) {
    return a(
      href: entry.href,
      classes:
          'card card-hover flex flex-col gap-0.5 px-5 py-3 '
          '${next ? 'items-end text-right' : 'items-start'}',
      [
        span(classes: 'font-mono text-xs text-muted', [
          .text(next ? 'Next' : 'Previous'),
        ]),
        span(classes: 'font-medium text-ink', [
          .text(next ? '${entry.navLabel} →' : '← ${entry.navLabel}'),
        ]),
      ],
    );
  }
}
