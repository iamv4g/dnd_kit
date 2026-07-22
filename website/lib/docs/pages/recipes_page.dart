import 'package:jaspr/jaspr.dart';

import '../code_tabs.dart';
import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/recipes`
class RecipesPage extends StatelessComponent {
  const RecipesPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'recipes',
      toc: const [
        (id: 'scroll-view', label: 'Sortable inside a scroll view'),
        (id: 'drop-on-over', label: 'Drop where the highlight is'),
        (id: 'placeholder', label: 'A placeholder gap'),
        (id: 'nested', label: 'Nested or parallel sortables'),
      ],
      body: [
        docLead(
          'Four patterns that come up in production drag-and-drop UIs, with '
          'the parts dnd_kit handles for you and the parts your app still '
          'owns.',
        ),
        youWillLearn(const [
          'What sortables inside a scrolling list need (and no longer need).',
          'How to make the committed drop match the drop-target highlight.',
          'How to open a web-style placeholder gap without losing the preview.',
          'How to run two sortable surfaces on one controller.',
        ]),
        docSection(
          id: 'scroll-view',
          title: 'Sortable inside a scroll view',
          children: [
            docProse(
              'Scrolling moves your items without laying them out again, so a '
              'measurement taken when a target was first built no longer '
              'describes where it is. dnd_kit handles this for you in the two '
              'places it happens.',
            ),
            docBullets(const [
              'Drag start re-measures everything, so a drag begun after any '
                  'amount of scrolling aims at the targets you can actually '
                  'see.',
              'Auto-scroll re-measures on every tick and re-resolves the drop '
                  'target, so the highlight keeps up while content moves under '
                  'a stationary pointer.',
            ]),
            docProseRich([
              docText('That leaves one thing for you: wrap the scrolling '
                  'region in '),
              inlineCode('DndAutoScroll'),
              docText(' so a drag can reach items that are off-screen. If you '
                  'move the viewport yourself mid-drag — an outer page scroll, '
                  'say — call '),
              inlineCode('controller.measuring.markAllDirty()'),
              docText(' afterwards.'),
            ]),
            const CodeTabs(
              flutterFile: 'sortable_in_scroll_view.dart',
              jasprFile: 'sortable_in_scroll_view.dart',
              flutter: _scrollFlutter,
              jaspr: _scrollJaspr,
            ),
          ],
        ),
        docSection(
          id: 'drop-on-over',
          title: 'Drop where the highlight is',
          children: [
            docProseRich([
              inlineCode('isOver'),
              docText(' reports the collision result — the item the drag is '
                  'over right now. The default strategies resolve the drop '
                  'from the dragged rectangle\'s center instead, which does '
                  'not commit until that center crosses a neighbour\'s center. '
                  'If your UI lights up a target or opens a gap, those two '
                  'signals will visibly disagree.'),
            ]),
            docProseRich([
              docText('Use '),
              inlineCode('SortableStrategies.dropOnOver'),
              docText(' to land the move on whatever is highlighted. On a '
                  'multi-container board, set it per container area — '),
              inlineCode('SortableMultiContainerArea'),
              docText(' takes a '),
              inlineCode('strategy'),
              docText(' just like '),
              inlineCode('SortableScope'),
              docText(' does.'),
            ]),
            const CodeTabs(
              flutterFile: 'drop_on_over.dart',
              jasprFile: 'drop_on_over.dart',
              flutter: _dropOnOverFlutter,
              jaspr: _dropOnOverJaspr,
            ),
          ],
        ),
        docSection(
          id: 'placeholder',
          title: 'A placeholder gap',
          children: [
            docProse(
              'dnd_kit does not shift neighbours or draw a gap for you: it '
              'reports what is happening and your app renders it. The gap is '
              'three small pieces.',
            ),
            docBullets(const [
              'Collapse the source slot for the item being dragged, so the '
                  'list closes up behind it.',
              'Insert a keyed spacer next to the current drop target — below '
                  'it when dragging downward, above it when dragging upward.',
              'Pair it with dropOnOver so the item lands in the gap the user '
                  'is looking at.',
            ]),
            docProseRich([
              docText('The drag preview is sized from the rectangle measured '
                  'at drag start ('),
              inlineCode('initialActiveRect'),
              docText('), not the live one, so collapsing the source cannot '
                  'shrink it away.'),
            ]),
            docCodeBlock('placeholder_gap.dart', _placeholderFlutter),
          ],
        ),
        docSection(
          id: 'nested',
          title: 'Nested or parallel sortables',
          children: [
            docProse(
              'Two sortable surfaces on one screen — reorderable sections that '
              'each contain reorderable rows — need to share one controller, '
              'because the inner scope would otherwise shadow the outer one '
              'and each drag would only see half the picture.',
            ),
            docBullets(const [
              'Give the shared controller to both scopes.',
              'Namespace ids by kind so a section and a row can never collide.',
              'Scope collisions by kind: a section drag should ignore the rows '
                  'nested inside a section it is passing over.',
            ]),
            docProseRich([
              docText('The detector gets the dragged item as '),
              inlineCode('DndCollisionInput.activeId'),
              docText(', which is what makes kind-scoping possible. The active '
                  'item is already excluded from the candidates, so you only '
                  'filter for kind.'),
            ]),
            docCodeBlock('nested_scopes.dart', _nestedFlutter),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Sortable lists',
            desc: 'The base sortable surface these recipes build on.',
            href: docHref('sortable'),
          ),
          NextStep(
            label: 'Collision detection',
            desc: 'How targets are ranked, and how to write your own detector.',
            href: docHref('collision'),
          ),
        ]),
      ],
    );
  }
}

const _scrollFlutter = '''DndAutoScroll(
  child: CustomScrollView(
    slivers: [
      for (final day in days)
        SliverList.list(children: sectionsFor(day)),
    ],
  ),
)''';

const _scrollJaspr = '''DndAutoScroll(
  classes: 'max-h-[70vh] overflow-auto',
  child: div([
    for (final day in days) daySection(day),
  ]),
)''';

const _dropOnOverFlutter = '''SortableScope(
  itemIds: sections.map((s) => DndId(s.id)),
  strategy: SortableStrategies.dropOnOver,
  onMove: applyMove,
  child: ListView(children: sectionCards),
)

// On a board, set it per container area:
SortableMultiContainerArea(
  id: DndId(column.id),
  itemIds: column.cardIds,
  strategy: SortableStrategies.dropOnOver,
  child: columnBody,
)''';

const _dropOnOverJaspr = '''SortableScope(
  itemIds: sections.map((s) => DndId(s.id)),
  strategy: SortableStrategies.dropOnOver,
  onMove: applyMove,
  child: div(sectionCards),
)''';

const _placeholderFlutter = '''ListenableBuilder(
  listenable: controller,
  builder: (context, _) {
    final activeId = controller.activeId;
    final overId = controller.overId;

    return Column(
      children: [
        for (final item in items) ...[
          // The gap opens above the target when dragging upward.
          if (overId == DndId(item.id) && draggingUpward)
            SizedBox(key: const ValueKey('gap'), height: gapHeight),

          // The dragged item's own slot collapses.
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              height: activeId == DndId(item.id) ? 0 : null,
              child: ItemCard(item),
            ),
          ),

          if (overId == DndId(item.id) && !draggingUpward)
            SizedBox(key: const ValueKey('gap'), height: gapHeight),
        ],
      ],
    );
  },
)''';

const _nestedFlutter = '''// One controller, shared by both scopes.
final controller = DndController(
  collisionDetector: (input) {
    final activeId = input.activeId;
    if (activeId == null) return DndCollisionDetectors.closestCenter(input);

    // Only rank candidates of the same kind as the dragged item.
    final prefix = activeId.value.split(':').first;
    final sameKind = <DndId, DndRect>{
      for (final entry in input.droppableRects.entries)
        if (entry.key.value.startsWith('\$prefix:')) entry.key: entry.value,
    };

    return DndCollisionDetectors.compose(const [
      DndCollisionDetectors.pointerWithin,
      DndCollisionDetectors.rectIntersection,
    ])(DndCollisionInput(
      activeRect: input.activeRect,
      droppableRects: sameKind,
      pointer: input.pointer,
      activeId: activeId,
    ));
  },
);

// Ids carry their kind: DndId('section:2'), DndId('row:17').''';
