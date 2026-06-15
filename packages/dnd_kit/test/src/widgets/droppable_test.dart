import 'package:dnd_kit/dnd_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndDroppable', () {
    testWidgets('registers and unregisters droppable metadata', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDroppable(
            id: DndId('column-1'),
            data: 'payload',
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(
        controller.registry.droppable(const DndId('column-1')),
        const DndDroppableRegistration(
          id: DndId('column-1'),
          data: 'payload',
        ),
      );

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const SizedBox(),
        ),
      );

      expect(controller.registry.hasDroppable(const DndId('column-1')), isFalse);
    });

    testWidgets('updates registry metadata when widget inputs change', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDroppable(
            id: DndId('column-1'),
            data: 'first',
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDroppable(
            id: DndId('column-2'),
            disabled: true,
            data: 'second',
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(controller.registry.hasDroppable(const DndId('column-1')), isFalse);
      expect(
        controller.registry.droppable(const DndId('column-2')),
        const DndDroppableRegistration(
          id: DndId('column-2'),
          disabled: true,
          data: 'second',
        ),
      );
    });

    testWidgets('moves registration when the nearest controller changes', (tester) async {
      final firstController = DndController();
      final secondController = DndController();
      addTearDown(firstController.dispose);
      addTearDown(secondController.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: firstController,
          child: const DndDroppable(
            id: DndId('column-1'),
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      await tester.pumpWidget(
        DndScope(
          controller: secondController,
          child: const DndDroppable(
            id: DndId('column-1'),
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(firstController.registry.hasDroppable(const DndId('column-1')), isFalse);
      expect(secondController.registry.hasDroppable(const DndId('column-1')), isTrue);
    });

    testWidgets('warns when duplicate droppable widgets persist after reconciliation',
        (tester) async {
      final warnings = <DndWarning>[];
      final controller = DndController(
        diagnosticsConfig: DndDiagnosticsConfig(onWarning: warnings.add),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              DndDroppable(
                id: DndId('column-1'),
                child: SizedBox(width: 80, height: 80),
              ),
              Positioned(
                top: 100,
                child: DndDroppable(
                  id: DndId('column-1'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
            ],
          ),
        ),
      );

      expect(
        warnings,
        [
          isA<DndWarning>()
              .having((warning) => warning.code, 'code', 'duplicate-droppable-id')
              .having((warning) => warning.id, 'id', const DndId('column-1'))
              .having((warning) => warning.message, 'message', contains('after reconciliation')),
        ],
      );

      await tester.pump();
      expect(warnings, hasLength(1));
    });

    testWidgets('keeps disabled droppables registered as disabled metadata', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDroppable(
            id: DndId('column-1'),
            disabled: true,
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(
        controller.registry.droppable(const DndId('column-1'))?.disabled,
        isTrue,
      );
    });

    testWidgets('builder receives visual state as drag moves over target', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final detailsLog = <DndDroppableDetails>[];

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 100,
                top: 100,
                child: DndDroppable(
                  id: const DndId('column-1'),
                  builder: (context, details, child) {
                    detailsLog.add(details);
                    return Text(
                      'droppable:${details.isOver}:'
                      '${details.activeId?.value ?? 'none'}:'
                      '${details.session?.activeId.value ?? 'none'}',
                      textDirection: TextDirection.ltr,
                    );
                  },
                  child: const SizedBox(width: 80, height: 80),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('droppable:false:none:none'), findsOneWidget);
      expect(detailsLog.last.id, const DndId('column-1'));

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint.zero,
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 20, height: 20),
      );
      controller.startDrag();
      controller.moveDrag(const DndPoint(110, 110));
      await tester.pump();

      expect(find.text('droppable:true:task-1:task-1'), findsOneWidget);
      expect(detailsLog.last.isOver, isTrue);

      controller.endDrag();
      await tester.pump();

      expect(find.text('droppable:true:task-1:task-1'), findsOneWidget);

      controller.reset();
      await tester.pump();

      expect(find.text('droppable:false:none:none'), findsOneWidget);
    });

    testWidgets('builder reports disabled visual state', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDroppableDetails? latestDetails;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDroppable(
            id: const DndId('column-1'),
            disabled: true,
            builder: (context, details, child) {
              latestDetails = details;
              return child;
            },
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(latestDetails?.disabled, isTrue);
      expect(latestDetails?.isOver, isFalse);
    });

    testWidgets('measures global droppable bounds while mounted', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 10,
                top: 20,
                child: DndDroppable(
                  id: DndId('column-1'),
                  child: SizedBox(width: 80, height: 60),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(
        controller.measuring.droppableRect(const DndId('column-1')),
        const DndRect(left: 10, top: 20, width: 80, height: 60),
      );

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const SizedBox(),
        ),
      );

      expect(controller.measuring.droppableRect(const DndId('column-1')), isNull);
    });

    testWidgets('removes old measurements and measures the new id after id changes',
        (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                child: DndDroppable(
                  id: DndId('column-1'),
                  child: SizedBox(width: 80, height: 60),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(controller.measuring.droppableStatus(const DndId('column-1')),
          DndMeasurementStatus.clean);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                child: DndDroppable(
                  id: DndId('column-2'),
                  child: SizedBox(width: 100, height: 70),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(controller.measuring.droppableStatus(const DndId('column-1')),
          DndMeasurementStatus.removed);
      expect(controller.measuring.droppableStatus(const DndId('column-2')),
          DndMeasurementStatus.clean);
      expect(
        controller.measuring.droppableRect(const DndId('column-2')),
        const DndRect(left: 0, top: 0, width: 100, height: 70),
      );
    });

    testWidgets('marks disabled changes dirty while keeping stale rects out of collision',
        (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragEndEvent? endEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              const Positioned(
                left: 100,
                top: 0,
                child: DndDroppable(
                  id: DndId('column-1'),
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: DndDraggable(
                  id: const DndId('task-1'),
                  onDragEnd: (event) {
                    endEvent = event;
                  },
                  child: const SizedBox(width: 40, height: 40),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              const Positioned(
                left: 100,
                top: 0,
                child: DndDroppable(
                  id: DndId('column-1'),
                  disabled: true,
                  child: SizedBox(width: 80, height: 80),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: DndDraggable(
                  id: const DndId('task-1'),
                  onDragEnd: (event) {
                    endEvent = event;
                  },
                  child: const SizedBox(width: 40, height: 40),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(controller.registry.droppable(const DndId('column-1'))?.disabled, isTrue);
      expect(controller.measuring.droppableRect(const DndId('column-1')), isNotNull);

      await tester.dragFrom(const Offset(20, 20), const Offset(100, 0));
      await tester.pump();

      expect(endEvent?.overId, isNull);
    });
  });
}
