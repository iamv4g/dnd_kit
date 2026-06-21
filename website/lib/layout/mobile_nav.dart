import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/site_data.dart';

/// Hamburger menu for mobile (the reorderable nav pills are desktop-only).
@client
class MobileNav extends StatefulComponent {
  const MobileNav({super.key});

  @override
  State<MobileNav> createState() => _MobileNavState();
}

class _MobileNavState extends State<MobileNav> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);
  void _close() => setState(() => _open = false);

  @override
  Component build(BuildContext context) {
    return div(classes: 'relative md:hidden', [
      button(
        classes:
            'inline-grid h-10 w-10 place-items-center rounded-full border '
            'border-line bg-surface text-ink transition-colors '
            'hover:border-accent hover:text-accent',
        attributes: {
          'type': 'button',
          'aria-label': _open ? 'Close menu' : 'Open menu',
          'aria-expanded': _open.toString(),
        },
        onClick: _toggle,
        [
          span(classes: 'text-lg leading-none', [.text(_open ? '✕' : '☰')]),
        ],
      ),
      if (_open)
        div(
          classes:
              'absolute right-0 top-full mt-2 w-56 origin-top-right rounded-2xl '
              'border border-line bg-surface p-2 shadow-lift animate-fade-in',
          [
            for (final item in navItems)
              a(
                href: item.href,
                classes:
                    'block rounded-xl px-3 py-2 text-sm font-medium text-ink '
                    'transition-colors hover:bg-raised',
                onClick: _close,
                [.text(item.label)],
              ),
            div(classes: 'my-1 h-px bg-line', const []),
            a(
              href: SiteLinks.github,
              target: Target.blank,
              attributes: const {'rel': 'noreferrer'},
              classes:
                  'block rounded-xl px-3 py-2 text-sm font-medium text-muted '
                  'transition-colors hover:bg-raised',
              onClick: _close,
              [.text('GitHub ↗')],
            ),
            a(
              href: SiteLinks.docs,
              classes:
                  'block rounded-xl px-3 py-2 text-sm font-medium text-muted '
                  'transition-colors hover:bg-raised',
              onClick: _close,
              [.text('Docs')],
            ),
          ],
        ),
    ]);
  }
}
