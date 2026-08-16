import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Shared building blocks for documentation pages: the lead paragraph, the
/// "You'll learn" callout, section wrappers, prose, bullet lists, inline code,
/// and the "Next steps" card grid.

const _prose = 'max-w-3xl leading-relaxed text-muted';

/// The one-sentence summary directly under a page heading.
Component docLead(String text) {
  return p(classes: 'max-w-3xl text-lg leading-relaxed text-muted', [
    .text(text),
  ]);
}

/// A short outcomes callout shown near the top of a page.
Component youWillLearn(List<String> items) {
  return div(classes: 'max-w-3xl rounded-3xl squircle bg-raised/70 p-5', [
    span(
      classes: 'font-mono text-xs uppercase tracking-[0.18em] text-accent',
      const [.text("You'll learn")],
    ),
    ul(classes: 'mt-3 flex flex-col gap-1.5 text-muted', [
      for (final item in items)
        li(classes: 'flex gap-2', [
          span(classes: 'text-accent', const [.text('—')]),
          span([.text(item)]),
        ]),
    ]),
  ]);
}

/// A page section with an anchored `<h2>` heading.
Component docSection({
  required String id,
  required String title,
  required List<Component> children,
}) {
  return section(id: id, classes: 'scroll-mt-24', [
    h2(
      classes:
          'font-display text-2xl font-extrabold tracking-[-0.03em] text-ink '
          'sm:text-3xl',
      [.text(title)],
    ),
    div(classes: 'mt-4 flex flex-col gap-4', children),
  ]);
}

/// A prose paragraph. [spans] lets a paragraph mix text with inline code.
Component docProse(String text) => p(classes: _prose, [.text(text)]);

/// A prose paragraph built from mixed inline content (text + inlineCode).
Component docProseRich(List<Component> spans) => p(classes: _prose, spans);

/// Plain inline text node, for composing with [inlineCode] in [docProseRich].
Component docText(String text) => Component.text(text);

/// An inline link, for composing with text inside [docProseRich].
Component docLink(String label, String href) {
  return a(
    href: href,
    classes: 'text-accent underline underline-offset-2 hover:no-underline',
    [.text(label)],
  );
}

/// Inline `code` styling.
Component inlineCode(String text) {
  return Component.element(
    tag: 'code',
    classes: 'rounded bg-raised px-1.5 py-0.5 font-mono text-[0.85em] text-ink',
    children: [.text(text)],
  );
}

/// A plain (non-tabbed) code block with a filename label.
Component docCodeBlock(String filename, String code) {
  return div(
    classes:
        'overflow-hidden rounded-[2rem] squircle bg-[#0C1420] '
        'dark:bg-surface shadow-lift',
    [
      div(classes: 'flex items-center px-6 pt-5', [
        span(classes: 'ml-auto font-mono text-xs text-[#5A6B84]', [
          .text(filename),
        ]),
      ]),
      Component.element(
        tag: 'pre',
        classes:
            'overflow-x-auto px-6 pb-6 pt-3 font-mono text-sm leading-relaxed '
            'text-[#D9E2EF]',
        children: [.text(code)],
      ),
    ],
  );
}

/// An unordered list of prose items.
Component docBullets(List<String> items) {
  return ul(classes: 'flex max-w-3xl flex-col gap-2 text-muted', [
    for (final item in items)
      li(classes: 'flex gap-2', [
        span(classes: 'mt-0.5 text-accent', const [.text('•')]),
        span([.text(item)]),
      ]),
  ]);
}

/// A "Next steps" card linking to another doc page or external resource.
class NextStep {
  const NextStep({
    required this.label,
    required this.desc,
    required this.href,
    this.external = false,
  });

  final String label;
  final String desc;
  final String href;
  final bool external;
}

/// The "Next steps" card grid shown at the bottom of a page body.
Component nextSteps(List<NextStep> steps) {
  return div(classes: 'mt-2 grid gap-3 sm:grid-cols-2', [
    for (final step in steps)
      a(
        href: step.href,
        target: step.external ? Target.blank : null,
        attributes: step.external ? const {'rel': 'noreferrer'} : null,
        classes: 'card card-hover flex flex-col gap-1 p-5',
        [
          span(classes: 'font-semibold text-ink', [
            .text(step.external ? '${step.label} ↗' : step.label),
          ]),
          span(classes: 'text-sm text-muted', [.text(step.desc)]),
        ],
      ),
  ]);
}
