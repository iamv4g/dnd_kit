import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:dnd_kit_sortable/dnd_kit_sortable.dart';
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

      await tester.dragFrom(const Offset(40, 40), const Offset(100, 0));
      await tester.pump();

      expect(moves, hasLength(1));
      expect(
        moves.single,
        isA<SortableMoveDetails>()
            .having((details) => details.activeId, 'activeId', const DndId('item-1'))
            .having((details) => details.overId, 'overId', const DndId('item-2'))
            .having((details) => details.oldIndex, 'oldIndex', 0)
            .having((details) => details.newIndex, 'newIndex', 1)
            .having((details) => details.containerId, 'containerId', const DndId('list-1')),
      );
      expect(
        itemIds,
        const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
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

      await tester.dragFrom(const Offset(40, 40), const Offset(5, 0));
      await tester.pump();

      expect(moves, isEmpty);
    });
  });
}
