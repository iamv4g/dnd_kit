import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import 'planner_model.dart';

/// A nested-sortable planner: days with sticky headers, sections that reorder
/// within a day, and items that drag across sections (and across days).
///
/// Two sortable surfaces share one controller: a per-day [SortableScope]
/// reorders sections, and one board-wide [SortableMultiScope] moves items
/// between sections. A kind-scoped collision detector keeps a section drag from
/// resolving to an item and vice versa.
class PlannerDemo extends StatefulWidget {
  const PlannerDemo({super.key});

  @override
  State<PlannerDemo> createState() => _PlannerDemoState();
}

class _PlannerDemoState extends State<PlannerDemo> {
  final PlannerBoard _board = PlannerBoard.demo();

  late final DndController _controller = DndController();

  // Read live via closures so reorders are reflected without rebuilding it.
  late final DndCollisionDetector _detector = _plannerCollisionDetector(
    sectionContainers: () => _sectionContainers,
  );

  // Each section is a container of items for the board-wide item scope.
  List<SortableContainer> get _sectionContainers => [
        for (final day in _board.days)
          for (final sectionId in day.sectionIds)
            SortableContainer(
              id: DndId(PlannerIds.sectionContainer(sectionId)),
              itemIds: [
                for (final itemId in _board.sections[sectionId]!.itemIds)
                  DndId(PlannerIds.item(itemId)),
              ],
            ),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSectionMove(String dayId, SortableMoveDetails move) {
    setState(() {
      _board.reorderSection(
        dayId: dayId,
        fromIndex: move.fromIndex,
        toIndex: move.toIndex,
      );
    });
  }

  void _onItemMove(SortableMoveDetails move) {
    final fromSection = move.fromContainerId;
    final toSection = move.toContainerId;
    if (fromSection == null || toSection == null) {
      return;
    }
    setState(() {
      _board.moveItem(
        fromSectionId: PlannerIds.decode(fromSection.value),
        fromIndex: move.fromIndex,
        toSectionId: PlannerIds.decode(toSection.value),
        toIndex: move.toIndex,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SortableMultiScope(
      controller: _controller,
      collisionDetector: _detector,
      containers: _sectionContainers,
      offsetResolver: SortableMultiOffsets.verticalLists,
      onMove: _onItemMove,
      child: Scaffold(
        appBar: AppBar(title: const Text('Planner (nested sortables)')),
        body: Stack(
          children: [
            DndAutoScroll(
              controller: _controller,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _Intro()),
                  for (final day in _board.days) ..._daySlivers(day),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
            DndDragOverlay(
              controller: _controller,
              builder: (context, details) =>
                  _overlayFor(context, details.activeId),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _daySlivers(PlannerDay day) {
    final scheme = Theme.of(context).colorScheme;
    return [
      SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _DayHeaderDelegate(title: day.title, scheme: scheme),
          ),
          SliverToBoxAdapter(child: _daySections(day)),
        ],
      ),
    ];
  }

  // A per-day section scope: sections reorder within their day.
  Widget _daySections(PlannerDay day) {
    return SortableScope(
      controller: _controller,
      containerId: DndId('day:${day.id}'),
      itemIds: [for (final id in day.sectionIds) DndId(PlannerIds.section(id))],
      strategy: SortableStrategies.dropOnOver,
      offsetResolver: SortableOffsets.verticalList,
      onMove: (move) => _onSectionMove(day.id, move),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          children: [
            for (final sectionId in day.sectionIds)
              _SectionCard(
                key: ValueKey('section-card:$sectionId'),
                section: _board.sections[sectionId]!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _overlayFor(BuildContext context, DndId activeId) {
    if (PlannerIds.isSection(activeId.value)) {
      final section = _board.sections[PlannerIds.decode(activeId.value)];
      if (section == null) return const SizedBox.shrink();
      return Material(
        color: Colors.transparent,
        child: _SectionHeaderCard(title: section.title, elevated: true),
      );
    }
    final item = _board.items[PlannerIds.decode(activeId.value)];
    if (item == null) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: _ItemFace(item: item, elevated: true),
    );
  }
}

/// Routes collisions by the dragged kind: a section drag ranks only sections,
/// an item drag ranks only the item scope (section containers + items).
DndCollisionDetector _plannerCollisionDetector({
  required List<SortableContainer> Function() sectionContainers,
}) {
  final itemDetector =
      SortableMultiContainer.collisionDetector(containers: sectionContainers);
  final sectionDetector = DndCollisionDetectors.compose(const [
    DndCollisionDetectors.pointerWithin,
    DndCollisionDetectors.rectIntersection,
  ]);

  DndCollisionInput scoped(
      DndCollisionInput input, bool Function(String) keep) {
    return DndCollisionInput(
      activeRect: input.activeRect,
      pointer: input.pointer,
      activeId: input.activeId,
      droppableRects: {
        for (final entry in input.droppableRects.entries)
          if (keep(entry.key.value)) entry.key: entry.value,
      },
    );
  }

  return (input) {
    final active = input.activeId;
    if (active != null && PlannerIds.isSection(active.value)) {
      return sectionDetector(scoped(input, PlannerIds.isSection));
    }
    return itemDetector(
      scoped(input,
          (v) => PlannerIds.isSectionContainer(v) || PlannerIds.isItem(v)),
    );
  };
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'Drag a section by its handle to reorder it within its day. Drag an '
        'item by its handle to move it between sections and days. Day headers '
        'stick while you scroll; each item keeps its own editable note.',
      ),
    );
  }
}

class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DayHeaderDelegate({required this.title, required this.scheme});

  final String title;
  final ColorScheme scheme;

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 44,
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_DayHeaderDelegate oldDelegate) {
    return oldDelegate.title != title || oldDelegate.scheme != scheme;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.section});

  final PlannerSection section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SortableItem(
      id: DndId(PlannerIds.section(section.id)),
      builder: (context, details, child) {
        // Hide the dragged section (floating copy is in the overlay) and slide
        // the others by the reported offset.
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, details.offset.y, 0),
          child: Opacity(opacity: details.isDragging ? 0 : 1, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeaderCard(
                title: section.title,
                handleKey: ValueKey('section-handle:${section.id}'),
              ),
              SortableMultiContainerArea(
                id: DndId(PlannerIds.sectionContainer(section.id)),
                itemIds: [
                  for (final id in section.itemIds) DndId(PlannerIds.item(id)),
                ],
                strategy: SortableStrategies.dropOnOver,
                builder: (context, details, child) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: details.isOver
                          ? scheme.primary.withValues(alpha: 0.06)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Column(
                    children: [
                      if (section.itemIds.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Drop an item here',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                      for (final itemId in section.itemIds)
                        _ItemCard(
                          key: ValueKey('item-card:$itemId'),
                          item: _boardItem(context, itemId),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PlannerItem _boardItem(BuildContext context, String id) {
    // The section only holds ids; the demo state owns the item data. Look it up
    // through the ancestor state.
    final state = context.findAncestorStateOfType<_PlannerDemoState>()!;
    return state._board.items[id]!;
  }
}

class _SectionHeaderCard extends StatelessWidget {
  const _SectionHeaderCard({
    required this.title,
    this.elevated = false,
    this.handleKey,
  });

  final String title;
  final bool elevated;
  final Key? handleKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: elevated
          ? BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.primary),
            )
          : null,
      child: Row(
        children: [
          DndDragHandle(
            key: handleKey,
            label: 'Reorder section $title',
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.drag_indicator,
                  size: 18, color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({super.key, required this.item});

  final PlannerItem item;

  @override
  Widget build(BuildContext context) {
    return SortableMultiItem(
      id: DndId(PlannerIds.item(item.id)),
      builder: (context, details, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, details.offset.y, 0),
          child: Opacity(opacity: details.isDragging ? 0 : 1, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _ItemFace(
          item: item,
          handleKey: ValueKey('item-handle:${item.id}'),
        ),
      ),
    );
  }
}

class _ItemFace extends StatelessWidget {
  const _ItemFace({required this.item, this.elevated = false, this.handleKey});

  final PlannerItem item;
  final bool elevated;
  final Key? handleKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: elevated ? scheme.primary : scheme.outlineVariant,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DndDragHandle(
            key: handleKey,
            label: 'Move item ${item.title}',
            child: const Padding(
              padding: EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Icon(Icons.drag_indicator, size: 18),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                _NoteField(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An editable note whose text survives reorders because its element is keyed
/// through the sortable item.
class _NoteField extends StatefulWidget {
  const _NoteField({required this.item});

  final PlannerItem item;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.item.note);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) => widget.item.note = value,
      style: Theme.of(context).textTheme.bodySmall,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Add a note…',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
