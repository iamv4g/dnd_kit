import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SortableMultiScope', () {
    testWidgets('provides immutable container metadata and a drag controller', (
      tester,
    ) async {
      SortableMultiScopeData? capturedScope;
      DndController? capturedController;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SortableMultiScope(
            containers: <SortableContainer>[
              SortableContainer(
                id: const DndId('todo'),
                itemIds: const <DndId>[DndId('task-1')],
              ),
            ],
            onMove: (_) {},
            child: Builder(
              builder: (context) {
                capturedScope = SortableMultiScope.of(context);
                capturedController = DndScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedController, isNotNull);
      expect(capturedScope?.containers.single.id, const DndId('todo'));
      expect(
        () => capturedScope?.containers.add(
          SortableContainer(
            id: const DndId('done'),
            itemIds: const <DndId>[],
          ),
        ),
        throwsUnsupportedError,
      );
    });

    testWidgets('reports cross-container moves without manual drag-end wiring', (
      tester,
    ) async {
      final moves = <SortableMoveDetails>[];
      final containers = <SortableContainer>[
        SortableContainer(
          id: const DndId('todo'),
          itemIds: const <DndId>[DndId('task-1')],
        ),
        SortableContainer(
          id: const DndId('done'),
          itemIds: const <DndId>[DndId('task-2')],
        ),
      ];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 260,
            height: 140,
            child: SortableMultiScope(
              containers: containers,
              onMove: moves.add,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    child: SortableMultiContainerArea(
                      id: const DndId('todo'),
                      itemIds: const <DndId>[DndId('task-1')],
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          children: const <Widget>[
                            Positioned(
                              left: 0,
                              top: 0,
                              child: SortableMultiItem(
                                id: DndId('task-1'),
                                child: SizedBox(width: 80, height: 40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 140,
                    top: 0,
                    child: SortableMultiContainerArea(
                      id: const DndId('done'),
                      itemIds: const <DndId>[DndId('task-2')],
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          children: const <Widget>[
                            Positioned(
                              left: 0,
                              top: 0,
                              child: SortableMultiItem(
                                id: DndId('task-2'),
                                child: SizedBox(width: 80, height: 40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.dragFrom(
        const Offset(40, 20),
        const Offset(140, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      expect(moves, hasLength(1));
      expect(
        moves.single,
        isA<SortableMoveDetails>()
            .having((details) => details.activeId, 'activeId', const DndId('task-1'))
            .having((details) => details.overId, 'overId', const DndId('task-2'))
            .having((details) => details.fromContainerId, 'fromContainerId', const DndId('todo'))
            .having((details) => details.toContainerId, 'toContainerId', const DndId('done'))
            .having((details) => details.fromIndex, 'fromIndex', 0)
            .having((details) => details.toIndex, 'toIndex', 0),
      );
    });
  });

  group('SortableMultiScope offsets', () {
    // Two columns side by side, three cards each, stacked vertically.
    Widget boardHarness({
      required DndController controller,
      required void Function(DndId, SortableItemDetails) onItemBuild,
      SortableMoveCallback? onMove,
    }) {
      const todo = <DndId>[DndId('t0'), DndId('t1'), DndId('t2')];
      const done = <DndId>[DndId('d0'), DndId('d1'), DndId('d2')];
      final containers = <SortableContainer>[
        SortableContainer(id: const DndId('todo'), itemIds: todo),
        SortableContainer(id: const DndId('done'), itemIds: done),
      ];

      Widget column(DndId id, List<DndId> ids, double left) {
        return Positioned(
          left: left,
          top: 0,
          width: 120,
          height: 200,
          child: SortableMultiContainerArea(
            id: id,
            itemIds: ids,
            strategy: SortableStrategies.dropOnOver,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final itemId in ids)
                  SortableMultiItem(
                    id: itemId,
                    builder: (context, details, child) {
                      onItemBuild(itemId, details);
                      return child;
                    },
                    child: SizedBox(
                      key: ValueKey<String>(itemId.value),
                      width: 120,
                      height: 40,
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 300,
          height: 200,
          child: SortableMultiScope(
            controller: controller,
            containers: containers,
            offsetResolver: SortableMultiOffsets.verticalLists,
            onMove: onMove ?? (_) {},
            child: Stack(
              children: <Widget>[
                column(const DndId('todo'), todo, 0),
                column(const DndId('done'), done, 160),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('shifts a column tail for a same-column move', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final offsets = <DndId, DndPoint>{};

      await tester.pumpWidget(
        boardHarness(
          controller: controller,
          onItemBuild: (id, details) => offsets[id] = details.offset,
        ),
      );
      await tester.pump();

      offsets.clear();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('t0'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey<String>('t2'))));
      await tester.pump();

      // t1 and t2 rise to make room; the done column is untouched.
      expect(offsets[const DndId('t1')]?.y, lessThan(0));
      expect(offsets[const DndId('t2')]?.y, lessThan(0));
      expect(offsets[const DndId('d0')], DndPoint.zero);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('closes the source and opens the target across columns', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      SortableMoveDetails? committed;
      final offsets = <DndId, DndPoint>{};

      await tester.pumpWidget(
        boardHarness(
          controller: controller,
          onItemBuild: (id, details) => offsets[id] = details.offset,
          onMove: (details) => committed = details,
        ),
      );
      await tester.pump();

      offsets.clear();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('t0'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      // Drag onto the first card of the done column.
      await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey<String>('d0'))));
      await tester.pump();

      // Source column closes: cards after t0 rise.
      expect(offsets[const DndId('t1')]?.y, lessThan(0));
      expect(offsets[const DndId('t2')]?.y, lessThan(0));
      // Target column opens: the hovered card and those after it drop.
      expect(offsets[const DndId('d0')]?.y, greaterThan(0));

      await gesture.up();
      await tester.pump();

      expect(committed?.toContainerId, const DndId('done'));
    });

    testWidgets('offsets are zero without a resolver', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      const todo = <DndId>[DndId('t0'), DndId('t1')];
      final offsets = <DndId, DndPoint>{};

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 200,
            child: SortableMultiScope(
              controller: controller,
              containers: <SortableContainer>[
                SortableContainer(id: const DndId('todo'), itemIds: todo),
              ],
              onMove: (_) {},
              child: SortableMultiContainerArea(
                id: const DndId('todo'),
                itemIds: todo,
                strategy: SortableStrategies.dropOnOver,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final id in todo)
                      SortableMultiItem(
                        id: id,
                        builder: (context, details, child) {
                          offsets[id] = details.offset;
                          return child;
                        },
                        child: SizedBox(key: ValueKey<String>(id.value), width: 120, height: 40),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('t0'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey<String>('t1'))));
      await tester.pump();

      expect(offsets.values.every((offset) => offset == DndPoint.zero), isTrue);

      await gesture.up();
      await tester.pump();
    });
  });

  group('SortableMultiScope preview', () {
    Widget singleAreaHarness({
      required SortableStrategy strategy,
      required void Function(SortableItemDetails) onItemBuild,
      SortableMoveCallback? onMove,
    }) {
      const itemIds = <DndId>[DndId('task-1'), DndId('task-2'), DndId('task-3')];
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 200,
          child: SortableMultiScope(
            containers: <SortableContainer>[
              SortableContainer(id: const DndId('todo'), itemIds: itemIds),
            ],
            onMove: onMove ?? (_) {},
            child: SortableMultiContainerArea(
              id: const DndId('todo'),
              itemIds: itemIds,
              strategy: strategy,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final id in itemIds)
                    SortableMultiItem(
                      id: id,
                      builder: (context, details, child) {
                        onItemBuild(details);
                        return child;
                      },
                      child: SizedBox(
                        key: ValueKey<String>(id.value),
                        width: 120,
                        height: 40,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('resolves the preview with the source area strategy', (tester) async {
      final seen = <SortableItemDetails>[];

      await tester.pumpWidget(
        singleAreaHarness(
          // dropOnOver commits at the hovered item; verticalList would report
          // no move until the dragged center crosses the neighbour's center.
          strategy: SortableStrategies.dropOnOver,
          onItemBuild: seen.add,
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('task-1'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      seen.clear();
      // Just inside task-2, short of its center.
      await gesture.moveTo(
        tester.getTopLeft(find.byKey(const ValueKey<String>('task-2'))) + const Offset(60, 5),
      );
      await tester.pump();

      expect(
        seen.map((details) => details.previewIndex).toSet(),
        <int?>{1},
        reason: 'the registered dropOnOver strategy must drive the preview',
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('publishes nothing when the area uses a center-crossing strategy', (tester) async {
      final seen = <SortableItemDetails>[];

      await tester.pumpWidget(
        singleAreaHarness(
          strategy: SortableStrategies.verticalList,
          onItemBuild: seen.add,
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('task-1'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      seen.clear();
      await gesture.moveTo(
        tester.getTopLeft(find.byKey(const ValueKey<String>('task-2'))) + const Offset(60, 5),
      );
      await tester.pump();

      expect(
        seen.map((details) => details.previewIndex).toSet(),
        <int?>{null},
        reason: 'verticalList has not crossed the neighbour center yet',
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('preview matches the committed cross-container move', (tester) async {
      final moves = <SortableMoveDetails>[];
      final seen = <SortableItemDetails>[];
      final containers = <SortableContainer>[
        SortableContainer(id: const DndId('todo'), itemIds: const <DndId>[DndId('task-1')]),
        SortableContainer(id: const DndId('done'), itemIds: const <DndId>[DndId('task-2')]),
      ];

      Widget area(DndId id, DndId itemId, double left) {
        return Positioned(
          left: left,
          top: 0,
          child: SortableMultiContainerArea(
            id: id,
            itemIds: <DndId>[itemId],
            child: SizedBox(
              width: 120,
              height: 120,
              child: SortableMultiItem(
                id: itemId,
                builder: (context, details, child) {
                  seen.add(details);
                  return child;
                },
                child: SizedBox(key: ValueKey<String>(itemId.value), width: 80, height: 40),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 260,
            height: 140,
            child: SortableMultiScope(
              containers: containers,
              onMove: moves.add,
              child: Stack(
                children: <Widget>[
                  area(const DndId('todo'), const DndId('task-1'), 0),
                  area(const DndId('done'), const DndId('task-2'), 140),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        const Offset(40, 20),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      seen.clear();
      await gesture.moveTo(const Offset(180, 20));
      await tester.pump();

      final previewAtRelease = seen.map((details) => details.previewIndex).toSet();
      final previewContainers = seen.map((details) => details.previewContainerId).toSet();

      await gesture.up();
      await tester.pump();

      expect(moves, hasLength(1));
      expect(previewContainers, <DndId?>{const DndId('done')});
      expect(
        previewAtRelease.single,
        moves.single.toIndex,
        reason: 'the preview shown at release must equal the committed move',
      );
    });
  });
}
