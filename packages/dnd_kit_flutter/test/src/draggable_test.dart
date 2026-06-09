import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndDraggable', () {
    Future<void> focusDraggable(WidgetTester tester) async {
      final focus = tester.widget<Focus>(
        find.descendant(of: find.byType(DndDraggable), matching: find.byType(Focus)).first,
      );
      focus.focusNode!.requestFocus();
      await tester.pump();
    }

    testWidgets('registers and unregisters draggable metadata', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDraggable(
            id: DndId('task-1'),
            data: 'payload',
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      expect(
        controller.registry.draggable(const DndId('task-1')),
        const DndDraggableRegistration(
          id: DndId('task-1'),
          data: 'payload',
        ),
      );

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const SizedBox(),
        ),
      );

      expect(controller.registry.hasDraggable(const DndId('task-1')), isFalse);
    });

    testWidgets('updates registry metadata when widget inputs change', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDraggable(
            id: DndId('task-1'),
            data: 'first',
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDraggable(
            id: DndId('task-2'),
            disabled: true,
            data: 'second',
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      expect(controller.registry.hasDraggable(const DndId('task-1')), isFalse);
      expect(
        controller.registry.draggable(const DndId('task-2')),
        const DndDraggableRegistration(
          id: DndId('task-2'),
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
          child: const DndDraggable(
            id: DndId('task-1'),
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      await tester.pumpWidget(
        DndScope(
          controller: secondController,
          child: const DndDraggable(
            id: DndId('task-1'),
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      expect(firstController.registry.hasDraggable(const DndId('task-1')), isFalse);
      expect(secondController.registry.hasDraggable(const DndId('task-1')), isTrue);
    });

    testWidgets('does not start a drag when disabled', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      var startCount = 0;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            disabled: true,
            onDragStart: (_) {
              startCount += 1;
            },
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      await tester.dragFrom(const Offset(20, 20), const Offset(20, 0));
      await tester.pump();

      expect(startCount, 0);
      expect(controller.state, const DndIdle());
      expect(
        controller.registry.draggable(const DndId('task-1'))?.disabled,
        isTrue,
      );
    });

    testWidgets('emits core drag lifecycle callbacks for pan gestures', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      final moveEvents = <DndDragMoveEvent>[];
      DndDragEndEvent? endEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            onDragStart: (event) {
              startEvent = event;
            },
            onDragMove: moveEvents.add,
            onDragEnd: (event) {
              endEvent = event;
            },
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(15, 20));
      await gesture.up();
      await tester.pump();

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(startEvent?.initialPointer, const DndPoint(10, 10));
      expect(startEvent?.inputKind, DndInputKind.mouse);
      expect(moveEvents, isNotEmpty);
      expect(moveEvents.last.currentPointer, const DndPoint(25, 30));
      expect(endEvent?.activeId, const DndId('task-1'));
      expect(endEvent?.currentPointer, const DndPoint(25, 30));
      expect(controller.state, const DndIdle());
    });

    testWidgets('reports touch input kind for touch pan gestures', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            onDragStart: (event) {
              startEvent = event;
            },
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(10, 10),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(15, 20));
      await gesture.up();
      await tester.pump();

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(startEvent?.inputKind, DndInputKind.touch);
      expect(controller.state, const DndIdle());
    });

    testWidgets('waits for pointer distance before starting a drag', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      final moveEvents = <DndDragMoveEvent>[];

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            activationConstraint: const DndSensorActivationConstraint(distance: 50),
            onDragStart: (event) {
              startEvent = event;
            },
            onDragMove: moveEvents.add,
            child: const SizedBox(width: 120, height: 120),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(20, 20));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();

      expect(startEvent, isNull);
      expect(controller.state, isA<DndPending>());

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(moveEvents, isNotEmpty);
      expect(controller.state, isA<DndDragging>());

      await gesture.up();
      await tester.pump();
    });

    testWidgets('cancels pending pointer activation when gesture ends early', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      DndDragCancelEvent? cancelEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            activationConstraint: const DndSensorActivationConstraint(distance: 100),
            onDragStart: (event) {
              startEvent = event;
            },
            onDragCancel: (event) {
              cancelEvent = event;
            },
            child: const SizedBox(width: 120, height: 120),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(20, 20));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(startEvent, isNull);
      expect(cancelEvent?.activeId, const DndId('task-1'));
      expect(cancelEvent?.reason, DndCancelReason.sensor);
      expect(controller.state, const DndIdle());
    });

    testWidgets('waits for pointer delay before starting a drag', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            activationConstraint: const DndSensorActivationConstraint(
              delay: Duration(milliseconds: 300),
            ),
            onDragStart: (event) {
              startEvent = event;
            },
            child: const SizedBox(width: 120, height: 120),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(20, 20));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 299));

      expect(startEvent, isNull);
      expect(controller.state, isA<DndPending>());

      await tester.pump(const Duration(milliseconds: 1));

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(controller.state, isA<DndDragging>());

      await gesture.up();
      await tester.pump();
    });

    testWidgets('cancels delayed pointer activation when tolerance is exceeded', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      DndDragCancelEvent? cancelEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            activationConstraint: const DndSensorActivationConstraint(
              delay: Duration(seconds: 1),
              tolerance: 5,
            ),
            onDragStart: (event) {
              startEvent = event;
            },
            onDragCancel: (event) {
              cancelEvent = event;
            },
            child: const SizedBox(width: 120, height: 120),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(20, 20));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();

      expect(startEvent, isNull);
      expect(cancelEvent?.activeId, const DndId('task-1'));
      expect(cancelEvent?.reason, DndCancelReason.sensor);
      expect(controller.state, const DndIdle());

      await gesture.cancel();
    });

    testWidgets('starts a long-press drag after the configured delay', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            longPressActivation: const DndLongPressActivation(
              delay: Duration(milliseconds: 300),
            ),
            onDragStart: (event) {
              startEvent = event;
            },
            child: const SizedBox(width: 120, height: 120),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(20, 20),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(const Duration(milliseconds: 299));

      expect(startEvent, isNull);
      expect(controller.state, isA<DndPending>());

      await tester.pump(const Duration(milliseconds: 1));

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(startEvent?.initialPointer, const DndPoint(20, 20));
      expect(startEvent?.inputKind, DndInputKind.touch);
      expect(controller.state, isA<DndDragging>());

      await gesture.up();
      await tester.pump();
    });

    testWidgets('cancels long-press activation when tolerance is exceeded', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      DndDragCancelEvent? cancelEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            longPressActivation: const DndLongPressActivation(
              delay: Duration(seconds: 1),
              tolerance: 5,
            ),
            onDragStart: (event) {
              startEvent = event;
            },
            onDragCancel: (event) {
              cancelEvent = event;
            },
            child: const SizedBox(width: 120, height: 120),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(20, 20));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();

      expect(startEvent, isNull);
      expect(cancelEvent?.activeId, const DndId('task-1'));
      expect(cancelEvent?.reason, DndCancelReason.sensor);
      expect(controller.state, const DndIdle());

      await gesture.cancel();
    });

    testWidgets('cancels long-press activation when the pointer ends early', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      DndDragCancelEvent? cancelEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            longPressActivation: const DndLongPressActivation(
              delay: Duration(milliseconds: 300),
            ),
            onDragStart: (event) {
              startEvent = event;
            },
            onDragCancel: (event) {
              cancelEvent = event;
            },
            child: const SizedBox(width: 120, height: 120),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();

      expect(startEvent, isNull);
      expect(cancelEvent?.activeId, const DndId('task-1'));
      expect(cancelEvent?.reason, DndCancelReason.sensor);
      expect(controller.state, const DndIdle());
    });

    testWidgets('starts a drag from a drag handle', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      DndDragEndEvent? endEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            onDragStart: (event) {
              startEvent = event;
            },
            onDragEnd: (event) {
              endEvent = event;
            },
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                textDirection: TextDirection.ltr,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    child: DndDragHandle(
                      child: SizedBox(width: 30, height: 30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(20, 0));
      await gesture.up();
      await tester.pump();

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(startEvent?.initialPointer, const DndPoint(10, 10));
      expect(startEvent?.inputKind, DndInputKind.mouse);
      expect(endEvent?.activeId, const DndId('task-1'));
      expect(controller.state, const DndIdle());
    });

    testWidgets('does not start from the draggable body when a handle exists', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      var startCount = 0;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            onDragStart: (_) {
              startCount += 1;
            },
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                textDirection: TextDirection.ltr,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    child: DndDragHandle(
                      child: SizedBox(width: 30, height: 30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.dragFrom(const Offset(80, 80), const Offset(20, 0));
      await tester.pump();

      expect(startCount, 0);
      expect(controller.state, const DndIdle());
    });

    testWidgets('applies pointer activation constraints through a drag handle', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      final moveEvents = <DndDragMoveEvent>[];

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            activationConstraint: const DndSensorActivationConstraint(distance: 50),
            onDragStart: (event) {
              startEvent = event;
            },
            onDragMove: moveEvents.add,
            child: const SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                textDirection: TextDirection.ltr,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    child: DndDragHandle(
                      child: SizedBox(width: 40, height: 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(20, 20));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();

      expect(startEvent, isNull);
      expect(controller.state, isA<DndPending>());

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(moveEvents, isNotEmpty);
      expect(controller.state, isA<DndDragging>());

      await gesture.up();
      await tester.pump();
    });

    testWidgets('applies long-press activation through a drag handle', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            longPressActivation: const DndLongPressActivation(
              delay: Duration(milliseconds: 300),
            ),
            onDragStart: (event) {
              startEvent = event;
            },
            child: const SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                textDirection: TextDirection.ltr,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    child: DndDragHandle(
                      child: SizedBox(width: 40, height: 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 299));

      expect(startEvent, isNull);
      expect(controller.state, isA<DndPending>());

      await tester.pump(const Duration(milliseconds: 1));

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(controller.state, isA<DndDragging>());

      await gesture.up();
      await tester.pump();
    });

    testWidgets('does not start from a handle when the draggable is disabled', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      var startCount = 0;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            disabled: true,
            onDragStart: (_) {
              startCount += 1;
            },
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                textDirection: TextDirection.ltr,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    child: DndDragHandle(
                      child: SizedBox(width: 30, height: 30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.dragFrom(const Offset(10, 10), const Offset(20, 0));
      await tester.pump();

      expect(startCount, 0);
      expect(controller.state, const DndIdle());
    });

    testWidgets('cancels an active drag when disabled during the gesture', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragCancelEvent? cancelEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            onDragCancel: (event) {
              cancelEvent = event;
            },
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(20, 20));
      await tester.pump();

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            disabled: true,
            onDragCancel: (event) {
              cancelEvent = event;
            },
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      expect(cancelEvent?.activeId, const DndId('task-1'));
      expect(cancelEvent?.reason, DndCancelReason.disabled);
      expect(controller.state, const DndIdle());

      await gesture.cancel();
    });

    testWidgets('updates overId while dragging over measured droppables', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      final moveEvents = <DndDragMoveEvent>[];
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
                  onDragMove: moveEvents.add,
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

      final gesture = await tester.startGesture(const Offset(20, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();

      expect(moveEvents, isNotEmpty);
      expect(controller.measuring.draggableRect(const DndId('task-1')), isNotNull);
      expect(controller.overId, const DndId('column-1'));

      await gesture.up();
      await tester.pump();

      expect(endEvent?.overId, const DndId('column-1'));
    });

    testWidgets('ignores disabled droppables during collision detection', (tester) async {
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

      await tester.dragFrom(const Offset(20, 20), const Offset(100, 0));
      await tester.pump();

      expect(endEvent?.overId, isNull);
    });

    testWidgets('starts, moves, and drops a focused keyboard drag', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      final moveEvents = <DndDragMoveEvent>[];
      DndDragEndEvent? endEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            keyboardDragStep: 10,
            onDragStart: (event) {
              startEvent = event;
            },
            onDragMove: moveEvents.add,
            onDragEnd: (event) {
              endEvent = event;
            },
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      await focusDraggable(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(startEvent?.inputKind, DndInputKind.keyboard);
      expect(startEvent?.initialPointer, const DndPoint(400, 300));
      expect(controller.state, isA<DndDragging>());

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(moveEvents.map((event) => event.currentPointer), <DndPoint>[
        const DndPoint(410, 300),
        const DndPoint(410, 310),
      ]);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(endEvent?.activeId, const DndId('task-1'));
      expect(endEvent?.currentPointer, const DndPoint(410, 310));
      expect(controller.state, const DndIdle());
    });

    testWidgets('cancels an active keyboard drag with escape', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragCancelEvent? cancelEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            onDragCancel: (event) {
              cancelEvent = event;
            },
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      await focusDraggable(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(cancelEvent?.activeId, const DndId('task-1'));
      expect(cancelEvent?.reason, DndCancelReason.user);
      expect(controller.state, const DndIdle());
    });

    testWidgets('does not start keyboard dragging when disabled', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      var startCount = 0;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            disabled: true,
            onDragStart: (_) {
              startCount += 1;
            },
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      await focusDraggable(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(startCount, 0);
      expect(controller.state, const DndIdle());
    });

    testWidgets('drops keyboard drag without a droppable', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragEndEvent? endEvent;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            onDragEnd: (event) {
              endEvent = event;
            },
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      await focusDraggable(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(endEvent?.activeId, const DndId('task-1'));
      expect(endEvent?.overId, isNull);
      expect(controller.state, const DndIdle());
    });

    testWidgets('exposes a keyboard drag semantics hint', (tester) async {
      await tester.pumpWidget(
        const DndScope(
          child: DndDraggable(
            id: DndId('task-1'),
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.hint ==
                      'Press Space or Enter to pick up, arrow keys to move, Escape to cancel.',
            )
            .first,
      );

      expect(
        semantics.properties.hint,
        'Press Space or Enter to pick up, arrow keys to move, Escape to cancel.',
      );
    });
  });
}
