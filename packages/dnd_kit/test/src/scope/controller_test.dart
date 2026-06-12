import 'package:dnd_kit/dnd_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndController', () {
    test('starts idle with an empty registry', () {
      final controller = DndController();
      addTearDown(controller.dispose);

      expect(controller.state, const DndIdle());
      expect(controller.isIdle, isTrue);
      expect(controller.isDragging, isFalse);
      expect(controller.activeId, isNull);
      expect(controller.activeSession, isNull);
      expect(controller.registry.snapshot, DndRegistrySnapshot.empty);
    });

    test('passes diagnostics configuration to its registry', () {
      final warnings = <DndWarning>[];
      final controller = DndController(
        diagnosticsConfig: DndDiagnosticsConfig(onWarning: warnings.add),
      );
      addTearDown(controller.dispose);

      controller.registry.registerDraggable(
        const DndDraggableRegistration(id: DndId('task-1')),
      );
      expect(
        () => controller.registry.registerDraggable(
          const DndDraggableRegistration(id: DndId('task-1')),
        ),
        throwsA(isA<AssertionError>()),
      );
      controller.registry.registerDroppable(
        const DndDroppableRegistration(id: DndId('column-1')),
      );
      expect(
        () => controller.registry.registerDroppable(
          const DndDroppableRegistration(id: DndId('column-1')),
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        warnings,
        contains(
          isA<DndWarning>()
              .having((warning) => warning.code, 'code', 'duplicate-draggable-id')
              .having((warning) => warning.id, 'id', const DndId('task-1')),
        ),
      );
      expect(
        warnings,
        contains(
          isA<DndWarning>()
              .having((warning) => warning.code, 'code', 'duplicate-droppable-id')
              .having((warning) => warning.id, 'id', const DndId('column-1')),
        ),
      );
    });

    test('notifies listeners through drag lifecycle transitions', () {
      final controller = DndController();
      addTearDown(controller.dispose);
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount += 1;
      });

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 20),
          inputKind: DndInputKind.mouse,
        ),
      );
      expect(controller.state, isA<DndPending>());
      expect(controller.activeId, const DndId('task-1'));

      final startEvent = controller.startDrag();
      expect(startEvent, isA<DndDragStartEvent>());
      expect(controller.isDragging, isTrue);
      expect(controller.activeSession?.currentPointer, const DndPoint(10, 20));

      final moveEvent = controller.moveDrag(const DndPoint(14, 25));
      expect(moveEvent?.delta, const DndPoint(4, 5));
      expect(controller.activeSession?.currentPointer, const DndPoint(14, 25));

      final endEvent = controller.endDrag(overId: const DndId('column-done'));
      expect(endEvent?.overId, const DndId('column-done'));
      expect(controller.state, isA<DndDropping>());

      controller.reset();
      expect(controller.state, const DndIdle());
      expect(notificationCount, 5);
    });

    test('cancels pending and active drags', () {
      final controller = DndController();
      addTearDown(controller.dispose);

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint.zero,
        ),
      );
      final pendingCancel = controller.cancelDrag(reason: DndCancelReason.user);
      expect(pendingCancel?.activeId, const DndId('task-1'));
      expect(pendingCancel?.session, isNull);
      expect(controller.state, isA<DndCancelled>());

      controller.reset();
      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-2'),
          position: DndPoint.zero,
        ),
      );
      controller.startDrag();
      controller.moveDrag(const DndPoint(3, 4));

      final activeCancel = controller.cancelDrag(reason: DndCancelReason.disabled);
      expect(activeCancel?.activeId, const DndId('task-2'));
      expect(activeCancel?.session?.currentPointer, const DndPoint(3, 4));
      expect(activeCancel?.reason, DndCancelReason.disabled);
      expect(controller.state, isA<DndCancelled>());
    });

    test('applies modifiers to drag movement and collision detection', () {
      final controller = DndController(
        modifiers: const <DndModifier>[
          DndModifiers.restrictToHorizontalAxis,
        ],
      );
      addTearDown(controller.dispose);

      controller.registry.registerDroppable(const DndDroppableRegistration(id: DndId('column-1')));
      controller.measuring.updateDroppableRect(
        const DndId('column-1'),
        const DndRect(left: 100, top: 0, width: 80, height: 80),
      );

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(20, 20),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 40, height: 40),
      );
      controller.startDrag();

      final moveEvent = controller.moveDrag(const DndPoint(120, 120));

      expect(moveEvent?.currentPointer, const DndPoint(120, 20));
      expect(moveEvent?.delta, const DndPoint(100, 0));
      expect(controller.activeSession?.transform, const DndTransform(x: 100));
      expect(controller.overId, const DndId('column-1'));
    });

    test('refreshes dirty measurements before collision detection', () {
      final controller = DndController();
      addTearDown(controller.dispose);

      controller.registry.registerDroppable(const DndDroppableRegistration(id: DndId('column-1')));
      controller.measuring.updateDroppableRect(
        const DndId('column-1'),
        const DndRect(left: 300, top: 0, width: 80, height: 80),
      );
      controller.measuring.markDroppableDirty(
        const DndId('column-1'),
        measure: () => const DndRect(left: 100, top: 0, width: 80, height: 80),
      );

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(20, 20),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 40, height: 40),
      );
      controller.startDrag();
      controller.moveDrag(const DndPoint(120, 20));

      expect(controller.measuring.droppableStatus(const DndId('column-1')),
          DndMeasurementStatus.clean);
      expect(controller.overId, const DndId('column-1'));
    });

    test('refreshes dirty active measurements before modifier input', () {
      final controller = DndController(
        modifiers: <DndModifier>[
          DndModifiers.restrictToBoundary(
            const DndRect(left: 0, top: 0, width: 100, height: 100),
          ),
        ],
      );
      addTearDown(controller.dispose);

      controller.measuring.updateDraggableRect(
        const DndId('task-1'),
        const DndRect(left: 0, top: 0, width: 40, height: 40),
      );
      controller.measuring.markDraggableDirty(
        const DndId('task-1'),
        measure: () => const DndRect(left: 0, top: 0, width: 80, height: 80),
      );

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint.zero,
          inputKind: DndInputKind.keyboard,
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 40, height: 40),
      );
      controller.startDrag();
      final moveEvent = controller.moveDrag(const DndPoint(100, 100));

      expect(
          controller.measuring.draggableStatus(const DndId('task-1')), DndMeasurementStatus.clean);
      expect(moveEvent?.currentPointer, const DndPoint(20, 20));
    });

    test('keeps active rect origin stable when source measurement shifts during drag', () {
      DndCollisionInput? latestInput;
      final controller = DndController(
        collisionDetector: (input) {
          latestInput = input;
          return DndCollisionResult.empty;
        },
      );
      addTearDown(controller.dispose);

      controller.registry.registerDroppable(const DndDroppableRegistration(id: DndId('column-1')));
      controller.measuring.updateDroppableRect(
        const DndId('column-1'),
        const DndRect(left: 0, top: 0, width: 400, height: 400),
      );

      const activeId = DndId('task-1');
      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: activeId,
          position: DndPoint(110, 110),
        ),
        activeRect: const DndRect(left: 100, top: 100, width: 40, height: 50),
      );
      controller.startDrag();
      controller.moveDrag(const DndPoint(130, 140));

      expect(
        latestInput?.activeRect,
        const DndRect(left: 120, top: 130, width: 40, height: 50),
      );

      controller.measuring.updateDraggableRect(
        activeId,
        const DndRect(left: 40, top: 20, width: 60, height: 70),
      );
      controller.moveDrag(const DndPoint(132, 142));

      expect(
        latestInput?.activeRect,
        const DndRect(left: 122, top: 132, width: 60, height: 70),
        reason:
            'scroll-driven source remeasurement should update size without moving the drag origin',
      );
    });
  });
}
