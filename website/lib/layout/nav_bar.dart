import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/site_data.dart';
import '../drag/drag_bus.dart';
import '../theme/theme_toggle.dart';
import 'mobile_nav.dart';

/// Sticky top navigation. The in-page links are reorderable (drag a pill to
/// rearrange them) while still navigating on a plain click.
class NavBar extends StatelessComponent {
  const NavBar({
    this.activeDocs = false,
    this.activeShowcase = false,
    super.key,
  });

  /// Highlights the Docs pill when the docs page is the current route.
  final bool activeDocs;

  /// Highlights the Showcase pill when the showcase page is the current route.
  final bool activeShowcase;

  @override
  Component build(BuildContext context) {
    return nav(
      classes:
          'sticky top-0 z-30 border-b border-line bg-paper/80 backdrop-blur',
      [
        div(
          classes:
              'mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 '
              'px-6',
          [
            a(
              href: '#top',
              classes: 'font-serif text-xl font-semibold text-ink',
              [
                .text('dnd'),
                span(classes: 'text-accent', [.text('_')]),
                .text('kit'),
              ],
            ),
            const ReorderableNav(),
            div(classes: 'flex items-center gap-1.5', [
              a(
                href: SiteLinks.showcase,
                classes:
                    'pill-link hidden sm:inline-block'
                    '${activeShowcase ? ' text-accent' : ''}',
                attributes: activeShowcase
                    ? const {'aria-current': 'page'}
                    : null,
                [.text('Showcase')],
              ),
              a(
                href: SiteLinks.github,
                target: Target.blank,
                attributes: const {'rel': 'noreferrer'},
                classes: 'pill-link hidden sm:inline-block',
                [.text('GitHub')],
              ),
              a(
                href: SiteLinks.docs,
                classes:
                    'pill-link hidden sm:inline-block'
                    '${activeDocs ? ' text-accent' : ''}',
                attributes: activeDocs ? const {'aria-current': 'page'} : null,
                [.text('Docs')],
              ),
              const ThemeToggle(),
              const MobileNav(),
            ]),
          ],
        ),
      ],
    );
  }
}

/// The reorderable in-page nav pills.
@client
class ReorderableNav extends StatefulComponent {
  const ReorderableNav({super.key});

  @override
  State<ReorderableNav> createState() => _ReorderableNavState();
}

class _ReorderableNavState extends State<ReorderableNav> {
  late final DndController _controller = DndController()
    ..addListener(_onChanged);

  late List<DndId> _order = [
    for (var i = 0; i < navItems.length; i++) DndId('nav-$i'),
  ];

  ({String label, String href}) _itemFor(DndId id) =>
      navItems[int.parse(id.value.split('-').last)];

  void _onChanged() {
    dragBus.report(_controller, source: 'nav');
    if (mounted) setState(() {});
  }

  void _onMove(SortableMoveDetails details) {
    setState(() {
      final next = List<DndId>.of(_order);
      next.insert(details.toIndex, next.removeAt(details.fromIndex));
      _order = next;
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return SortableScope(
      controller: _controller,
      strategy: SortableStrategies.horizontalList,
      itemIds: _order,
      onMove: _onMove,
      child: div(classes: 'hidden items-center gap-1 md:flex', [
        for (final id in _order)
          SortableItem(
            id: id,
            constraint: const DndSensorActivationConstraint(distance: 6),
            label: 'Reorder ${_itemFor(id).label}',
            builder: (context, itemState, child) {
              // No floating overlay here (it would sit behind the sticky nav),
              // so lift the pill in place while dragging instead of dimming it.
              final dragging = itemState.isActive || itemState.isDragging;
              return div(
                classes:
                    'transition-transform duration-150 '
                    '${dragging ? '-translate-y-0.5 scale-105' : ''}',
                [child],
              );
            },
            // A hover-revealed grip is the drag surface; pressing the link text
            // itself does not trigger pointer capture, so the anchor still
            // navigates on a plain click. Drag the grip to reorder.
            child: div(classes: 'group flex items-center rounded-full', [
              DndDragHandle(
                label: 'Reorder ${_itemFor(id).label}',
                child: span(
                  classes:
                      'cursor-grab select-none pl-2 text-xs leading-none '
                      'text-muted/40 opacity-0 transition-opacity '
                      'group-hover:opacity-100',
                  attributes: const {'aria-hidden': 'true'},
                  [.text('⠿')],
                ),
              ),
              a(
                href: _itemFor(id).href,
                attributes: const {'draggable': 'false'},
                classes: 'pill-link',
                [.text(_itemFor(id).label)],
              ),
            ]),
          ),
      ]),
    );
  }
}
