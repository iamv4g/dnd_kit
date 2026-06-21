import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/site_data.dart';

/// Page footer with the outbound links and a quiet sign-off.
class Footer extends StatelessComponent {
  const Footer({super.key});

  @override
  Component build(BuildContext context) {
    return footer(classes: 'border-t border-line', [
      div(
        classes:
            'mx-auto flex max-w-6xl flex-col items-start justify-between '
            'gap-6 px-6 py-12 sm:flex-row sm:items-center',
        [
          div(classes: 'flex flex-col gap-1', [
            span(classes: 'font-serif text-lg text-ink', [
              .text('dnd'),
              span(classes: 'text-accent', [.text('_')]),
              .text('kit'),
            ]),
            span(classes: 'text-sm text-muted', const [
              .text('One drag engine for Flutter and the web.'),
            ]),
          ]),
          div(classes: 'flex flex-wrap items-center gap-5 text-sm', [
            _link('GitHub', SiteLinks.github, external: true),
            _link('pub.dev', SiteLinks.pubKit, external: true),
            _link('Docs', SiteLinks.docs),
          ]),
        ],
      ),
    ]);
  }

  Component _link(String label, String href, {bool external = false}) {
    return a(
      href: href,
      target: external ? Target.blank : null,
      attributes: external ? const {'rel': 'noreferrer'} : null,
      classes: 'text-muted transition-colors hover:text-accent',
      [.text(label)],
    );
  }
}
