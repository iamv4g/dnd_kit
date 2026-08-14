import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Small capsule label that sits above section headings.
Component eyebrow(String text) {
  return span(
    classes:
        'inline-flex w-fit items-center gap-2 rounded-full bg-accent/10 px-3.5 '
        'py-1.5 font-mono text-xs uppercase tracking-[0.18em] text-accent-deep '
        'dark:text-accent',
    [.text(text)],
  );
}

/// Primary call-to-action: a gradient capsule that lifts on hover.
Component ctaPrimary(String label, String href, {bool external = false}) {
  return a(
    href: href,
    target: external ? Target.blank : null,
    attributes: external ? const {'rel': 'noreferrer'} : null,
    classes:
        'inline-flex items-center gap-2 rounded-full bg-gradient-to-r '
        'from-accent-deep to-accent px-6 py-3 text-sm font-semibold text-white '
        'shadow-lift-accent transition-transform duration-200 ease-spring '
        'hover:-translate-y-0.5',
    [.text(label)],
  );
}

/// Secondary call-to-action: a soft raised capsule.
Component ctaGhost(String label, String href, {bool external = false}) {
  return a(
    href: href,
    target: external ? Target.blank : null,
    attributes: external ? const {'rel': 'noreferrer'} : null,
    classes:
        'inline-flex items-center gap-2 rounded-full bg-surface px-6 py-3 '
        'text-sm font-semibold text-ink shadow-lift transition-transform '
        'duration-200 ease-spring hover:-translate-y-0.5',
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
      classes:
          'reveal max-w-full overflow-x-hidden '
          '${classes == null ? '' : ' $classes'}',
      styles: delayMs == 0
          ? null
          : Styles(raw: {'transition-delay': '${delayMs}ms'}),
      [child],
    );
  }
}

/// Global IntersectionObserver that reveals every `.reveal` element once.
///
/// Deferred until the document has finished parsing: hydration can still be
/// rewriting the body, and querying too early observes nodes that are either
/// missing or already detached, which leaves them stuck at opacity 0.
const revealScript = '''
(function(){
  var io = ('IntersectionObserver' in window)
    ? new IntersectionObserver(function(entries){
        entries.forEach(function(e){
          if (e.isIntersecting) {
            e.target.setAttribute('data-shown','true');
            io.unobserve(e.target);
          }
        });
      }, { rootMargin: '0px 0px -10% 0px', threshold: 0.08 })
    : null;

  // Idempotent: `data-armed` keeps a node from being observed twice, and any
  // node that hydration swapped in arrives unarmed and gets picked up.
  function arm(){
    document.querySelectorAll('.reveal:not([data-armed])').forEach(function(el){
      el.setAttribute('data-armed','');
      if (io) { io.observe(el); } else { el.setAttribute('data-shown','true'); }
    });
  }

  arm();
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', arm);
  }
  window.addEventListener('load', arm);

  // Hydration replaces these wrappers *after* DOMContentLoaded, which detaches
  // whatever the observer was already holding. Re-arm whenever the body
  // changes so the replacements are picked up whenever they land.
  if ('MutationObserver' in window) {
    var pending = false;
    new MutationObserver(function(){
      if (pending) return;
      pending = true;
      requestAnimationFrame(function(){ pending = false; arm(); });
    }).observe(document.body, { childList: true, subtree: true });
  }
})();
''';
