import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Mono uppercase label that sits above section headings.
Component eyebrow(String text) {
  return span(
    classes: 'font-mono text-xs uppercase tracking-[0.22em] text-accent',
    [.text(text)],
  );
}

/// Solid coral call-to-action.
Component ctaPrimary(String label, String href, {bool external = false}) {
  return a(
    href: href,
    target: external ? Target.blank : null,
    attributes: external ? const {'rel': 'noreferrer'} : null,
    classes:
        'inline-flex items-center gap-2 rounded-full bg-accent px-5 py-2.5 '
        'text-sm font-semibold text-white shadow-lift-accent transition-transform '
        'duration-200 hover:-translate-y-0.5 hover:bg-accent-deep',
    [.text(label)],
  );
}

/// Outlined secondary call-to-action.
Component ctaGhost(String label, String href, {bool external = false}) {
  return a(
    href: href,
    target: external ? Target.blank : null,
    attributes: external ? const {'rel': 'noreferrer'} : null,
    classes:
        'inline-flex items-center gap-2 rounded-full border border-line px-5 '
        'py-2.5 text-sm font-semibold text-ink transition-colors duration-200 '
        'hover:border-accent hover:text-accent',
    [.text(label)],
  );
}

/// Wraps [child] so it fades up the first time it scrolls into view.
///
/// Pure CSS (the `.reveal` utility) flipped by [revealScript]; no hydration
/// needed, so it works for server-rendered static sections.
class Reveal extends StatelessComponent {
  const Reveal({
    required this.child,
    this.delayMs = 0,
    this.classes,
    super.key,
  });

  final Component child;
  final int delayMs;
  final String? classes;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'reveal${classes == null ? '' : ' $classes'}',
      styles: delayMs == 0
          ? null
          : Styles(raw: {'transition-delay': '${delayMs}ms'}),
      [child],
    );
  }
}

/// Global IntersectionObserver that reveals every `.reveal` element once.
const revealScript = '''
(function(){
  var els = document.querySelectorAll('.reveal');
  if (!('IntersectionObserver' in window)) {
    els.forEach(function(el){ el.setAttribute('data-shown','true'); });
    return;
  }
  var io = new IntersectionObserver(function(entries){
    entries.forEach(function(e){
      if (e.isIntersecting) {
        e.target.setAttribute('data-shown','true');
        io.unobserve(e.target);
      }
    });
  }, { rootMargin: '0px 0px -10% 0px', threshold: 0.08 });
  els.forEach(function(el){ io.observe(el); });
})();
''';
