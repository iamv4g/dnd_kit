/// Static content + external links for the dnd_kit home page.
library;

/// Outbound links wired across the site.
class SiteLinks {
  const SiteLinks._();

  static const github = 'https://github.com/vanvixi/dnd_kit';

  static const pubKit = 'https://pub.dev/packages/dnd_kit';
  static const pubFlutter = 'https://pub.dev/packages/dnd_kit_flutter';
  static const pubJaspr = 'https://pub.dev/packages/dnd_kit_jaspr';

  /// Docs site is built later; placeholder for now.
  static const docs = '#docs';
}

/// In-page nav targets (also the reorderable nav pills).
const navItems = <({String label, String href})>[
  (label: 'Showcase', href: '#showcase'),
  (label: 'Code', href: '#code'),
  (label: 'Features', href: '#features'),
  (label: 'Packages', href: '#packages'),
  (label: 'Playground', href: '#playground'),
];

/// A published package in the family.
class Package {
  const Package({
    required this.name,
    required this.role,
    required this.body,
    required this.href,
    this.isEngine = false,
  });

  final String name;
  final String role;
  final String body;
  final String href;
  final bool isEngine;
}

const enginePackage = Package(
  name: 'dnd_kit',
  role: 'The engine · pure Dart',
  body:
      'The framework-neutral drag runtime: state machine, collision, modifiers '
      'and sortable math. No Flutter, no DOM — just the logic both adapters share.',
  href: SiteLinks.pubKit,
  isEngine: true,
);

const adapterPackages = <Package>[
  Package(
    name: 'dnd_kit_flutter',
    role: 'Flutter adapter',
    body:
        'Widgets and a controller that drive the shared engine on Flutter, '
        'including multi-container sortable.',
    href: SiteLinks.pubFlutter,
  ),
  Package(
    name: 'dnd_kit_jaspr',
    role: 'Web adapter',
    body:
        'Jaspr components over the same engine — SSR-safe, pointer-based. It '
        'powers every drag on this page.',
    href: SiteLinks.pubJaspr,
  ),
];

/// A single capability the library ships.
class Feature {
  const Feature({required this.title, required this.body, required this.glyph});

  final String title;
  final String body;
  final String glyph;
}

const features = <Feature>[
  Feature(
    glyph: '◇',
    title: 'One drag engine',
    body:
        'A single framework-neutral runtime powers both Flutter and the web. '
        'Collision, modifiers and sortable math are computed identically on '
        'every adapter.',
  ),
  Feature(
    glyph: '⌨',
    title: 'Keyboard & a11y',
    body:
        'Every draggable is operable from the keyboard with a live region '
        'announcing pick up, move and drop — accessibility is built in, not '
        'bolted on.',
  ),
  Feature(
    glyph: '⤢',
    title: 'Modifiers',
    body:
        'Constrain movement to an axis, snap to a grid or clamp to a boundary '
        'by composing pure modifier functions on the active transform.',
  ),
  Feature(
    glyph: '⟲',
    title: 'Auto-scroll',
    body:
        'Drag past the edge of a scrollable region and it scrolls to follow, '
        'with velocity driven by the same DOM-free math the engine ships.',
  ),
  Feature(
    glyph: '⧉',
    title: 'SSR-safe',
    body:
        'Pointer-events based, no document listeners and no dart:js_interop at '
        'import time — components pre-render on the server and hydrate cleanly.',
  ),
  Feature(
    glyph: '≡',
    title: 'Sortable presets',
    body:
        'Drop in SortableScope + SortableItem for vertical, horizontal and grid '
        'reordering, or build your own on the generic draggable layer.',
  ),
];
