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
              docText(
                'That leaves one thing for you: wrap the scrolling '
                'region in ',
              ),
              inlineCode('DndAutoScroll'),
              docText(
                ' so a drag can reach items that are off-screen. If you '
                'move the viewport yourself mid-drag — an outer page scroll, '
                'say — call ',
              ),
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
              docText(
                ' reports the collision result — the item the drag is '
                'over right now. The default strategies resolve the drop '
                'from the dragged rectangle\'s center instead, which does '
                'not commit until that center crosses a neighbour\'s center. '
                'If your UI lights up a target or opens a gap, those two '
                'signals will visibly disagree.',
              ),
            ]),
            docProseRich([
              docText('Use '),
              inlineCode('SortableStrategies.dropOnOver'),
              docText(
                ' to land the move on whatever is highlighted. On a '
                'multi-container board, set it per container area — ',
              ),
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
            docProseRich([
              docText(
                'dnd_kit computes the geometry; your app renders it. Set '
                'an ',
              ),
              inlineCode('offsetResolver'),
              docText(' on the scope and each item builder receives an '),
              inlineCode('offset'),
              docText(
                ' telling it how far to move so the dragged item has '
                'somewhere to land. The library never animates: you choose '
                'the animation, or none.',
              ),
            ]),
            docBullets(const [
              'Apply the offset inside the item builder, not around the item. '
                  'The builder sits below the measured box, so the shift '
                  'cannot move a measured rectangle and feed back into '
                  'collision.',
              'Pair it with dropOnOver so the item lands in the gap the user '
                  'is looking at.',
              'Hide the dragged row in place — the floating copy lives in the '
                  'overlay — but keep its slot. The neighbours slide over that '
                  'slot, leaving one clean gap.',
              'Read previewIndex when you want the landing index itself — for '
                  'a label, a counter, or an announcement.',
            ]),
            const CodeTabs(
              flutterFile: 'placeholder_gap.dart',
              jasprFile: 'placeholder_gap.dart',
              flutter: _placeholderFlutter,
              jaspr: _placeholderJaspr,
            ),
            docProseRich([
              docText(
                'Hide the source row rather than collapsing its height. '
                'The offsets shift the neighbours by the row\'s full extent '
                'to reclaim its slot; if you also collapsed the slot, the '
                'layout would reclaim that space a second time and the rows '
                'would overshoot. If you are building a gap by hand without '
                'the offset resolver and do collapse the source, the drag '
                'preview is sized from ',
              ),
              inlineCode('initialActiveRect'),
              docText(
                ', the drag-start rectangle, so the floating copy still '
                'survives the collapse.',
              ),
            ]),
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
              docText(
                ', which is what makes kind-scoping possible. The active '
                'item is already excluded from the candidates, so you only '
                'filter for kind.',
              ),
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

const _placeholderFlutter = '''SortableScope(
  itemIds: items.map((item) => DndId(item.id)),
  strategy: SortableStrategies.dropOnOver,
  offsetResolver: SortableOffsets.verticalList,
  onMove: applyMove,
  child: ListView(
    children: [
      for (final item in items)
        SortableItem(
          id: DndId(item.id),
          builder: (context, details, child) {
            // Applied inside the builder, so the shift stays below the
            // measured box.
            return AnimatedSlide(
              duration: const Duration(milliseconds: 150),
              offset: Offset(
                details.offset.x / itemWidth,
                details.offset.y / itemHeight,
              ),
              child: child,
            );
          },
          child: ItemCard(item),
        ),
    ],
  ),
)''';

const _placeholderJaspr = '''SortableScope(
  itemIds: items.map((item) => DndId(item.id)),
  strategy: SortableStrategies.dropOnOver,
  offsetResolver: SortableOffsets.verticalList,
  onMove: applyMove,
  child: div([
    for (final item in items)
      SortableItem(
        id: DndId(item.id),
        builder: (context, details, child) => div(
          styles: Styles(
            transform: Transform.translate(
              x: details.offset.x.px,
              y: details.offset.y.px,
            ),
            transition: Transition('transform', duration: 150),
          ),
          [child],
        ),
        child: itemCard(item),
      ),
  ]),
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
