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

  Component _sidebarLink(DocEntry entry) {
    final active = entry.slug == slug;
    return a(
      href: entry.href,
      attributes: active ? const {'aria-current': 'page'} : null,
      classes:
          'rounded-lg px-3 py-1.5 text-sm transition-colors '
          '${active ? 'bg-surface font-medium text-accent' : 'text-muted hover:bg-surface hover:text-ink'}',
      [.text(entry.navLabel)],
    );
  }

  Component _content(DocEntry entry) {
    return div(classes: 'min-w-0', [
      eyebrow(entry.group),
      h1(classes: 'mt-3 font-serif text-4xl text-ink sm:text-5xl', [
        .text(entry.title),
      ]),
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
    return div(
      classes:
          'mt-12 flex items-stretch justify-between gap-4 border-t '
          'border-line pt-6',
      [
        if (prev != null) _pagerLink(prev, next: false) else div(const []),
        if (next != null) _pagerLink(next, next: true) else div(const []),
      ],
    );
  }

  Component _pagerLink(DocEntry entry, {required bool next}) {
    return a(
      href: entry.href,
      classes:
          'flex flex-col gap-0.5 rounded-2xl border border-line bg-surface '
          'px-5 py-3 transition-colors hover:border-accent '
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
