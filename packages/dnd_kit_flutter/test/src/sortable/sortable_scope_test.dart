import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SortableScopeData.resolveDetails', () {
    final scope = SortableScopeData(
      containerId: const DndId('list-1'),
      strategy: SortableStrategies.verticalList,
      itemIds: const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
    );
    final itemRects = <DndId, DndRect>{
      const DndId('item-1'): const DndRect(left: 0, top: 0, width: 100, height: 40),
      const DndId('item-2'): const DndRect(left: 0, top: 40, width: 100, height: 40),
      const DndId('item-3'): const DndRect(left: 0, top: 80, width: 100, height: 40),
    };
    final session = DndDragSession.start(
      activeId: const DndId('item-1'),
      initialPointer: const DndPoint(50, 20),
    ).moveTo(const DndPoint(50, 105));

    test('resolves a preview identically to the committed move', () {
      final preview = scope.resolveDetails(
        SortableDragContext.preview(session: session, overId: const DndId('item-3')),
        itemRects: itemRects,
        activeRect: itemRects[const DndId('item-1')],
      );
      final commit = scope.moveDetailsFor(
        DndDragEndEvent(session: session, overId: const DndId('item-3')),
        itemRects: itemRects,
        activeRect: itemRects[const DndId('item-1')],
      );

      expect(preview?.toIndex, commit?.toIndex);
      expect(preview?.fromIndex, commit?.fromIndex);
      expect(preview?.overId, commit?.overId);
      expect(preview?.event, isNull);
      expect(commit?.event, isNotNull);
    });

    test('reports no preview when the drag is over itself', () {
      final preview = scope.resolveDetails(
        SortableDragContext.preview(session: session, overId: const DndId('item-1')),
        itemRects: itemRects,
      );

      expect(preview, isNull);
    });
  });

  group('SortableScope preview', () {
    Widget harness({
      required DndController controller,
      required List<DndId> itemIds,
      required SortableStrategy strategy,
      required void Function(SortableItemDetails) onItemBuild,
      SortableMoveCallback? onMove,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SortableScope(
          controller: controller,
          itemIds: itemIds,
          strategy: strategy,
          onMove: onMove,
          child: Column(
            children: <Widget>[
              for (final id in itemIds)
                SortableItem(
                  id: id,
                  builder: (context, details, child) {
                    onItemBuild(details);
                    return child;
                  },
                  child: SizedBox(key: ValueKey<String>(id.value), height: 40, width: 100),
                ),
            ],
          ),
        ),
      );
    }

    /// Starts a mouse drag, which activates immediately; the touch default
    /// waits for a hold so it can coexist with scrolling.
    Future<TestGesture> startDrag(WidgetTester tester, String fromKey) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey<String>(fromKey))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      return gesture;
    }

    testWidgets('reports nothing while no drag is active', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final seen = <SortableItemDetails>[];

      await tester.pumpWidget(
        harness(
          controller: controller,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
          strategy: SortableStrategies.dropOnOver,
          onItemBuild: seen.add,
        ),
      );

      expect(seen, isNotEmpty);
      expect(seen.every((details) => details.previewIndex == null), isTrue);
      expect(seen.every((details) => details.previewContainerId == null), isTrue);
    });

    testWidgets('publishes the index the drop will commit to', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      SortableMoveDetails? committed;
      final seen = <SortableItemDetails>[];

      await tester.pumpWidget(
        harness(
          controller: controller,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
          strategy: SortableStrategies.dropOnOver,
          onItemBuild: seen.add,
          onMove: (details) => committed = details,
        ),
      );
      await tester.pump();

      final gesture = await startDrag(tester, 'item-1');
      seen.clear();
      await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey<String>('item-3'))));
      await tester.pump();

      final previewAtRelease = seen.map((details) => details.previewIndex).toSet();

      await gesture.up();
      await tester.pump();

      expect(previewAtRelease, <int?>{2}, reason: 'every item reads the same preview');
      expect(committed?.toIndex, 2);
      expect(
        previewAtRelease.single,
        committed?.toIndex,
        reason: 'the preview shown at release must equal the committed move',
      );
    });

    testWidgets('resolves once per move no matter how many items read it', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      var resolutions = 0;
      final itemIds = <DndId>[
        for (var index = 0; index < 6; index += 1) DndId('item-$index'),
      ];

      SortableMoveDetails? countingStrategy(SortableStrategyInput input) {
        resolutions += 1;
        return SortableStrategies.dropOnOver(input);
      }

      final reads = <int?>[];
      await tester.pumpWidget(
        harness(
          controller: controller,
          itemIds: itemIds,
          strategy: countingStrategy,
          onItemBuild: (details) => reads.add(details.previewIndex),
        ),
      );
      await tester.pump();

      final gesture = await startDrag(tester, 'item-0');
      reads.clear();
      resolutions = 0;
      await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey<String>('item-4'))));
      await tester.pump();

      expect(reads.length, itemIds.length, reason: 'every item read the preview');
      expect(reads.toSet(), <int?>{4});
      expect(
        resolutions,
        1,
        reason: 'the cache must collapse those reads into a single resolution',
      );

      await gesture.up();
      await tester.pump();
    });
  });

  group('SortableScope offsets', () {
    const itemIds = <DndId>[
      DndId('item-0'),
      DndId('item-1'),
      DndId('item-2'),
      DndId('item-3'),
    ];

    Widget harness({
      required DndController controller,
      required SortableOffsetResolver offsetResolver,
      required void Function(SortableItemDetails) onItemBuild,
      bool applyOffset = false,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SortableScope(
          controller: controller,
          itemIds: itemIds,
          strategy: SortableStrategies.dropOnOver,
          offsetResolver: offsetResolver,
          child: Column(
            children: <Widget>[
              for (final id in itemIds)
                SortableItem(
                  id: id,
                  builder: (context, details, child) {
                    onItemBuild(details);
                    // Applying inside the builder keeps the shift below the
                    // measured box, which is what prevents feedback.
                    return applyOffset
                        ? Transform.translate(
                            offset: Offset(details.offset.x, details.offset.y),
                            child: child,
                          )
                        : child;
                  },
                  child: SizedBox(key: ValueKey<String>(id.value), height: 40, width: 100),
                ),
            ],
          ),
        ),
      );
    }

    Future<TestGesture> dragFromTo(WidgetTester tester, String from, String to) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey<String>(from))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(ValueKey<String>(to))));
      await tester.pump();
      return gesture;
    }

    testWidgets('reports zero offsets by default', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final seen = <SortableItemDetails>[];

      await tester.pumpWidget(
        harness(
          controller: controller,
          offsetResolver: SortableOffsets.none,
          onItemBuild: seen.add,
        ),
      );
      await tester.pump();

      seen.clear();
      final gesture = await dragFromTo(tester, 'item-0', 'item-2');

      expect(seen, isNotEmpty);
      expect(seen.every((details) => details.offset == DndPoint.zero), isTrue);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('shifts the items the move displaces', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final offsets = <DndId, DndPoint>{};

      await tester.pumpWidget(
        harness(
          controller: controller,
          offsetResolver: SortableOffsets.verticalList,
          onItemBuild: (details) => offsets[details.id] = details.offset,
        ),
      );
      await tester.pump();

      offsets.clear();
      final gesture = await dragFromTo(tester, 'item-0', 'item-2');

      // item-0 moves to index 2, so item-1 and item-2 rise one 40pt slot and
      // item-3 keeps its place.
      expect(offsets[const DndId('item-1')], const DndPoint(0, -40));
      expect(offsets[const DndId('item-2')], const DndPoint(0, -40));
      expect(offsets[const DndId('item-3')], DndPoint.zero);
      expect(offsets[const DndId('item-0')], DndPoint.zero);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('resolves offsets once per move', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      var resolutions = 0;
      final reads = <DndPoint>[];

      Map<DndId, DndPoint> countingResolver(SortableOffsetInput input) {
        resolutions += 1;
        return SortableOffsets.verticalList(input);
      }

      await tester.pumpWidget(
        harness(
          controller: controller,
          offsetResolver: countingResolver,
          onItemBuild: (details) => reads.add(details.offset),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('item-0'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      reads.clear();
      resolutions = 0;
      await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey<String>('item-2'))));
      await tester.pump();

      expect(reads.length, itemIds.length);
      expect(resolutions, 1, reason: 'every item read one shared resolution');

      await gesture.up();
      await tester.pump();
    });

    testWidgets('applying offsets does not disturb collision', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final seenOver = <DndId?>[];

      await tester.pumpWidget(
        harness(
          controller: controller,
          offsetResolver: SortableOffsets.verticalList,
          onItemBuild: (details) {},
          applyOffset: true,
        ),
      );
      await tester.pump();

      final gesture = await dragFromTo(tester, 'item-0', 'item-2');
      seenOver.add(controller.overId);

      // Hold still across several frames: with the offsets applied, a
      // measurement feedback loop would show up as overId oscillating.
      for (var frame = 0; frame < 5; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        seenOver.add(controller.overId);
      }

      expect(seenOver.toSet(), <DndId?>{const DndId('item-2')});

      // The measured rect of a shifted item must still describe its unshifted
      // slot, so the box below it stays where collision expects it. item-1 is
      // rendered 40pt higher, but its measured top must remain 40.
      expect(
        controller.measuring.droppableRect(const DndId('item-1'))?.top,
        40,
        reason: 'a builder-applied offset sits below the measured box',
      );

      await gesture.up();
      await tester.pump();
    });
  });

  group('SortableScope', () {
    testWidgets('provides immutable item order and the underlying controller', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      SortableScopeData? capturedScope;
      DndController? capturedController;

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          containerId: const DndId('list-1'),
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          child: Builder(
            builder: (context) {
              capturedScope = SortableScope.of(context);
              capturedController = DndScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedController, same(controller));
      expect(capturedScope?.containerId, const DndId('list-1'));
      expect(capturedScope?.itemIds, const <DndId>[DndId('item-1'), DndId('item-2')]);
      expect(
        () => capturedScope?.itemIds.add(const DndId('item-3')),
        throwsUnsupportedError,
      );
    });

    testWidgets('returns null from maybeOf when no scope exists', (tester) async {
      SortableScopeData? capturedScope;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedScope = SortableScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(capturedScope, isNull);
    });

    testWidgets('throws from of when no scope exists', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      );

      expect(
        () => SortableScope.of(capturedContext),
        throwsA(
          isA<FlutterError>().having(
            (error) => error.toString(),
            'message',
            contains('SortableScope.of() was called without a SortableScope'),
          ),
        ),
      );
    });
  });
}
