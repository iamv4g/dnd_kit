/// The documentation information architecture: grouped sidebar entries plus a
/// flat ordered list that drives the previous/next pager. This is the single
/// source of truth for the docs section — pages, routes, and the sidebar all
/// read from it.
library;

/// One documentation page.
class DocEntry {
  const DocEntry({
    required this.slug,
    required this.navLabel,
    required this.title,
    required this.group,
  });

  /// URL slug under `/docs`. Empty for the docs landing (`/docs`).
  final String slug;

  /// Short label shown in the sidebar.
  final String navLabel;

  /// Page heading (`<h1>`).
  final String title;

  /// Group label, shown as the eyebrow above the heading.
  final String group;

  /// jaspr_router path for this page (e.g. `/docs` or `/docs/draggable`).
  String get routePath => slug.isEmpty ? '/docs' : '/docs/$slug';

  /// Link target, relative to the document `<base href>`. Trailing slash keeps
  /// same-page anchors on the generated `index.html` instead of bouncing
  /// through a Pages redirect.
  String get href => slug.isEmpty ? 'docs/' : 'docs/$slug/';

  /// A same-page anchor link to a section [id] on this page.
  String anchor(String id) => '$href#$id';
}

/// A labelled group of sidebar entries.
class DocGroup {
  const DocGroup({required this.label, required this.entries});

  final String label;
  final List<DocEntry> entries;
}

const docGroups = <DocGroup>[
  DocGroup(
    label: 'Get started',
    entries: [
      DocEntry(
        slug: '',
        navLabel: 'Overview',
        title: 'dnd_kit documentation',
        group: 'Get started',
      ),
      DocEntry(
        slug: 'install',
        navLabel: 'Installation',
        title: 'Installation',
        group: 'Get started',
      ),
      DocEntry(
        slug: 'quickstart',
        navLabel: 'Quickstart',
        title: 'Quickstart',
        group: 'Get started',
      ),
    ],
  ),
  DocGroup(
    label: 'Concepts',
    entries: [
      DocEntry(
        slug: 'draggable',
        navLabel: 'Draggable',
        title: 'Draggable',
        group: 'Concepts',
      ),
      DocEntry(
        slug: 'droppable',
        navLabel: 'Droppable',
        title: 'Droppable',
        group: 'Concepts',
      ),
      DocEntry(
        slug: 'overlay',
        navLabel: 'Drag overlay',
        title: 'Drag overlay',
        group: 'Concepts',
      ),
      DocEntry(
        slug: 'collision',
        navLabel: 'Collision detection',
        title: 'Collision detection',
        group: 'Concepts',
      ),
      DocEntry(
        slug: 'sensors',
        navLabel: 'Sensors & activation',
        title: 'Sensors & activation',
        group: 'Concepts',
      ),
      DocEntry(
        slug: 'modifiers',
        navLabel: 'Modifiers',
        title: 'Modifiers',
        group: 'Concepts',
      ),
      DocEntry(
        slug: 'auto-scroll',
        navLabel: 'Auto-scroll',
        title: 'Auto-scroll',
        group: 'Concepts',
      ),
    ],
  ),
  DocGroup(
    label: 'Sortable',
    entries: [
      DocEntry(
        slug: 'sortable',
        navLabel: 'Sortable lists',
        title: 'Sortable lists',
        group: 'Sortable',
      ),
      DocEntry(
        slug: 'multi-container',
        navLabel: 'Multi-container',
        title: 'Multi-container sortable',
        group: 'Sortable',
      ),
    ],
  ),
  DocGroup(
    label: 'Accessibility',
    entries: [
      DocEntry(
        slug: 'accessibility',
        navLabel: 'Accessibility',
        title: 'Accessibility',
        group: 'Accessibility',
      ),
    ],
  ),
  DocGroup(
    label: 'Reference',
    entries: [
      DocEntry(
        slug: 'reference',
        navLabel: 'API reference',
        title: 'API reference',
        group: 'Reference',
      ),
    ],
  ),
];

/// All entries in sidebar order — drives the previous/next pager.
final List<DocEntry> docOrder = [
  for (final group in docGroups) ...group.entries,
];

/// The entry immediately before [slug] in reading order, or null.
DocEntry? docPrev(String slug) {
  final i = docOrder.indexWhere((e) => e.slug == slug);
  return i > 0 ? docOrder[i - 1] : null;
}

/// The entry immediately after [slug] in reading order, or null.
DocEntry? docNext(String slug) {
  final i = docOrder.indexWhere((e) => e.slug == slug);
  return i >= 0 && i < docOrder.length - 1 ? docOrder[i + 1] : null;
}

/// The base-relative link for a page [slug] (for cross-page references).
String docHref(String slug) => docOrder.firstWhere((e) => e.slug == slug).href;
