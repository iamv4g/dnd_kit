import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SortableItem', () {
    testWidgets('registers and unregisters draggable and droppable metadata', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          itemIds: const <DndId>[DndId('item-1')],
          child: const SortableItem(
            id: DndId('item-1'),
            data: 'payload',
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(
        controller.registry.draggable(const DndId('item-1')),
        const DndDraggableRegistration(
          id: DndId('item-1'),
          data: 'payload',
        ),
      );
      expect(
        controller.registry.droppable(const DndId('item-1')),
        const DndDroppableRegistration(
          id: DndId('item-1'),
          data: 'payload',
        ),
      );

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          itemIds: const <DndId>[],
          child: const SizedBox(),
        ),
      );

      expect(controller.registry.hasDraggable(const DndId('item-1')), isFalse);
      expect(controller.registry.hasDroppable(const DndId('item-1')), isFalse);
    });

    testWidgets('keeps disabled items registered as disabled metadata', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          itemIds: const <DndId>[DndId('item-1')],
          child: const SortableItem(
            id: DndId('item-1'),
            disabled: true,
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(controller.registry.draggable(const DndId('item-1'))?.disabled, isTrue);
      expect(controller.registry.droppable(const DndId('item-1'))?.disabled, isTrue);
    });

    testWidgets('builder receives sortable visual state', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      SortableItemDetails? latestDetails;

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                child: SortableItem(
                  id: const DndId('item-1'),
                  builder: (context, details, child) {
                    latestDetails = details;
                    return Text(
                      'item:${details.index}:${details.isDragging}:${details.isOver}',
                      textDirection: TextDirection.ltr,
                    );
                  },
                  child: const SizedBox(width: 80, height: 80),
                ),
              ),
              const Positioned(
                left: 100,
                top: 0,
                child: SortableItem(
                  id: DndId('item-2'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('item:0:false:false'), findsOneWidget);
      expect(latestDetails?.id, const DndId('item-1'));

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('item-1'),
          position: DndPoint(10, 10),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 80, height: 80),
      );
      controller.startDrag();
      controller.moveDrag(const DndPoint(110, 10));
      await tester.pump();

      expect(latestDetails?.isDragging, isTrue);
      expect(latestDetails?.isActive, isTrue);
      expect(latestDetails?.index, 0);
    });

    testWidgets('reports move intent and leaves application order external', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final itemIds = <DndId>[
        const DndId('item-1'),
        const DndId('item-2'),
        const DndId('item-3'),
      ];
      final moves = <SortableMoveDetails>[];

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          containerId: const DndId('list-1'),
          itemIds: itemIds,
          onMove: moves.add,
          child: const Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                child: SortableItem(
                  id: DndId('item-1'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 100,
                top: 0,
                child: SortableItem(
                  id: DndId('item-2'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 200,
                top: 0,
                child: SortableItem(
                  id: DndId('item-3'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.dragFrom(const Offset(40, 40), const Offset(100, 0),
          kind: PointerDeviceKind.mouse);
      await tester.pump();

      expect(moves, hasLength(1));
      expect(
        moves.single,
        isA<SortableMoveDetails>()
            .having((details) => details.activeId, 'activeId', const DndId('item-1'))
            .having((details) => details.overId, 'overId', const DndId('item-2'))
            .having((details) => details.fromIndex, 'fromIndex', 0)
            .having((details) => details.toIndex, 'toIndex', 1)
            .having((details) => details.fromContainerId, 'fromContainerId', const DndId('list-1'))
            .having((details) => details.toContainerId, 'toContainerId', const DndId('list-1')),
      );
      expect(
        itemIds,
        const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
      );
    });

    testWidgets('uses the configured sortable strategy for move intent', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      SortableStrategyInput? latestInput;
      final moves = <SortableMoveDetails>[];

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          strategy: (input) {
            latestInput = input;
            return input.fallbackMoveDetails(toIndex: 0);
          },
          onMove: moves.add,
          child: const Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                child: SortableItem(
                  id: DndId('item-1'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 100,
                top: 0,
                child: SortableItem(
                  id: DndId('item-2'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.dragFrom(const Offset(40, 40), const Offset(100, 0),
          kind: PointerDeviceKind.mouse);
      await tester.pump();

      expect(latestInput?.activeId, const DndId('item-1'));
      expect(latestInput?.overId, const DndId('item-2'));
      expect(latestInput?.itemRects.keys, contains(const DndId('item-2')));
      expect(latestInput?.activeRect, isNotNull);
      expect(
        moves.single,
        isA<SortableMoveDetails>()
            .having((details) => details.fromIndex, 'fromIndex', 0)
            .having((details) => details.toIndex, 'toIndex', 0),
      );
    });

    testWidgets('can use the horizontal list strategy for move intent', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final moves = <SortableMoveDetails>[];

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
          strategy: SortableStrategies.horizontalList,
          onMove: moves.add,
          child: const Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                child: SortableItem(
                  id: DndId('item-1'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 100,
                top: 0,
                child: SortableItem(
                  id: DndId('item-2'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 200,
                top: 0,
                child: SortableItem(
                  id: DndId('item-3'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.dragFrom(const Offset(40, 40), const Offset(210, 0),
          kind: PointerDeviceKind.mouse);
      await tester.pump();

      expect(
        moves.single,
        isA<SortableMoveDetails>()
            .having((details) => details.fromIndex, 'fromIndex', 0)
            .having((details) => details.toIndex, 'toIndex', 2),
      );
    });

    testWidgets('can use the grid strategy for move intent', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final moves = <SortableMoveDetails>[];

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          itemIds: const <DndId>[
            DndId('item-1'),
            DndId('item-2'),
            DndId('item-3'),
            DndId('item-4'),
          ],
          strategy: SortableStrategies.grid,
          onMove: moves.add,
          child: const Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                child: SortableItem(
                  id: DndId('item-1'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 100,
                top: 0,
                child: SortableItem(
                  id: DndId('item-2'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 0,
                top: 100,
                child: SortableItem(
                  id: DndId('item-3'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 100,
                top: 100,
                child: SortableItem(
                  id: DndId('item-4'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.dragFrom(const Offset(40, 40), const Offset(110, 110),
          kind: PointerDeviceKind.mouse);
      await tester.pump();

      expect(
        moves.single,
        isA<SortableMoveDetails>()
            .having((details) => details.fromIndex, 'fromIndex', 0)
            .having((details) => details.toIndex, 'toIndex', 3),
      );
    });

    testWidgets('does not report a move when dropped over itself', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final moves = <SortableMoveDetails>[];

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          onMove: moves.add,
          child: const SortableItem(
            id: DndId('item-1'),
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );
      await tester.pump();

      await tester.dragFrom(const Offset(40, 40), const Offset(5, 0),
          kind: PointerDeviceKind.mouse);
      await tester.pump();

      expect(moves, isEmpty);
    });

    testWidgets('exposes live displacement to sibling builders during a drag', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final displacements = <DndId, DndPoint>{};

      Widget item(String id) {
        return SortableItem(
          id: DndId(id),
          builder: (context, details, child) {
            displacements[details.id] = details.displacement;
            return child;
          },
          child: const SizedBox(width: 80, height: 40),
        );
      }

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[item('item-1'), item('item-2')],
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SortableItem).first),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 45));
      await tester.pump();

      expect(displacements[const DndId('item-2')], const DndPoint(0, -40));

      await gesture.up();
      await tester.pump();

      expect(displacements[const DndId('item-2')], DndPoint.zero);
    });
  });
}
