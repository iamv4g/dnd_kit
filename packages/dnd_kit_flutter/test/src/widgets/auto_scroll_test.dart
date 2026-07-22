import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndAutoScroll', () {
    testWidgets('scrolls down while dragging near the trailing edge', (tester) async {
      final controller = DndController();
      final scrollController = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
        ),
      );
      await tester.pump();

      _startDrag(
        controller,
        _pointNearTrailingEdge(tester, DndScrollAxis.vertical),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets('uses the first descendant scrollable when no scroll controller is provided',
        (tester) async {
      final controller = DndController();
      final scrollController = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
          useExplicitScrollController: false,
        ),
      );
      await tester.pump();

      _startDrag(
        controller,
        _pointNearTrailingEdge(tester, DndScrollAxis.vertical),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets('scrolls up while dragging near the leading edge', (tester) async {
      final controller = DndController();
      final scrollController = ScrollController(initialScrollOffset: 300);
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
        ),
      );
      await tester.pump();

      _startDrag(
        controller,
        _pointNearLeadingEdge(tester, DndScrollAxis.vertical),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, lessThan(300));
    });

    testWidgets('does not scroll when disabled', (tester) async {
      final controller = DndController();
      final scrollController = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
          enabled: false,
        ),
      );
      await tester.pump();

      _startDrag(
        controller,
        _pointNearTrailingEdge(tester, DndScrollAxis.vertical),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, 0);
    });

    testWidgets('stops when dragging ends', (tester) async {
      final controller = DndController();
      final scrollController = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
        ),
      );
      await tester.pump();

      _startDrag(
        controller,
        _pointNearTrailingEdge(tester, DndScrollAxis.vertical),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final offsetAfterDrag = scrollController.offset;

      controller.endDrag();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(offsetAfterDrag, greaterThan(0));
      expect(scrollController.offset, offsetAfterDrag);
    });

    testWidgets('does not exceed scroll extents', (tester) async {
      final controller = DndController();
      final scrollController = ScrollController(initialScrollOffset: 800);
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
        ),
      );
      await tester.pump();
      scrollController.jumpTo(scrollController.position.maxScrollExtent);

      _startDrag(
        controller,
        _pointNearTrailingEdge(tester, DndScrollAxis.vertical),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, scrollController.position.maxScrollExtent);
    });

    testWidgets('scrolls right while dragging near the trailing edge', (tester) async {
      final controller = DndController();
      final scrollController = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
          axis: DndScrollAxis.horizontal,
        ),
      );
      await tester.pump();

      _startDrag(
        controller,
        _pointNearTrailingEdge(tester, DndScrollAxis.horizontal),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets(
        'uses the first descendant horizontal scrollable when no scroll controller is provided',
        (tester) async {
      final controller = DndController();
      final scrollController = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
          axis: DndScrollAxis.horizontal,
          useExplicitScrollController: false,
        ),
      );
      await tester.pump();

      _startDrag(
        controller,
        _pointNearTrailingEdge(tester, DndScrollAxis.horizontal),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets('scrolls left while dragging near the leading edge', (tester) async {
      final controller = DndController();
      final scrollController = ScrollController(initialScrollOffset: 300);
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
          axis: DndScrollAxis.horizontal,
        ),
      );
      await tester.pump();

      _startDrag(
        controller,
        _pointNearLeadingEdge(tester, DndScrollAxis.horizontal),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, lessThan(300));
    });

    testWidgets('does not exceed horizontal scroll extents', (tester) async {
      final controller = DndController();
      final scrollController = ScrollController(initialScrollOffset: 800);
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
          axis: DndScrollAxis.horizontal,
        ),
      );
      await tester.pump();
      scrollController.jumpTo(scrollController.position.maxScrollExtent);

      _startDrag(
        controller,
        _pointNearTrailingEdge(tester, DndScrollAxis.horizontal),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, scrollController.position.maxScrollExtent);
    });

    testWidgets('re-measures droppables and updates overId on auto-scroll ticks', (tester) async {
      final controller = DndController();
      final scrollController = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _AutoScrollHarness(
          controller: controller,
          scrollController: scrollController,
          droppableItems: true,
        ),
      );
      await tester.pump();

      final pointer = _pointNearTrailingEdge(tester, DndScrollAxis.vertical);
      _startDrag(controller, pointer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      final offset = scrollController.offset;
      expect(offset, greaterThan(0));

      // Items are 50 tall; the stationary pointer must resolve to the item
      // that scrolled under it, not the one measured before scrolling.
      final expectedIndex = ((offset + pointer.y) / 50).floor();
      expect(controller.overId, DndId('item-$expectedIndex'));
    });

    testWidgets(
        'keeps the explicit horizontal controller when nested vertical auto-scrollables emit metrics',
        (tester) async {
      final controller = DndController();
      final boardScrollController = ScrollController();
      final columnScrollController = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(boardScrollController.dispose);
      addTearDown(columnScrollController.dispose);

      await tester.pumpWidget(
        _NestedAutoScrollHarness(
          controller: controller,
          boardScrollController: boardScrollController,
          columnScrollController: columnScrollController,
        ),
      );
      await tester.pump();

      _startDrag(
        controller,
        _pointNearTrailingEdgeByKey(
          tester,
          const ValueKey<String>('outer-board-list'),
          DndScrollAxis.horizontal,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(boardScrollController.offset, greaterThan(0));
      expect(columnScrollController.offset, 0);
    });
  });
}

void _startDrag(DndController controller, DndPoint position) {
  controller.beginDrag(
    DndSensorActivationEvent(
      activeId: const DndId('task-1'),
      position: position,
    ),
    activeRect: const DndRect(left: 20, top: 20, width: 40, height: 40),
  );
  controller.startDrag();
  controller.moveDrag(position);
}

DndPoint _pointNearTrailingEdge(WidgetTester tester, DndScrollAxis axis) {
  final rect = tester.getRect(find.byType(ListView));
  return switch (axis) {
    DndScrollAxis.vertical => DndPoint(rect.center.dx, rect.bottom - 10),
    DndScrollAxis.horizontal => DndPoint(rect.right - 10, rect.center.dy),
  };
}

DndPoint _pointNearLeadingEdge(WidgetTester tester, DndScrollAxis axis) {
  final rect = tester.getRect(find.byType(ListView));
  return switch (axis) {
    DndScrollAxis.vertical => DndPoint(rect.center.dx, rect.top + 10),
    DndScrollAxis.horizontal => DndPoint(rect.left + 10, rect.center.dy),
  };
}

DndPoint _pointNearTrailingEdgeByKey(
  WidgetTester tester,
  Key key,
  DndScrollAxis axis,
) {
  final rect = tester.getRect(find.byKey(key));
  return switch (axis) {
    DndScrollAxis.vertical => DndPoint(rect.center.dx, rect.bottom - 10),
    DndScrollAxis.horizontal => DndPoint(rect.right - 10, rect.center.dy),
  };
}

class _AutoScrollHarness extends StatelessWidget {
  const _AutoScrollHarness({
    required this.controller,
    required this.scrollController,
    this.enabled = true,
    this.axis = DndScrollAxis.vertical,
    this.useExplicitScrollController = true,
    this.droppableItems = false,
  });

  final DndController controller;
  final ScrollController scrollController;
  final bool enabled;
  final DndScrollAxis axis;
  final bool useExplicitScrollController;
  final bool droppableItems;

  @override
  Widget build(BuildContext context) {
    return DndScope(
      controller: controller,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 200,
          child: DndAutoScroll(
            enabled: enabled,
            axis: axis,
            scrollController: useExplicitScrollController ? scrollController : null,
            options: const DndAutoScrollOptions(
              edgeThreshold: 40,
              maxVelocity: 20,
            ),
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: axis == DndScrollAxis.horizontal ? Axis.horizontal : Axis.vertical,
              itemExtent: 50,
              itemCount: 20,
              itemBuilder: (context, index) {
                if (!droppableItems) {
                  return Text('item-$index');
                }

                return DndDroppable(
                  id: DndId('item-$index'),
                  child: Text('item-$index'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NestedAutoScrollHarness extends StatelessWidget {
  const _NestedAutoScrollHarness({
    required this.controller,
    required this.boardScrollController,
    required this.columnScrollController,
  });

  final DndController controller;
  final ScrollController boardScrollController;
  final ScrollController columnScrollController;

  @override
  Widget build(BuildContext context) {
    return DndScope(
      controller: controller,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 220,
          height: 220,
          child: DndAutoScroll(
            axis: DndScrollAxis.horizontal,
            scrollController: boardScrollController,
            options: const DndAutoScrollOptions(
              edgeThreshold: 40,
              maxVelocity: 20,
            ),
            child: ListView.builder(
              key: const ValueKey<String>('outer-board-list'),
              controller: boardScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 160,
                  child: index == 0
                      ? DndAutoScroll(
                          scrollController: columnScrollController,
                          options: const DndAutoScrollOptions(
                            edgeThreshold: 40,
                            maxVelocity: 20,
                          ),
                          child: ListView.builder(
                            controller: columnScrollController,
                            itemExtent: 48,
                            itemCount: 30,
                            itemBuilder: (context, itemIndex) {
                              return Text('nested-$itemIndex');
                            },
                          ),
                        )
                      : Text('column-$index'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
