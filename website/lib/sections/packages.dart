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
    return div(classes: 'mx-auto flex max-w-3xl flex-col items-center', [
      // The engine — full width on mobile, centered above the gap on >= sm.
      div(classes: 'flex w-full justify-center', [
        div(classes: 'w-full sm:max-w-sm', [_card(enginePackage)]),
      ]),

      // Mobile: an indented tree so both adapters visibly branch off the one
      // engine — a left spine with a tick into each card.
      div(classes: 'flex flex-col sm:hidden', [
        // Short stem from the engine down to the first branch.
        div(classes: 'flex', [
          div(classes: 'relative h-4 w-6 shrink-0', [
            div(classes: 'absolute left-3 top-0 h-full w-px bg-line', const []),
          ]),
        ]),
        _treeRow(adapterPackages[0], last: false),
        _treeRow(adapterPackages[1], last: true),
      ]),

      // Desktop: a branching connector — a short stem from the engine, a
      // horizontal bar, then a drop into the center of each adapter card. The
      // adapters use a no-gap 2-column grid so their centers sit exactly at
      // 25% / 75%, which the bar ends and drops line up with.
      div(classes: 'relative hidden h-12 w-full sm:block', [
        // Stem: engine bottom → bar center.
        div(
          classes: 'absolute left-1/2 top-0 h-6 w-px -translate-x-1/2 bg-line',
          const [],
        ),
        // Horizontal bar between the two card centers.
        div(
          classes: 'absolute left-1/4 right-1/4 top-6 h-px bg-line',
          const [],
        ),
        // Drops to each card center.
        div(
          classes: 'absolute left-1/4 top-6 h-6 w-px -translate-x-1/2 bg-line',
          const [],
        ),
        div(
          classes: 'absolute right-1/4 top-6 h-6 w-px translate-x-1/2 bg-line',
          const [],
        ),
        // "powers" label sitting on the bar's midpoint.
        div(
          classes:
              'absolute left-1/2 top-6 -translate-x-1/2 -translate-y-1/2 '
              'bg-paper px-2',
          [
            span(
              classes:
                  'font-mono text-[10px] uppercase tracking-wider text-accent',
              const [.text('powers')],
            ),
          ],
        ),
      ]),

      // Desktop adapters: no gap so each cell center is exactly 25% / 75%,
      // which the tree connector lines up with. (Mobile uses the tree above.)
      div(classes: 'hidden w-full sm:grid sm:grid-cols-2 sm:gap-0', [
        for (final pkg in adapterPackages)
          div(classes: 'sm:px-3', [_card(pkg)]),
      ]),
    ]);
  }

  // One adapter row of the mobile tree: a rail (spine + branch tick) and the
  // card. The spine runs full height except the [last] row, which stops at the
  // branch so the tree ends cleanly.
  Component _treeRow(Package pkg, {required bool last}) {
    return div(classes: 'flex items-stretch', [
      div(classes: 'relative w-6 shrink-0', [
        div(
          classes:
              'absolute left-3 top-0 w-px bg-line ${last ? 'h-1/2' : 'h-full'}',
          const [],
        ),
        div(
          classes: 'absolute left-3 top-1/2 h-px w-3 -translate-y-1/2 bg-line',
          const [],
        ),
      ]),
      div(classes: 'flex-1 py-2', [_card(pkg)]),
    ]);
  }

  Component _card(Package pkg) {
    final accent = pkg.isEngine;
    return a(
      href: pkg.href,
      target: Target.blank,
      attributes: const {'rel': 'noreferrer'},
      classes:
          'group flex h-full w-full flex-col gap-3 rounded-2xl border p-5 '
          'transition-colors '
          '${accent ? 'border-accent/50 bg-accent/5 hover:border-accent' : 'border-line bg-surface hover:border-accent/50'}',
      [
        div(classes: 'flex items-center justify-between gap-3', [
          span(classes: 'font-mono text-lg text-ink', [.text(pkg.name)]),
          span(
            classes: accent
                ? 'rounded-full bg-accent px-2.5 py-0.5 font-mono text-[10px] '
                      'uppercase tracking-wider text-white'
                : 'rounded-full border border-line px-2.5 py-0.5 font-mono '
                      'text-[10px] uppercase tracking-wider text-muted',
            [.text(pkg.role)],
          ),
        ]),
        p(classes: 'text-sm leading-relaxed text-muted', [.text(pkg.body)]),
        span(
          classes:
              'text-sm font-medium text-accent transition-transform '
              'group-hover:translate-x-0.5',
          const [.text('View on pub.dev →')],
        ),
      ],
    );
  }
}
