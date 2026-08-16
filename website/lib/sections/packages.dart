import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/site_data.dart';

/// The package family, drawn as a hierarchy: the `dnd_kit` engine on top
/// powering the two adapters below, so it reads at a glance that one engine
/// drives both. Each card links to its pub.dev page.
class Packages extends StatelessComponent {
  const Packages({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'mx-auto flex max-w-4xl flex-col', [
      _card(enginePackage),
      _joint(),
      div(classes: 'grid grid-cols-1 gap-4 sm:grid-cols-2', [
        for (final pkg in adapterPackages) _card(pkg),
      ]),
    ]);
  }

  /// The "renders as" connector between the engine card and the adapters.
  Component _joint() {
    return div(
      classes: 'flex items-center justify-center gap-4 py-6 text-muted',
      [
        _curve('M2 2 C 40 2, 40 22, 118 22'),
        span(
          classes:
              'whitespace-nowrap font-mono text-[10px] uppercase '
              'tracking-[0.18em] text-accent-deep dark:text-accent',
          const [.text('renders as')],
        ),
        _curve('M2 22 C 80 22, 80 2, 118 2'),
      ],
    );
  }

  Component _curve(String path) {
    return Component.element(
      tag: 'svg',
      classes: 'h-6 w-[120px] shrink-0',
      attributes: const {
        'viewBox': '0 0 120 24',
        'fill': 'none',
        'aria-hidden': 'true',
      },
      children: [
        Component.element(
          tag: 'path',
          attributes: {
            'd': path,
            'stroke': 'currentColor',
            'stroke-opacity': '0.35',
            'stroke-width': '2.5',
            'stroke-linecap': 'round',
          },
        ),
      ],
    );
  }

  Component _card(Package pkg) {
    final isEngine = pkg.isEngine;
    return a(
      href: pkg.href,
      target: Target.blank,
      attributes: const {'rel': 'noreferrer'},
      classes:
          'group flex h-full w-full flex-col gap-3 p-6 card card-hover '
          '${isEngine ? 'bg-gradient-to-br from-[#0B2740] to-[#0F4C75] text-white' : ''}',
      [
        div(classes: 'flex flex-wrap items-center justify-between gap-3', [
          span(
            classes:
                'font-mono text-lg font-bold tracking-[-0.02em] '
                '${isEngine ? 'text-white' : 'text-ink'}',
            [.text(pkg.name)],
          ),
          span(
            classes:
                'rounded-full px-3 py-1 font-mono text-[10px] uppercase '
                'tracking-wider '
                '${isEngine ? 'bg-white/15 text-white/85' : 'bg-accent/10 text-accent-deep dark:text-accent'}',
            [.text(pkg.role)],
          ),
        ]),
        p(
          classes:
              'text-sm leading-relaxed '
              '${isEngine ? 'text-white/75' : 'text-muted'}',
          [.text(pkg.body)],
        ),
        span(
          classes:
              'text-sm font-semibold transition-transform '
              'group-hover:translate-x-0.5 '
              '${isEngine ? 'text-sky' : 'text-accent'}',
          const [.text('View on pub.dev →')],
        ),
      ],
    );
  }
}
